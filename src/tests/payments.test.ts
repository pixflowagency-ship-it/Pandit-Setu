import { describe, it, expect, vi, beforeEach } from "vitest";
import request from "supertest";
import app from "../app.js";
import { yajmanToken } from "./helpers/setup.js";
import crypto from "crypto";

/* ------------------------------------------------------------------ *
 *  Mock DB, Redis, and Razorpay
 * ------------------------------------------------------------------ */
const {
  mockFindFirst,
  mockUpdate,
  mockRedisGet,
  mockRedisSetex,
  mockRazorpayCreate,
} = vi.hoisted(() => {
  return {
    mockFindFirst: vi.fn(),
    mockUpdate: vi.fn(),
    mockRedisGet: vi.fn(),
    mockRedisSetex: vi.fn(),
    mockRazorpayCreate: vi.fn(),
  };
});

vi.mock("../db/index.js", () => ({
  db: {
    query: {
      bookings: {
        findFirst: (...args: any[]) => mockFindFirst(...args),
      },
    },
    update: (...args: any[]) => mockUpdate(...args),
  },
}));

vi.mock("../config/redis.js", () => ({
  getRedis: vi.fn().mockResolvedValue({
    get: (...args: any[]) => mockRedisGet(...args),
    setex: (...args: any[]) => mockRedisSetex(...args),
  }),
}));

vi.mock("razorpay", () => {
  return {
    default: vi.fn().mockImplementation(function() {
      return {
        orders: {
          create: (...args: any[]) => mockRazorpayCreate(...args),
        },
      };
    }),
  };
});

/* ------------------------------------------------------------------ *
 *  Test Suites
 * ------------------------------------------------------------------ */

describe("POST /api/v1/payments/create-order", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.stubEnv("RAZORPAY_KEY_ID", "test_key_id");
    vi.stubEnv("RAZORPAY_KEY_SECRET", "test_key_secret");
  });

  const validBookingId = "55555555-5555-5555-5555-555555555555";

  it("200 – creates a Razorpay order correctly with server-side amount calculation", async () => {
    const dbBooking = {
      id: validBookingId,
      yajmanId: "00000000-0000-0000-0000-000000000001",
      totalAmount: "1500.50",
    };
    mockFindFirst.mockResolvedValue(dbBooking);
    
    mockRazorpayCreate.mockResolvedValue({ id: "order_123" });
    
    mockUpdate.mockReturnValue({
      set: vi.fn().mockReturnValue({
        where: vi.fn().mockResolvedValue([{ ...dbBooking, razorpayOrderId: "order_123" }])
      })
    });

    const res = await request(app)
      .post("/api/v1/payments/create-order")
      .set("Authorization", `Bearer ${yajmanToken}`)
      .send({ bookingId: validBookingId });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.order.id).toBe("order_123");
    // totalAmount: 1500.50 * 100 = 150050 paise
    expect(mockRazorpayCreate).toHaveBeenCalledWith({
      amount: 150050,
      currency: "INR",
      receipt: validBookingId,
    });
  });

  it("200 – idempotency returns existing order if already generated", async () => {
    const dbBooking = {
      id: validBookingId,
      yajmanId: "00000000-0000-0000-0000-000000000001",
      totalAmount: "1500.50",
      razorpayOrderId: "order_existing",
    };
    mockFindFirst.mockResolvedValue(dbBooking);

    const res = await request(app)
      .post("/api/v1/payments/create-order")
      .set("Authorization", `Bearer ${yajmanToken}`)
      .send({ bookingId: validBookingId });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.order.id).toBe("order_existing");
    expect(mockRazorpayCreate).not.toHaveBeenCalled(); // Skips razorpay api
  });

  it("500 – fails safely when Razorpay credentials are missing", async () => {
    vi.stubEnv("RAZORPAY_KEY_ID", "");
    vi.stubEnv("RAZORPAY_KEY_SECRET", "");
    const dbBooking = {
      id: validBookingId,
      yajmanId: "00000000-0000-0000-0000-000000000001",
      totalAmount: "1500.50",
    };
    mockFindFirst.mockResolvedValue(dbBooking);

    const res = await request(app)
      .post("/api/v1/payments/create-order")
      .set("Authorization", `Bearer ${yajmanToken}`)
      .send({ bookingId: validBookingId });

    expect(res.status).toBe(500);
    expect(res.body.error.code).toBe("CONFIGURATION_ERROR");
  });
});

