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
  mockInsert,
  mockUpdate,
  mockRedisGet,
  mockRedisSetex,
  mockRazorpaySubCreate,
} = vi.hoisted(() => {
  return {
    mockFindFirst: vi.fn(),
    mockInsert: vi.fn(),
    mockUpdate: vi.fn(),
    mockRedisGet: vi.fn(),
    mockRedisSetex: vi.fn(),
    mockRazorpaySubCreate: vi.fn(),
  };
});

vi.mock("../db/index.js", () => ({
  db: {
    query: {
      subscriptions: {
        findFirst: (...args: any[]) => mockFindFirst(...args),
      },
    },
    insert: (...args: any[]) => mockInsert(...args),
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
        subscriptions: {
          create: (...args: any[]) => mockRazorpaySubCreate(...args),
        },
      };
    }),
  };
});

/* ------------------------------------------------------------------ *
 *  Test Suites
 * ------------------------------------------------------------------ */

describe("POST /api/v1/subscriptions", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("200 – creates a Razorpay subscription correctly", async () => {
    mockRazorpaySubCreate.mockResolvedValue({ id: "sub_123" });
    
    mockInsert.mockReturnValue({
      values: vi.fn().mockReturnValue({
        returning: vi.fn().mockResolvedValue([{ id: "db_sub_1", razorpaySubscriptionId: "sub_123", status: "CREATED" }])
      })
    });

    const res = await request(app)
      .post("/api/v1/subscriptions")
      .set("Authorization", `Bearer ${yajmanToken}`)
      .send({ planId: "plan_test123" });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.subscription.razorpaySubscriptionId).toBe("sub_123");
    expect(mockRazorpaySubCreate).toHaveBeenCalledWith({
      plan_id: "plan_test123",
      total_count: 12,
      customer_notify: 1,
    });
  });
});

describe("POST /api/v1/payments/webhook (Subscriptions)", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.stubEnv("RAZORPAY_WEBHOOK_SECRET", "test_webhook_secret");
  });

  const sendWebhook = async (eventBody: any) => {
    const rawBodyBuffer = Buffer.from(JSON.stringify(eventBody));
    const validSignature = crypto
      .createHmac("sha256", "test_webhook_secret")
      .update(rawBodyBuffer)
      .digest("hex");
      
    return request(app)
      .post("/api/v1/payments/webhook")
      .set("x-razorpay-signature", validSignature)
      .send(eventBody);
  };

  it("200 – subscription.activated correctly updates DB to ACTIVE", async () => {
    const payload = {
      event: "subscription.activated",
      id: "event_sub_act",
      payload: {
        subscription: { entity: { id: "sub_123" } }
      }
    };
    
    mockRedisGet.mockResolvedValueOnce(null);
    mockFindFirst.mockResolvedValue({ id: "db_sub_1", razorpaySubscriptionId: "sub_123" });
    
    const updateSetMock = vi.fn().mockReturnValue({
      where: vi.fn().mockResolvedValue(true)
    });
    mockUpdate.mockReturnValue({ set: updateSetMock });

    const res = await sendWebhook(payload);

    expect(res.status).toBe(200);
    expect(updateSetMock).toHaveBeenCalledWith(expect.objectContaining({ status: "ACTIVE" }));
  });
  
  it("200 – subscription.charged correctly updates currentPeriodEnd", async () => {
    const currentEnd = 1672531199; // Some unix timestamp
    const payload = {
      event: "subscription.charged",
      id: "event_sub_charge",
      payload: {
        subscription: { entity: { id: "sub_123", current_end: currentEnd } }
      }
    };
    
    mockRedisGet.mockResolvedValueOnce(null);
    mockFindFirst.mockResolvedValue({ id: "db_sub_1", razorpaySubscriptionId: "sub_123" });
    
    const updateSetMock = vi.fn().mockReturnValue({
      where: vi.fn().mockResolvedValue(true)
    });
    mockUpdate.mockReturnValue({ set: updateSetMock });

    const res = await sendWebhook(payload);

    expect(res.status).toBe(200);
    expect(updateSetMock).toHaveBeenCalledWith(expect.objectContaining({ 
      status: "ACTIVE",
      currentPeriodEnd: new Date(currentEnd * 1000)
    }));
  });
});
