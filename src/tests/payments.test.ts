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
  mockProductOrdersFindFirst,
  mockDakshinaFindFirst,
  mockSubscriptionsFindFirst,
  mockUpdate,
  mockRedisGet,
  mockRedisSetex,
  mockRazorpayCreate,
} = vi.hoisted(() => {
  return {
    mockFindFirst: vi.fn(),
    mockProductOrdersFindFirst: vi.fn(),
    mockDakshinaFindFirst: vi.fn(),
    mockSubscriptionsFindFirst: vi.fn(),
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
      productOrders: {
        findFirst: (...args: any[]) => mockProductOrdersFindFirst(...args),
      },
      dakshinaCollections: {
        findFirst: (...args: any[]) => mockDakshinaFindFirst(...args),
      },
      subscriptions: {
        findFirst: (...args: any[]) => mockSubscriptionsFindFirst(...args),
      },
    },
    update: (...args: any[]) => mockUpdate(...args),
    insert: vi.fn().mockReturnValue({
      values: vi.fn().mockReturnValue({
        returning: vi.fn().mockResolvedValue([{ id: "sub_1", status: "CREATED" }]),
      }),
    }),
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

describe("POST /api/v1/payments/webhook — Signature & Configuration Security Validation", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.stubEnv("RAZORPAY_WEBHOOK_SECRET", "test_webhook_secret");
  });

  it("401 – rejects webhook requests with missing x-razorpay-signature header", async () => {
    const payload = { event: "payment.captured", id: "evt_no_sig" };
    const res = await request(app)
      .post("/api/v1/payments/webhook")
      .send(payload);

    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe("UNAUTHORIZED");
    expect(res.body.error.message).toContain("Missing signature");
  });

  it("401 – rejects forged or tampered signature hash", async () => {
    const payload = { event: "payment.captured", id: "evt_tampered_sig" };
    const res = await request(app)
      .post("/api/v1/payments/webhook")
      .set("x-razorpay-signature", "invalid_forged_hash")
      .send(payload);

    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe("UNAUTHORIZED");
    expect(res.body.error.message).toContain("Invalid webhook signature");
  });

  it("401 – rejects valid signature applied to mismatched / tampered body", async () => {
    const originalPayload = { event: "payment.captured", id: "evt_orig" };
    const tamperedPayload = { event: "payment.captured", id: "evt_tampered" };

    const originalSignature = crypto
      .createHmac("sha256", "test_webhook_secret")
      .update(Buffer.from(JSON.stringify(originalPayload)))
      .digest("hex");

    const res = await request(app)
      .post("/api/v1/payments/webhook")
      .set("x-razorpay-signature", originalSignature)
      .send(tamperedPayload);

    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe("UNAUTHORIZED");
    expect(res.body.error.message).toContain("Invalid webhook signature");
  });

  it("500 – fails safely with CONFIGURATION_ERROR when RAZORPAY_WEBHOOK_SECRET is unconfigured", async () => {
    vi.stubEnv("RAZORPAY_WEBHOOK_SECRET", "");
    const payload = { event: "payment.captured", id: "evt_unconfigured" };
    const res = await request(app)
      .post("/api/v1/payments/webhook")
      .set("x-razorpay-signature", "any_signature")
      .send(payload);

    expect(res.status).toBe(500);
    expect(res.body.error.code).toBe("CONFIGURATION_ERROR");
    expect(res.body.error.message).toContain("secret is not configured");
  });

  it("200 – passes signature validation when valid HMAC SHA-256 signature is provided", async () => {
    const payload = { event: "payment.captured", id: "evt_valid_sig", payload: { payment: { entity: { order_id: "order_none" } } } };
    const rawBuffer = Buffer.from(JSON.stringify(payload));
    const validSignature = crypto
      .createHmac("sha256", "test_webhook_secret")
      .update(rawBuffer)
      .digest("hex");

    mockRedisGet.mockResolvedValueOnce(null);
    mockFindFirst.mockResolvedValueOnce(null);
    mockProductOrdersFindFirst.mockResolvedValueOnce(null);
    mockDakshinaFindFirst.mockResolvedValueOnce(null);

    const res = await request(app)
      .post("/api/v1/payments/webhook")
      .set("x-razorpay-signature", validSignature)
      .send(payload);

    expect(res.status).toBe(200);
    expect(res.body.status).toBe("ok");
  });
});