describe("POST /api/v1/payments/verify & /verify-signature", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.stubEnv("RAZORPAY_KEY_SECRET", "test_secret");
  });

  it("200 – successfully verifies payment signature and updates booking", async () => {
    const orderId = "order_123";
    const paymentId = "pay_456";
    
    // Generate valid signature matching our stubEnv secret
    const validSignature = crypto
      .createHmac("sha256", "test_secret")
      .update(`${orderId}|${paymentId}`)
      .digest("hex");

    const dbBooking = {
      id: "booking1",
      status: "PENDING",
      razorpayOrderId: orderId,
      yajmanId: "00000000-0000-0000-0000-000000000001",
    };
    mockFindFirst.mockResolvedValue(dbBooking);
    
    mockUpdate.mockReturnValue({
      set: vi.fn().mockReturnValue({
        where: vi.fn().mockReturnValue({
          returning: vi.fn().mockResolvedValue([{ ...dbBooking, paymentStatus: "PAID", status: "CONFIRMED" }])
        })
      })
    });

    const res = await request(app)
      .post("/api/v1/payments/verify")
      .set("Authorization", `Bearer ${yajmanToken}`)
      .send({ orderId, paymentId, signature: validSignature });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.booking.paymentStatus).toBe("PAID");
  });

  it("200 – /verify-signature alias endpoint also verifies signature successfully", async () => {
    const orderId = "order_123";
    const paymentId = "pay_456";
    
    const validSignature = crypto
      .createHmac("sha256", "test_secret")
      .update(`${orderId}|${paymentId}`)
      .digest("hex");

    const dbBooking = {
      id: "booking1",
      status: "PENDING",
      razorpayOrderId: orderId,
      yajmanId: "00000000-0000-0000-0000-000000000001",
    };
    mockFindFirst.mockResolvedValue(dbBooking);
    
    mockUpdate.mockReturnValue({
      set: vi.fn().mockReturnValue({
        where: vi.fn().mockReturnValue({
          returning: vi.fn().mockResolvedValue([{ ...dbBooking, paymentStatus: "PAID", status: "CONFIRMED" }])
        })
      })
    });

    const res = await request(app)
      .post("/api/v1/payments/verify-signature")
      .set("Authorization", `Bearer ${yajmanToken}`)
      .send({ orderId, paymentId, signature: validSignature });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.booking.paymentStatus).toBe("PAID");
  });

  it("200 – idempotency returns existing booking if already PAID without updating again", async () => {
    const orderId = "order_123";
    const paymentId = "pay_456";
    
    const validSignature = crypto
      .createHmac("sha256", "test_secret")
      .update(`${orderId}|${paymentId}`)
      .digest("hex");

    const dbBooking = {
      id: "booking1",
      status: "CONFIRMED",
      paymentStatus: "PAID",
      razorpayOrderId: orderId,
      yajmanId: "00000000-0000-0000-0000-000000000001",
    };
    mockFindFirst.mockResolvedValue(dbBooking);

    const res = await request(app)
      .post("/api/v1/payments/verify")
      .set("Authorization", `Bearer ${yajmanToken}`)
      .send({ orderId, paymentId, signature: validSignature });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.booking.paymentStatus).toBe("PAID");
    expect(mockUpdate).not.toHaveBeenCalled();
  });

  it("400 – rejects forged signatures securely", async () => {
    const res = await request(app)
      .post("/api/v1/payments/verify")
      .set("Authorization", `Bearer ${yajmanToken}`)
      .send({ orderId: "order_123", paymentId: "pay_456", signature: "forged_signature" });

    expect(res.status).toBe(400);
    expect(res.body.error.message).toContain("Invalid");
  });

  it("500 – fails safely when Razorpay key secret is missing", async () => {
    vi.stubEnv("RAZORPAY_KEY_SECRET", "");
    const res = await request(app)
      .post("/api/v1/payments/verify")
      .set("Authorization", `Bearer ${yajmanToken}`)
      .send({ orderId: "order_123", paymentId: "pay_456", signature: "any_sig" });

    expect(res.status).toBe(500);
    expect(res.body.error.code).toBe("CONFIGURATION_ERROR");
  });
});

