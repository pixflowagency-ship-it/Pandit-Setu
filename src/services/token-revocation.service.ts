import crypto from "node:crypto";
import { getRedis } from "../config/redis.js";
import { logger } from "../utils/logger.js";
import { AppError } from "../utils/api-error.js";
import type { JwtPayload } from "../types/auth.js";

/**
 * Interface representing Redis operations needed by the token revocation service.
 */
export interface RevocationRedisClient {
  setex(key: string, seconds: number, value: string): Promise<any>;
  exists(key: string): Promise<number>;
  ttl?(key: string): Promise<number>;
  del?(key: string): Promise<any>;
}

export class RevocationCheckUnavailableError extends AppError {
  constructor(message = "Authentication revocation check is temporarily unavailable") {
    super(503, "REVOCATION_UNAVAILABLE", message);
  }
}

/**
 * Token Revocation Engine supporting both distributed Redis denylisting
 * and local in-memory fallback with configurable fail-closed / fail-open security policies.
 */
export class TokenRevocationService {
  private memoryRevocationStore = new Map<string, number>();
  private redisOverride: RevocationRedisClient | null = null;
  private failClosedOverride: boolean | null = null;

  constructor(options?: { redisClient?: RevocationRedisClient; failClosed?: boolean }) {
    if (options?.redisClient) {
      this.redisOverride = options.redisClient;
    }
    if (options?.failClosed !== undefined) {
      this.failClosedOverride = options.failClosed;
    }
  }

  /**
   * Computes deterministic SHA-256 hash for a token to safely use as an identifier
   * without exposing the raw JWT string in keys, storage, or logs.
   */
  public hashToken(token: string): string {
    return crypto.createHash("sha256").update(token.trim()).digest("hex");
  }

  /**
   * Evaluates whether the system policy requires failing closed when the
   * distributed revocation store (Redis) cannot be reached.
   */
  public isFailClosed(): boolean {
    if (this.failClosedOverride !== null) {
      return this.failClosedOverride;
    }

    if (process.env.REVOCATION_FAIL_CLOSED === "true") {
      return true;
    }

    if (process.env.NODE_ENV === "production" && process.env.ALLOW_IN_MEMORY_REVOCATION !== "true") {
      return true;
    }

    return false;
  }

  public setFailClosed(failClosed: boolean | null): void {
    this.failClosedOverride = failClosed;
  }

  public setRedisClient(client: RevocationRedisClient | null): void {
    this.redisOverride = client;
  }

  private async getClient(): Promise<RevocationRedisClient | null> {
    if (this.redisOverride) {
      return this.redisOverride;
    }
    return (await getRedis()) as RevocationRedisClient | null;
  }

  /**
   * Calculates the remaining TTL in seconds for a token payload.
   * Enforces minimum 60s TTL so recently revoked tokens do not immediately vanish.
   */
  public calculateTtlSeconds(payload?: JwtPayload): number {
    const defaultTtl = 4 * 60 * 60; // 4 hours default
    if (payload?.exp && typeof payload.exp === "number") {
      const nowSeconds = Math.floor(Date.now() / 1000);
      const remaining = payload.exp - nowSeconds;
      return remaining > 0 ? remaining : 60;
    }
    return defaultTtl;
  }

  /**
   * Revokes a token by persisting it to Redis and the local in-memory store.
   * If Redis is down in fail-closed mode, records locally and throws RevocationCheckUnavailableError.
   */
  public async revokeToken(rawToken: string, payload?: JwtPayload): Promise<void> {
    if (!rawToken || typeof rawToken !== "string") return;

    const tokenHash = this.hashToken(rawToken);
    const ttlSeconds = this.calculateTtlSeconds(payload);
    const expiryTimestamp = Date.now() + ttlSeconds * 1000;

    // 1. Always record in local memory store
    this.memoryRevocationStore.set(tokenHash, expiryTimestamp);
    if (payload?.jti) {
      this.memoryRevocationStore.set(`jti:${payload.jti}`, expiryTimestamp);
    }

    // 2. Persist to shared distributed Redis
    let redisSuccess = false;
    let redisError: any = null;

    try {
      const redis = await this.getClient();
      if (redis && typeof redis.setex === "function") {
        await redis.setex(`revoked_token:${tokenHash}`, ttlSeconds, "1");
        if (payload?.jti) {
          await redis.setex(`revoked_jti:${payload.jti}`, ttlSeconds, "1");
        }
        redisSuccess = true;
        logger.info({ tokenHash: tokenHash.slice(0, 8), ttlSeconds }, "Token revoked in distributed Redis and memory");
      }
    } catch (err: any) {
      redisError = err;
      logger.warn({ err: err?.message }, "Redis unavailable during distributed token revocation");
    }

    if (!redisSuccess) {
      if (this.isFailClosed()) {
        logger.error({ tokenHash: tokenHash.slice(0, 8) }, "Distributed token revocation failed in fail-closed mode");
        throw new RevocationCheckUnavailableError("Failed to persist token revocation to distributed store; operation rejected under fail-closed security policy");
      }
      logger.info({ tokenHash: tokenHash.slice(0, 8), ttlSeconds }, "Token revoked in local memory store (fail-open dev fallback)");
    }
  }