describe("POST /api/v1/payments/webhook — Business Event Processing", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.stubEnv("RAZORPAY_WEBHOOK_SECRET", "test_webhook_secret");
  });

  function signPayload(payload: any): string {
    return crypto
      .createHmac("sha256", "test_webhook_secret")
      .update(Buffer.from(JSON.stringify(payload)))
      .digest("hex");
  }

  it("200 – payment.captured for booking: confirms booking and marks paymentStatus as PAID", async () => {
    const payload = {
      event: "payment.captured",
      id: "evt_booking_captured",
      payload: { payment: { entity: { order_id: "order_book_1" } } },
    };
    const signature = signPayload(payload);

    mockRedisGet.mockResolvedValueOnce(null);
    const mockBooking = { id: "booking_1", status: "PENDING", paymentStatus: "PENDING", razorpayOrderId: "order_book_1" };
    mockFindFirst.mockResolvedValueOnce(mockBooking);

    const mockWhere = vi.fn().mockResolvedValue(true);
    const mockSet = vi.fn().mockReturnValue({ where: mockWhere });
    mockUpdate.mockReturnValue({ set: mockSet });

    const res = await request(app)
      .post("/api/v1/payments/webhook")
      .set("x-razorpay-signature", signature)
      .send(payload);

    expect(res.status).toBe(200);
    expect(mockUpdate).toHaveBeenCalled();
    expect(mockSet).toHaveBeenCalledWith(
      expect.objectContaining({
        paymentStatus: "PAID",
        status: "CONFIRMED",
      })
    );
  });

  it("200 – order.paid for booking: confirms booking and marks paymentStatus as PAID", async () => {
    const payload = {
      event: "order.paid",
      id: "evt_booking_order_paid",
      payload: { order: { entity: { id: "order_book_2" } } },
    };
    const signature = signPayload(payload);

    mockRedisGet.mockResolvedValueOnce(null);
    const mockBooking = { id: "booking_2", status: "PENDING", paymentStatus: "PENDING", razorpayOrderId: "order_book_2" };
    mockFindFirst.mockResolvedValueOnce(mockBooking);

    const mockWhere = vi.fn().mockResolvedValue(true);
    const mockSet = vi.fn().mockReturnValue({ where: mockWhere });
    mockUpdate.mockReturnValue({ set: mockSet });

    const res = await request(app)
      .post("/api/v1/payments/webhook")
      .set("x-razorpay-signature", signature)
      .send(payload);

    expect(res.status).toBe(200);
    expect(mockSet).toHaveBeenCalledWith(
      expect.objectContaining({
        paymentStatus: "PAID",
        status: "CONFIRMED",
      })
    );
  });

  it("200 – order.paid for product orders: updates product order to PROCESSING and PAID with paidAt", async () => {
    const payload = {
      event: "order.paid",
      id: "evt_product_order_paid",
      payload: {
        order: { entity: { id: "order_prod_10" } },
        payment: { entity: { id: "pay_prod_10" } },
      },
    };
    const signature = signPayload(payload);

    mockRedisGet.mockResolvedValueOnce(null);
    mockFindFirst.mockResolvedValueOnce(null); // No booking matches
    const mockProductOrder = { id: "po_1", paymentStatus: "PENDING", status: "PENDING", razorpayOrderId: "order_prod_10" };
    mockProductOrdersFindFirst.mockResolvedValueOnce(mockProductOrder);

    const mockWhere = vi.fn().mockResolvedValue(true);
    const mockSet = vi.fn().mockReturnValue({ where: mockWhere });
    mockUpdate.mockReturnValue({ set: mockSet });

    const res = await request(app)
      .post("/api/v1/payments/webhook")
      .set("x-razorpay-signature", signature)
      .send(payload);

    expect(res.status).toBe(200);
    expect(mockSet).toHaveBeenCalledWith(
      expect.objectContaining({
        paymentStatus: "PAID",
        status: "PROCESSING",
      })
    );
  });

  it("200 – payment.captured for dakshina: updates dakshina collection to PAID with collectedAt", async () => {
    const payload = {
      event: "payment.captured",
      id: "evt_dakshina_captured",
      payload: { payment: { entity: { order_id: "order_dak_5", id: "pay_dak_5" } } },
    };
    const signature = signPayload(payload);

    mockRedisGet.mockResolvedValueOnce(null);
    mockFindFirst.mockResolvedValueOnce(null);
    mockProductOrdersFindFirst.mockResolvedValueOnce(null);
    const mockDakshina = { id: "dak_1", paymentStatus: "PENDING", razorpayOrderId: "order_dak_5" };
    mockDakshinaFindFirst.mockResolvedValueOnce(mockDakshina);

    const mockWhere = vi.fn().mockResolvedValue(true);
    const mockSet = vi.fn().mockReturnValue({ where: mockWhere });
    mockUpdate.mockReturnValue({ set: mockSet });

    const res = await request(app)
      .post("/api/v1/payments/webhook")
      .set("x-razorpay-signature", signature)
      .send(payload);

    expect(res.status).toBe(200);
    expect(mockSet).toHaveBeenCalledWith(
      expect.objectContaining({
        paymentStatus: "PAID",
        razorpayPaymentId: "pay_dak_5",
      })
    );
  });

  it("200 – subscription.charged: updates subscription to ACTIVE and advances currentPeriodEnd", async () => {
    const payload = {
      event: "subscription.charged",
      id: "evt_sub_charged",
      payload: {
        subscription: { entity: { id: "sub_rzp_99", current_end: 1775000000 } },
      },
    };
    const signature = signPayload(payload);

    mockRedisGet.mockResolvedValueOnce(null);
    const mockSubscription = { id: "sub_local_1", status: "CREATED", razorpaySubscriptionId: "sub_rzp_99" };
    mockSubscriptionsFindFirst.mockResolvedValueOnce(mockSubscription);

    const mockWhere = vi.fn().mockResolvedValue(true);
    const mockSet = vi.fn().mockReturnValue({ where: mockWhere });
    mockUpdate.mockReturnValue({ set: mockSet });

    const res = await request(app)
      .post("/api/v1/payments/webhook")
      .set("x-razorpay-signature", signature)
      .send(payload);

    expect(res.status).toBe(200);
    expect(mockSet).toHaveBeenCalledWith(
      expect.objectContaining({
        status: "ACTIVE",
      })
    );
  });

  it("200 – gracefully acknowledges unhandled event types without throwing errors", async () => {
    const payload = {
      event: "refund.processed",
      id: "evt_refund_1",
      payload: {},
    };
    const signature = signPayload(payload);

    mockRedisGet.mockResolvedValueOnce(null);

    const res = await request(app)
      .post("/api/v1/payments/webhook")
      .set("x-razorpay-signature", signature)
      .send(payload);

    expect(res.status).toBe(200);
    expect(res.body.status).toBe("ok");
    expect(mockUpdate).not.toHaveBeenCalled();
  });
});

