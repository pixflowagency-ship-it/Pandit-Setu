import { describe, it, expect, beforeEach, vi } from "vitest";
import request from "supertest";
import express from "express";
import crypto from "node:crypto";
import {
  TokenRevocationService,
  RevocationCheckUnavailableError,
  type RevocationRedisClient,
} from "../services/token-revocation.service.js";
import { signToken, signAdminToken } from "../services/jwt.service.js";
import { verifyToken } from "../middleware/verify-token.js";
import { errorHandler } from "../middleware/error-handler.js";

/**
 * High-fidelity in-memory Redis mock supporting TTL and expiration
 */
class MockSharedRedis implements RevocationRedisClient {
  private store = new Map<string, { value: string; expiresAt: number }>();
  public isDown = false;

  async setex(key: string, seconds: number, value: string): Promise<string> {
    if (this.isDown) throw new Error("Connection to Redis lost (ECONNREFUSED)");
    const expiresAt = Date.now() + seconds * 1000;
    this.store.set(key, { value, expiresAt });
    return "OK";
  }

  async exists(key: string): Promise<number> {
    if (this.isDown) throw new Error("Connection to Redis lost (ECONNREFUSED)");
    const entry = this.store.get(key);
    if (!entry) return 0;
    if (Date.now() >= entry.expiresAt) {
      this.store.delete(key);
      return 0;
    }
    return 1;
  }

  async ttl(key: string): Promise<number> {
    if (this.isDown) throw new Error("Connection to Redis lost (ECONNREFUSED)");
    const entry = this.store.get(key);
    if (!entry) return -2;
    const remaining = Math.round((entry.expiresAt - Date.now()) / 1000);
    return remaining > 0 ? remaining : -2;
  }

  async del(key: string): Promise<number> {
    if (this.isDown) throw new Error("Connection to Redis lost (ECONNREFUSED)");
    return this.store.delete(key) ? 1 : 0;
  }

  clear(): void {
    this.store.clear();
    this.isDown = false;
  }

  expireKey(key: string): void {
    const entry = this.store.get(key);
    if (entry) {
      entry.expiresAt = Date.now() - 1000;
    }
  }
}