  /**
   * Checks whether a token has been revoked.
   * 1. Checks local memory store first.
   * 2. If not found locally, queries distributed Redis.
   * 3. If Redis is unavailable:
   *    - In fail-closed mode: throws RevocationCheckUnavailableError (HTTP 503).
   *    - In fail-open mode: returns false and logs a warning.
   */
  public async isTokenRevoked(rawToken: string, payload?: JwtPayload): Promise<boolean> {
    if (!rawToken || typeof rawToken !== "string") return false;

    const tokenHash = this.hashToken(rawToken);
    const now = Date.now();

    // 1. Check local in-memory store
    const memoryExpiry = this.memoryRevocationStore.get(tokenHash);
    if (memoryExpiry) {
      if (now < memoryExpiry) {
        return true;
      }
      this.memoryRevocationStore.delete(tokenHash);
    }

    if (payload?.jti) {
      const jtiExpiry = this.memoryRevocationStore.get(`jti:${payload.jti}`);
      if (jtiExpiry) {
        if (now < jtiExpiry) {
          return true;
        }
        this.memoryRevocationStore.delete(`jti:${payload.jti}`);
      }
    }

    // 2. Query shared distributed Redis
    try {
      const redis = await this.getClient();
      if (redis && typeof redis.exists === "function") {
        const tokenExists = await redis.exists(`revoked_token:${tokenHash}`);
        if (tokenExists === 1) {
          return true;
        }

        if (payload?.jti) {
          const jtiExists = await redis.exists(`revoked_jti:${payload.jti}`);
          if (jtiExists === 1) {
            return true;
          }
        }

        return false;
      }
    } catch (err: any) {
      logger.warn({ err: err?.message }, "Redis unavailable during distributed token revocation check");
      if (this.isFailClosed()) {
        throw new RevocationCheckUnavailableError("Revocation store unavailable; request rejected under fail-closed security policy");
      }
      return false;
    }

    // If redis was not returned (null)
    if (this.isFailClosed()) {
      throw new RevocationCheckUnavailableError("Revocation store unavailable; request rejected under fail-closed security policy");
    }

    return false;
  }

  /**
   * Prunes expired records from memory store.
   */
  public pruneExpiredRevocations(): number {
    const now = Date.now();
    let pruned = 0;
    for (const [key, expiry] of this.memoryRevocationStore.entries()) {
      if (now >= expiry) {
        this.memoryRevocationStore.delete(key);
        pruned++;
      }
    }
    return pruned;
  }

  /**
   * Testing helper: clears in-memory revocation store.
   */
  public clearMemoryStore(): void {
    this.memoryRevocationStore.clear();
  }

  public getMemoryStoreSize(): number {
    return this.memoryRevocationStore.size;
  }
}

// Default singleton instance used across the application
export const defaultRevocationService = new TokenRevocationService();

export function hashToken(token: string): string {
  return defaultRevocationService.hashToken(token);
}

export function revokeToken(rawToken: string, payload?: JwtPayload): Promise<void> {
  return defaultRevocationService.revokeToken(rawToken, payload);
}

export function isTokenRevoked(rawToken: string, payload?: JwtPayload): Promise<boolean> {
  return defaultRevocationService.isTokenRevoked(rawToken, payload);
}

export function clearRevocationMemoryStore(): void {
  defaultRevocationService.clearMemoryStore();
}

export function pruneExpiredRevocations(): number {
  return defaultRevocationService.pruneExpiredRevocations();
}
