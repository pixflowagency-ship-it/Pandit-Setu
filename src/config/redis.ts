import { Redis } from "ioredis";
import { env } from "./env.js";
import { logger } from "../utils/logger.js";

let redis: Redis | null = null;

function createRedisClient(): Redis {
  const client = new Redis(env.redisUrl, {
    maxRetriesPerRequest: 1,
    retryStrategy(times: number) {
      if (times > 3) {
        logger.warn("Redis: giving up after 3 retries — idempotency cache disabled");
        return null;
      }
      return Math.min(times * 200, 2000);
    },
    lazyConnect: true,
  });

  client.on("error", (err: Error) => {
    logger.warn({ err: err.message }, "Redis connection error (non-fatal)");
  });

  client.on("connect", () => {
    logger.info("Redis connected");
  });

  return client;
}

/**
 * Returns the Redis client, lazily connecting on first call.
 * Returns `null` if connection fails — callers must handle gracefully.
 */
export async function getRedis(): Promise<Redis | null> {
  if (!redis) {
    redis = createRedisClient();
  }

  try {
    if (redis.status === "ready") return redis;
    if (redis.status === "connecting") {
      await redis.connect();
      return redis;
    }
    if (redis.status === "wait") {
      await redis.connect();
      return redis;
    }
    // reconnect if closed / end
    redis = createRedisClient();
    await redis.connect();
    return redis;
  } catch {
    logger.warn("Redis unavailable — idempotency cache disabled for this request");
    return null;
  }
}