describe("Phase P10: Distributed Token Revocation & Multi-Instance Security", () => {
  let sharedRedis: MockSharedRedis;
  let instanceA: TokenRevocationService;
  let instanceB: TokenRevocationService;

  beforeEach(() => {
    sharedRedis = new MockSharedRedis();
    // Simulate two independently initialized backend server instances sharing the same Redis cluster
    instanceA = new TokenRevocationService({ redisClient: sharedRedis, failClosed: true });
    instanceB = new TokenRevocationService({ redisClient: sharedRedis, failClosed: true });
  });

  describe("1. Cross-Instance Token Revocation", () => {
    it("proves that a token revoked on Instance A is immediately rejected on Instance B", async () => {
      const adminToken = signAdminToken({
        id: "admin-uuid-001",
        phone: "+919999900001",
        email: "admin1@sarvmangal.app",
        role: "ADMIN",
      });

      // Decode payload to obtain jti and exp
      const base64Payload = adminToken.split(".")[1];
      const payload = JSON.parse(Buffer.from(base64Payload, "base64url").toString("utf8"));

      // 1. Before logout, neither instance has revoked it
      expect(await instanceA.isTokenRevoked(adminToken, payload)).toBe(false);
      expect(await instanceB.isTokenRevoked(adminToken, payload)).toBe(false);

      // 2. User logs out on Instance A
      await instanceA.revokeToken(adminToken, payload);

      // Verify Instance A has it locally in its memory cache
      expect(instanceA.getMemoryStoreSize()).toBeGreaterThanOrEqual(1);

      // Crucial assertion: Instance B's process-local memory is completely EMPTY
      expect(instanceB.getMemoryStoreSize()).toBe(0);

      // 3. Request hits Instance B with the same token: Instance B consults shared Redis
      const isRevokedOnB = await instanceB.isTokenRevoked(adminToken, payload);
      expect(isRevokedOnB).toBe(true);
    });

    it("revokes by both SHA-256 token hash and JWT jti identifier in Redis", async () => {
      const token = signToken({
        id: "user-uuid-002",
        phone: "+919999900002",
        role: "YAJMAN",
      });

      const payload = JSON.parse(Buffer.from(token.split(".")[1], "base64url").toString("utf8"));
      expect(payload.jti).toBeDefined();

      await instanceA.revokeToken(token, payload);

      const tokenHash = instanceA.hashToken(token);
      expect(await sharedRedis.exists(`revoked_token:${tokenHash}`)).toBe(1);
      expect(await sharedRedis.exists(`revoked_jti:${payload.jti}`)).toBe(1);
    });
  });

  describe("2. Redis TTL & Expiry Management", () => {
    it("sets Redis key TTL matching the token's remaining lifespan", async () => {
      const nowSeconds = Math.floor(Date.now() / 1000);
      const mockPayload = {
        id: "admin-003",
        role: "ADMIN",
        jti: crypto.randomUUID(),
        exp: nowSeconds + 300, // Expires in 5 minutes (300 seconds)
      };

      const rawToken = "mock.jwt.token." + crypto.randomBytes(16).toString("hex");
      await instanceA.revokeToken(rawToken, mockPayload as any);

      const tokenHash = instanceA.hashToken(rawToken);
      const ttl = await sharedRedis.ttl(`revoked_token:${tokenHash}`);

      expect(ttl).toBeGreaterThanOrEqual(295);
      expect(ttl).toBeLessThanOrEqual(300);
    });

    it("cleans up expired entries naturally when TTL expires", async () => {
      const rawToken = "mock.expiring.token." + crypto.randomBytes(16).toString("hex");
      const mockPayload = {
        id: "admin-004",
        role: "ADMIN",
        jti: crypto.randomUUID(),
        exp: Math.floor(Date.now() / 1000) + 10,
      };

      await instanceA.revokeToken(rawToken, mockPayload as any);
      expect(await instanceB.isTokenRevoked(rawToken, mockPayload as any)).toBe(true);

      const tokenHash = instanceA.hashToken(rawToken);
      // Simulate TTL expiration in Redis
      sharedRedis.expireKey(`revoked_token:${tokenHash}`);
      sharedRedis.expireKey(`revoked_jti:${mockPayload.jti}`);

      // Now Instance B should report false (token expired and pruned from Redis)
      expect(await instanceB.isTokenRevoked(rawToken, mockPayload as any)).toBe(false);
    });

    it("prunes expired entries from local process memory store", () => {
      const instance = new TokenRevocationService();
      // Add fake expired entry manually
      (instance as any).memoryRevocationStore.set("expired_hash", Date.now() - 5000);
      (instance as any).memoryRevocationStore.set("valid_hash", Date.now() + 100000);

      const pruned = instance.pruneExpiredRevocations();
      expect(pruned).toBe(1);
      expect((instance as any).memoryRevocationStore.has("expired_hash")).toBe(false);
      expect((instance as any).memoryRevocationStore.has("valid_hash")).toBe(true);
    });
  });

  describe("3. Distributed Outage & Fail-Closed Security Policy", () => {
    it("fails closed (HTTP 503) when Redis is down and fail-closed is active", async () => {
      // Simulate Redis cluster outage
      sharedRedis.isDown = true;

      const unseenToken = "mock.unseen.token." + crypto.randomBytes(16).toString("hex");
      const payload = { id: "user-123", role: "ADMIN", exp: Math.floor(Date.now() / 1000) + 3600 };

      // In fail-closed mode, an unverified token must NOT be accepted blindly
      await expect(instanceB.isTokenRevoked(unseenToken, payload as any)).rejects.toThrow(
        RevocationCheckUnavailableError
      );
    });

    it("allows fail-open development mode when failClosed is explicitly false", async () => {
      const devInstance = new TokenRevocationService({
        redisClient: sharedRedis,
        failClosed: false,
      });

      sharedRedis.isDown = true;

      const unseenToken = "mock.dev.token." + crypto.randomBytes(16).toString("hex");
      const payload = { id: "user-123", role: "ADMIN", exp: Math.floor(Date.now() / 1000) + 3600 };

      // In dev mode with failClosed=false, it warns and returns false instead of throwing 503
      const result = await devInstance.isTokenRevoked(unseenToken, payload as any);
      expect(result).toBe(false);
    });

    it("recovers gracefully when Redis reconnects", async () => {
      const token = signAdminToken({
        id: "admin-recover",
        phone: "+919999900009",
        email: "recover@sarvmangal.app",
        role: "ADMIN",
      });
      const payload = JSON.parse(Buffer.from(token.split(".")[1], "base64url").toString("utf8"));

      // 1. Initial revocation succeeds
      await instanceA.revokeToken(token, payload);
      expect(await instanceB.isTokenRevoked(token, payload)).toBe(true);

      // 2. Outage occurs
      sharedRedis.isDown = true;
      await expect(instanceB.isTokenRevoked(token, payload)).rejects.toThrow();

      // 3. Redis recovers
      sharedRedis.isDown = false;
      expect(await instanceB.isTokenRevoked(token, payload)).toBe(true);
    });
  });

  describe("4. End-to-End Middleware Enforcement", () => {
    it("returns HTTP 401 TOKEN_REVOKED on Express route when token was revoked", async () => {
      const app = express();
      app.use(express.json());

      const adminToken = signAdminToken({
        id: "admin-express",
        phone: "+919999900010",
        email: "admin_express@sarvmangal.app",
        role: "ADMIN",
      });
      const payload = JSON.parse(Buffer.from(adminToken.split(".")[1], "base64url").toString("utf8"));

      // Revoke the token
      await instanceA.revokeToken(adminToken, payload);

      app.get("/test-protected", verifyToken, (req, res) => {
        res.json({ success: true, user: req.user });
      });
      app.use(errorHandler);

      // Note: verifyToken uses defaultRevocationService; let's test using the default service's methods
      const { revokeToken: revokeDefault } = await import("../services/token-revocation.service.js");
      await revokeDefault(adminToken, payload);

      const res = await request(app)
        .get("/test-protected")
        .set("Authorization", `Bearer ${adminToken}`);

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe("TOKEN_REVOKED");
    });
  });
});
