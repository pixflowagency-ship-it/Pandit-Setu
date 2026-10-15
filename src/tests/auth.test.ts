import { describe, it, expect, vi, beforeEach } from "vitest";
import request from "supertest";

/* ------------------------------------------------------------------ *
 *  Mock the DB module – must come BEFORE importing `app`              *
 * ------------------------------------------------------------------ */
vi.mock("../db/index.js", () => {
  const mockDb = {
    query: {
      users: { findFirst: vi.fn() },
      pandits: { findFirst: vi.fn() },
    },
    insert: vi.fn().mockReturnValue({
      values: vi.fn().mockReturnValue({
        returning: vi.fn().mockResolvedValue([{ id: "p1", verificationStatus: "PENDING", verificationStage: "STAGE_1_COMPLETE", isVerified: false }]),
        onConflictDoNothing: vi.fn().mockResolvedValue([]),
      }),
    }),
    select: vi.fn().mockReturnThis(),
    update: vi.fn().mockReturnThis(),
  };
  return { db: mockDb, users: {}, pandits: {}, poojas: {}, products: {}, bookings: {} };
});

/* Mock OTP service so we can control verification results */
vi.mock("../services/otp.service.js", () => ({
  createOtp: vi.fn().mockResolvedValue("123456"),
  verifyOtp: vi.fn().mockResolvedValue(true),
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
    mockedVerifyOtp.mockResolvedValue(false);

    const res = await request(app)
      .post("/api/v1/auth/verify-otp")
      .send({ phone: "9876543210", otp: "000000" });

    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe("INVALID_OTP");
  });

  it("400 – rejects invalid role parameter", async () => {
    const res = await request(app)
      .post("/api/v1/auth/verify-otp")
      .send({ phone: "9876543210", otp: "123456", role: "ADMIN" });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("VALIDATION_ERROR");
  });

  it("200 – verifies OTP and accepts valid PANDIT role", async () => {
    mockedVerifyOtp.mockResolvedValue(true);
    const { db } = await import("../db/index.js");
    const mockUser = {
      id: "u-pandit-123",
      phone: "9876543210",
      name: "Pandit Shastri",
      fullName: "Pandit Shastri",
      role: "PANDIT",
      dob: "1980-01-01",
      city: "Varanasi",
    };
    (db.query.users.findFirst as any).mockResolvedValue(mockUser);
    (db.query.pandits.findFirst as any).mockResolvedValue({
      id: "p1",
      userId: "u-pandit-123",
      verificationStatus: "APPROVED",
      verificationStage: "APPROVED",
      isVerified: true,
    });

    const res = await request(app)
      .post("/api/v1/auth/verify-otp")
      .send({ phone: "9876543210", otp: "123456", role: "PANDIT" });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.role).toBe("PANDIT");
    expect(res.body.data.user.fullName).toBe("Pandit Shastri");
    expect(res.body.data.user.dob).toBe("1980-01-01");
  });

  it("200 – existing Yajman logs in to Yajman portal with YAJMAN role", async () => {
    mockedVerifyOtp.mockResolvedValue(true);
    const { db } = await import("../db/index.js");
    const mockUser = {
      id: "u-yajman-999",
      phone: "9876543210",
      name: "Devotee Ramesh",
      role: "YAJMAN",
    };
    (db.query.users.findFirst as any).mockResolvedValue(mockUser);
    (db.query.pandits.findFirst as any).mockResolvedValue(null);

    const res = await request(app)
      .post("/api/v1/auth/verify-otp")
      .send({ phone: "9876543210", otp: "123456", role: "YAJMAN" });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.role).toBe("YAJMAN");
    expect(res.body.data.hasPanditProfile).toBe(false);
  });

  it("200 – Yajman attempting Pandit login without application receives requiresApplication: true", async () => {
    mockedVerifyOtp.mockResolvedValue(true);
    const { db } = await import("../db/index.js");
    const mockUser = {
      id: "u-yajman-999",
      phone: "9876543210",
      name: "Devotee Ramesh",
      role: "YAJMAN",
    };
    (db.query.users.findFirst as any).mockResolvedValue(mockUser);
    (db.query.pandits.findFirst as any).mockResolvedValue(null); // No pandit record exists

    const res = await request(app)
      .post("/api/v1/auth/verify-otp")
      .send({ phone: "9876543210", otp: "123456", role: "PANDIT" });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.requiresApplication).toBe(true);
    expect(res.body.data.isPandit).toBe(false);
  });

  it("200 – existing Pandit can use same phone to log into Yajman portal", async () => {
    mockedVerifyOtp.mockResolvedValue(true);
    const { db } = await import("../db/index.js");
    const mockUser = {
      id: "u-dual-123",
      phone: "9876543210",
      name: "Acharya Dev",
      role: "PANDIT",
    };
    (db.query.users.findFirst as any).mockResolvedValue(mockUser);
    (db.query.pandits.findFirst as any).mockResolvedValue({
      id: "pandit-rec-1",
      userId: "u-dual-123",
      verificationStatus: "APPROVED",
      isVerified: true,
    });

    const res = await request(app)
      .post("/api/v1/auth/verify-otp")
      .send({ phone: "9876543210", otp: "123456", role: "YAJMAN" });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.role).toBe("YAJMAN");
    expect(res.body.data.hasPanditProfile).toBe(true);
  });

  it("200 – pending Pandit logging into Pandit portal receives PENDING verification status", async () => {
    mockedVerifyOtp.mockResolvedValue(true);
    const { db } = await import("../db/index.js");
    const mockUser = {
      id: "u-pending-123",
      phone: "9876543210",
      name: "Acharya InReview",
      role: "PANDIT",
    };
    (db.query.users.findFirst as any).mockResolvedValue(mockUser);
    (db.query.pandits.findFirst as any).mockResolvedValue({
      id: "pandit-pending-1",
      userId: "u-pending-123",
      verificationStatus: "PENDING",
      verificationStage: "STAGE_3_DOCS_SUBMITTED",
      isVerified: false,
    });

    const res = await request(app)
      .post("/api/v1/auth/verify-otp")
      .send({ phone: "9876543210", otp: "123456", role: "PANDIT" });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.isPandit).toBe(true);
    expect(res.body.data.pandit.verificationStatus).toBe("PENDING");
    expect(res.body.data.pandit.isVerified).toBe(false);
  });

  it("401 – rejects invalid or malformed bearer token", async () => {
    const res = await request(app)
      .get("/api/v1/users/profile")
      .set("Authorization", "Bearer invalid.malformed.token");

    expect(res.status).toBe(401);
  });
});
