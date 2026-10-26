import pool from "../config/db.js";
import { getRedis } from "../config/redis.js";
import { env } from "../config/env.js";
import { logger } from "../utils/logger.js";

export interface ProviderStatus {
  configured: boolean;
  details?: string;
}

export interface HealthCheckResult {
  status: "ok" | "degraded" | "down";
  timestamp: string;
  uptimeSeconds: number;
  checks: {
    database: {
      status: "up" | "down";
      latencyMs?: number;
      error?: string;
    };
    redis: {
      status: "up" | "degraded" | "down";
      latencyMs?: number;
      error?: string;
    };
    providers: {
      razorpay: ProviderStatus;
      fast2sms: ProviderStatus;
      firebase: ProviderStatus;
      googlePlaces: ProviderStatus;
      agora: ProviderStatus;
    };
  };
}

/**
 * Checks external provider configuration readiness safely without exposing credentials.
 */
export function checkProviderReadiness(): HealthCheckResult["checks"]["providers"] {
  return {
    razorpay: {
      configured: Boolean(process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET),
      details: process.env.RAZORPAY_KEY_ID ? "Key ID present" : "Missing credentials",
    },
    fast2sms: {
      configured: Boolean(process.env.FAST2SMS_API_KEY),
      details: process.env.FAST2SMS_API_KEY ? "API key present" : "Missing key (using development mock)",
    },
    firebase: {
      configured: Boolean(
        process.env.FIREBASE_SERVICE_ACCOUNT_BASE64 || process.env.FIREBASE_SERVICE_ACCOUNT_PATH
      ),
      details: process.env.FIREBASE_SERVICE_ACCOUNT_BASE64
        ? "Base64 service account configured"
        : process.env.FIREBASE_SERVICE_ACCOUNT_PATH
        ? "File path configured"
        : "Missing service account (push notifications disabled)",
    },
    googlePlaces: {
      configured: Boolean(process.env.GOOGLE_PLACES_API_KEY),
      details: process.env.GOOGLE_PLACES_API_KEY ? "API key present" : "Missing key (temple discovery mock)",
    },
    agora: {
      configured: Boolean(process.env.AGORA_APP_ID && process.env.AGORA_APP_CERTIFICATE),
      details:
        process.env.AGORA_APP_ID && process.env.AGORA_APP_CERTIFICATE
          ? "App ID and certificate present"
          : "Missing credentials",
    },
  };
}

/**
 * Performs deep readiness checks across Database, Redis, and Providers.
 */
export async function performReadinessCheck(): Promise<HealthCheckResult> {
  const startDb = Date.now();
  let dbStatus: "up" | "down" = "up";
  let dbLatencyMs: number | undefined;
  let dbError: string | undefined;

  try {
    await pool.query("SELECT 1");
    dbLatencyMs = Date.now() - startDb;
  } catch (err: any) {
    dbStatus = "down";
    dbError = err?.message || "Database ping failed";
    logger.error({ err }, "Readiness check: Database down");
  }

  const startRedis = Date.now();
  let redisStatus: "up" | "degraded" | "down" = "up";
  let redisLatencyMs: number | undefined;
  let redisError: string | undefined;

  try {
    const redis = await getRedis();
    if (redis) {
      await redis.ping();
      redisLatencyMs = Date.now() - startRedis;
    } else {
      redisStatus = "degraded";
      redisError = "Redis client unavailable (running in memory fallback)";
    }
  } catch (err: any) {
    redisStatus = "degraded";
    redisError = err?.message || "Redis ping failed";
    logger.warn({ err }, "Readiness check: Redis degraded");
  }

  const providers = checkProviderReadiness();

  let overallStatus: "ok" | "degraded" | "down" = "ok";
  if (dbStatus === "down") {
    overallStatus = "down";
  } else if (redisStatus !== "up") {
    overallStatus = "degraded";
  }

  return {
    status: overallStatus,
    timestamp: new Date().toISOString(),
    uptimeSeconds: Math.floor(process.uptime()),
    checks: {
      database: {
        status: dbStatus,
        latencyMs: dbLatencyMs,
        error: dbError,
      },
      redis: {
        status: redisStatus,
        latencyMs: redisLatencyMs,
        error: redisError,
      },
      providers,
    },
  };
}