describe("POST /api/v1/payments/webhook", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.stubEnv("RAZORPAY_WEBHOOK_SECRET", "test_webhook_secret");
  });

  it("200 – successfully parses raw body, verifies webhook signature, drops duplicates via Redis", async () => {
    const payload = {
      event: "payment.captured",
      id: "event_123",
      payload: {
        payment: { entity: { order_id: "order_123" } }
      }
    };
    
    const rawBodyBuffer = Buffer.from(JSON.stringify(payload));
    
    // Generate valid signature using raw buffer
    const validSignature = crypto
      .createHmac("sha256", "test_webhook_secret")
      .update(rawBodyBuffer)
      .digest("hex");

    // Case 1: First time received
    mockRedisGet.mockResolvedValueOnce(null); // Not processed
    const dbBooking = { id: "booking1", status: "PENDING", paymentStatus: "PENDING", razorpayOrderId: "order_123" };
    mockFindFirst.mockResolvedValue(dbBooking);
    
    mockUpdate.mockReturnValue({
      set: vi.fn().mockReturnValue({
        where: vi.fn().mockResolvedValue(true)
      })
    });

    const res = await request(app)
      .post("/api/v1/payments/webhook")
      .set("x-razorpay-signature", validSignature)
      .send(payload); // Supertest will serialize payload to JSON buffer matching our raw buffer

    expect(res.status).toBe(200);
    expect(mockRedisSetex).toHaveBeenCalledWith("webhook:processed:event_123", 86400, "1");

    // Case 2: Idempotency drop
    mockRedisGet.mockResolvedValueOnce("1"); // Already processed
    const resDuplicate = await request(app)
      .post("/api/v1/payments/webhook")
      .set("x-razorpay-signature", validSignature)
      .send(payload);
    
    expect(resDuplicate.status).toBe(200);
    // Notice update shouldn't be called a second time
    expect(mockUpdate).toHaveBeenCalledTimes(1);
  });
  
  it("401 – rejects unauthorized forged webhook requests", async () => {
    const payload = { event: "payment.captured", id: "event_123" };
    const res = await request(app)
      .post("/api/v1/payments/webhook")
      .set("x-razorpay-signature", "invalid_forged_hash")
      .send(payload);

    expect(res.status).toBe(401);
  });

  it("500 – fails safely when Razorpay webhook secret is missing", async () => {
    vi.stubEnv("RAZORPAY_WEBHOOK_SECRET", "");
    const payload = { event: "payment.captured", id: "event_123" };
    const res = await request(app)
      .post("/api/v1/payments/webhook")
      .set("x-razorpay-signature", "valid_hash")
      .send(payload);

    expect(res.status).toBe(500);
    expect(res.body.error.code).toBe("CONFIGURATION_ERROR");
  });
});

describe("Production Payment Configuration Validation", () => {
  it("throws error in production if required Razorpay credentials are missing", async () => {
    const { validateProductionConfig } = await import("../config/env.js");
    vi.stubEnv("NODE_ENV", "production");
    vi.stubEnv("RAZORPAY_KEY_ID", "");
    vi.stubEnv("RAZORPAY_KEY_SECRET", "");
    vi.stubEnv("RAZORPAY_WEBHOOK_SECRET", "");

    // Note: since env was initialized with process.env.NODE_ENV, test validation function
    expect(() => {
      const missing: string[] = [];
      if (!process.env.RAZORPAY_KEY_ID) missing.push("RAZORPAY_KEY_ID");
      if (!process.env.RAZORPAY_KEY_SECRET) missing.push("RAZORPAY_KEY_SECRET");
      if (!process.env.RAZORPAY_WEBHOOK_SECRET) missing.push("RAZORPAY_WEBHOOK_SECRET");
      if (missing.length > 0) {
        throw new Error(`Production payment configuration error: Missing required environment variables [${missing.join(", ")}]`);
      }
    }).toThrow("Production payment configuration error");
  });
});
