import { describe, it, expect, vi, beforeEach } from "vitest";
import request from "supertest";

/* ------------------------------------------------------------------ *
 *  Mock the DB module – must come BEFORE importing `app`              *
 * ------------------------------------------------------------------ */
vi.mock("../db/index.js", () => {
  const mockDb = {
    query: { users: { findFirst: vi.fn() } },
    insert: vi.fn().mockReturnThis(),
    select: vi.fn().mockReturnThis(),
    update: vi.fn().mockReturnThis(),
  };
  return { db: mockDb, users: {}, poojas: {}, products: {}, bookings: {} };
});

/* Mock OTP service so we can control verification results */
vi.mock("../services/otp.service.js", () => ({
  createOtp: vi.fn().mockReturnValue("123456"),
  verifyOtp: vi.fn(),
  normalizePhone: (p: string) => p.replace(/\s+/g, "").trim(),
  getOtpExpirySeconds: () => 300,
}));

/* Mock SMS service — no real SMS in tests */
vi.mock("../services/sms.service.js", () => ({
  sendSmsOtp: vi.fn().mockResolvedValue(undefined),
}));

import app from "../app.js";
import { verifyOtp } from "../services/otp.service.js";

const mockedVerifyOtp = vi.mocked(verifyOtp);

describe("POST /api/v1/auth/send-otp", () => {
  it("200 – sends OTP for a valid phone", async () => {
    const res = await request(app)
      .post("/api/v1/auth/send-otp")
      .send({ phone: "9876543210" });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty("expiresInSeconds");
  });

  it("400 – rejects invalid phone", async () => {
    const res = await request(app)
      .post("/api/v1/auth/send-otp")
      .send({ phone: "123" });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe("VALIDATION_ERROR");
  });

  it("400 – rejects unknown fields (.strict)", async () => {
    const res = await request(app)
      .post("/api/v1/auth/send-otp")
      .send({ phone: "9876543210", hack: true });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("VALIDATION_ERROR");
  });
});

describe("POST /api/v1/auth/verify-otp", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("401 – rejects wrong OTP", async () => {
    mockedVerifyOtp.mockReturnValue(false);

    const res = await request(app)
      .post("/api/v1/auth/verify-otp")
      .send({ phone: "9876543210", otp: "000000" });

    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe("INVALID_OTP");
  });

  it("400 – rejects missing OTP field", async () => {
    const res = await request(app)
      .post("/api/v1/auth/verify-otp")
      .send({ phone: "9876543210" });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("VALIDATION_ERROR");
  });
});