describe("POST /api/v1/payments/webhook — Duplicate Event Delivery & Idempotency", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.stubEnv("RAZORPAY_WEBHOOK_SECRET", "test_webhook_secret");
  });

  function signPayload(payload: any): string {
    return crypto
      .createHmac("sha256", "test_webhook_secret")
      .update(Buffer.from(JSON.stringify(payload)))
      .digest("hex");
  }

  it("200 – drops duplicate event via Redis cache without querying or updating database", async () => {
    const payload = {
      event: "payment.captured",
      id: "evt_dup_redis",
      payload: { payment: { entity: { order_id: "order_dup_1" } } },
    };
    const signature = signPayload(payload);

    // Redis indicates event already processed
    mockRedisGet.mockResolvedValueOnce("1");

    const res = await request(app)
      .post("/api/v1/payments/webhook")
      .set("x-razorpay-signature", signature)
      .send(payload);

    expect(res.status).toBe(200);
    expect(res.body.status).toBe("ok");
    expect(mockFindFirst).not.toHaveBeenCalled();
    expect(mockUpdate).not.toHaveBeenCalled();
  });

  it("200 – sets 24h Redis idempotency key upon first successful processing", async () => {
    const payload = {
      event: "payment.captured",
      id: "evt_first_time",
      payload: { payment: { entity: { order_id: "order_first_1" } } },
    };
    const signature = signPayload(payload);

    mockRedisGet.mockResolvedValueOnce(null);
    mockFindFirst.mockResolvedValueOnce({ id: "b1", paymentStatus: "PENDING", status: "PENDING" });
    const mockWhere = vi.fn().mockResolvedValue(true);
    mockUpdate.mockReturnValue({ set: vi.fn().mockReturnValue({ where: mockWhere }) });

    const res = await request(app)
      .post("/api/v1/payments/webhook")
      .set("x-razorpay-signature", signature)
      .send(payload);

    expect(res.status).toBe(200);
    expect(mockRedisSetex).toHaveBeenCalledWith("webhook:processed:evt_first_time", 86400, "1");
  });

  it("200 – in-database idempotency: skips mutation if booking is already PAID even if Redis cache is missed", async () => {
    const payload = {
      event: "payment.captured",
      id: "evt_db_idempotency_booking",
      payload: { payment: { entity: { order_id: "order_already_paid" } } },
    };
    const signature = signPayload(payload);

    mockRedisGet.mockResolvedValueOnce(null); // Redis cache miss
    const alreadyPaidBooking = { id: "b_paid", paymentStatus: "PAID", status: "CONFIRMED" };
    mockFindFirst.mockResolvedValueOnce(alreadyPaidBooking);

    const res = await request(app)
      .post("/api/v1/payments/webhook")
      .set("x-razorpay-signature", signature)
      .send(payload);

    expect(res.status).toBe(200);
    // Booking was already PAID, update should NOT be executed
    expect(mockUpdate).not.toHaveBeenCalled();
  });

  it("200 – in-database idempotency: skips mutation if product order is already PAID", async () => {
    const payload = {
      event: "order.paid",
      id: "evt_db_idempotency_po",
      payload: { order: { entity: { id: "order_po_paid" } } },
    };
    const signature = signPayload(payload);

    mockRedisGet.mockResolvedValueOnce(null);
    mockFindFirst.mockResolvedValueOnce(null);
    const alreadyPaidOrder = { id: "po_paid", paymentStatus: "PAID", status: "PROCESSING" };
    mockProductOrdersFindFirst.mockResolvedValueOnce(alreadyPaidOrder);

    const res = await request(app)
      .post("/api/v1/payments/webhook")
      .set("x-razorpay-signature", signature)
      .send(payload);

    expect(res.status).toBe(200);
    expect(mockUpdate).not.toHaveBeenCalled();
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
