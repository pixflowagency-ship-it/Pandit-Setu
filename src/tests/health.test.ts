import { describe, it, expect, vi, beforeEach } from "vitest";
import request from "supertest";

/* ------------------------------------------------------------------ *
 *  Mock DB and Redis for isolated health tests
 * ------------------------------------------------------------------ */
vi.mock("../config/db.js", () => {
  return {
    default: {
      query: vi.fn().mockResolvedValue({ rows: [{ "?column?": 1 }] }),
    },
    query: vi.fn().mockResolvedValue({ rows: [{ "?column?": 1 }] }),
    testDbConnection: vi.fn().mockResolvedValue(undefined),
  };
});

vi.mock("../config/redis.js", () => {
  return {
    getRedis: vi.fn().mockResolvedValue({
      ping: vi.fn().mockResolvedValue("PONG"),
    }),
    closeRedis: vi.fn().mockResolvedValue(undefined),
  };
});

import app from "../app.js";

describe("Health & Observability Endpoints", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe("GET /health", () => {
    it("200 – returns status UP for backwards compatibility", async () => {
      const res = await request(app).get("/health");
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.status).toBe("UP");
      expect(res.body.timestamp).toBeDefined();
    });
  });

  describe("GET /health/live", () => {
    it("200 – returns liveness status ok with uptimeSeconds", async () => {
      const res = await request(app).get("/health/live");
      expect(res.status).toBe(200);
      expect(res.body.status).toBe("ok");
      expect(typeof res.body.uptimeSeconds).toBe("number");
      expect(res.body.timestamp).toBeDefined();
    });
  });

  describe("GET /health/ready", () => {
    it("200 – returns readiness check with database, redis, and provider configuration status", async () => {
      const res = await request(app).get("/health/ready");
      expect(res.status).toBe(200);
      expect(res.body.status).toBe("ok");
      expect(res.body.checks).toBeDefined();
      expect(res.body.checks.database.status).toBe("up");
      expect(res.body.checks.redis.status).toBe("up");
      expect(res.body.checks.providers).toBeDefined();
      expect(res.body.checks.providers.razorpay).toBeDefined();
      expect(res.body.checks.providers.fast2sms).toBeDefined();
      expect(res.body.checks.providers.firebase).toBeDefined();
      expect(res.body.checks.providers.googlePlaces).toBeDefined();
      expect(res.body.checks.providers.agora).toBeDefined();
    });

    it("503 – returns status down when database ping fails", async () => {
      const db = await import("../config/db.js");
      (db.default.query as any).mockRejectedValueOnce(new Error("Database connection timeout"));
      const res = await request(app).get("/health/ready");
      expect(res.status).toBe(503);
      expect(res.body.status).toBe("down");
      expect(res.body.checks.database.status).toBe("down");
      expect(res.body.checks.database.error).toBe("Database connection timeout");
    });

    it("200 – returns status degraded when redis is unavailable", async () => {
      const { getRedis } = await import("../config/redis.js");
      (getRedis as any).mockResolvedValueOnce(null);
      const res = await request(app).get("/health/ready");
      expect(res.status).toBe(200);
      expect(res.body.status).toBe("degraded");
      expect(res.body.checks.redis.status).toBe("degraded");
    });
  });

  describe("Request Correlation ID Middleware", () => {
    it("generates a new x-request-id header when none is provided", async () => {
      const res = await request(app).get("/health");
      expect(res.headers["x-request-id"]).toBeDefined();
      expect(res.headers["x-request-id"].length).toBeGreaterThan(10);
    });

    it("propagates an existing x-request-id header when supplied", async () => {
      const customId = "req-custom-trace-12345";
      const res = await request(app)
        .get("/health")
        .set("x-request-id", customId);
      expect(res.headers["x-request-id"]).toBe(customId);
    });
  });
});
