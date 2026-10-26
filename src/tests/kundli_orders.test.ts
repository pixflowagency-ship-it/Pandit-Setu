import { describe, it, expect, vi, beforeEach } from "vitest";
import request from "supertest";
import app from "../app.js";
import { yajmanToken, adminToken, signTestToken } from "./helpers/setup.js";
import crypto from "crypto";

const devoteeId = "00000000-0000-0000-0000-000000000001";
const otherDevoteeId = "22222222-2222-2222-2222-222222222222";
const otherDevoteeToken = signTestToken({
  id: otherDevoteeId,
  phone: "+919876543299",
  role: "YAJMAN",
});

const testOrderId = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";
const assignedPanditId = "33333333-3333-3333-3333-333333333333";

/* ------------------------------------------------------------------ *
 *  Mock DB, Redis, and Razorpay                                       *
 * ------------------------------------------------------------------ */
const {
  mockFindFirstUser,
  mockFindFirstKundli,
  mockFindManyKundli,
  mockCountKundli,
  mockInsertKundli,
  mockUpdateKundli,
  mockFindFirstPandit,
  mockRazorpayCreate,
} = vi.hoisted(() => {
  return {
    mockFindFirstUser: vi.fn(),
    mockFindFirstKundli: vi.fn(),
    mockFindManyKundli: vi.fn(),
    mockCountKundli: vi.fn(),
    mockInsertKundli: vi.fn(),
    mockUpdateKundli: vi.fn(),
    mockFindFirstPandit: vi.fn(),
    mockRazorpayCreate: vi.fn(),
  };
});

vi.mock("../db/index.js", () => {
  return {
    db: {
      query: {
        users: {
          findFirst: (...args: any[]) => mockFindFirstUser(...args),
        },
        kundliOrders: {
          findFirst: (...args: any[]) => mockFindFirstKundli(...args),
          findMany: (...args: any[]) => mockFindManyKundli(...args),
        },
        pandits: {
          findFirst: (...args: any[]) => mockFindFirstPandit(...args),
        },
      },
      select: () => ({
        from: () => ({
          where: () => mockCountKundli(),
        }),
      }),
      insert: () => ({
        values: (data: any) => ({
          returning: () => mockInsertKundli(data),
        }),
      }),
      update: () => ({
        set: (data: any) => ({
          where: () => ({
            returning: () => mockUpdateKundli(data),
          }),
        }),
      }),
    },
  };
});

vi.mock("../config/redis.js", () => {
  return {
    redis: {
      get: vi.fn().mockResolvedValue(null),
      set: vi.fn().mockResolvedValue("OK"),
      del: vi.fn().mockResolvedValue(1),
    },
  };
});

vi.mock("razorpay", () => {
  return {
    default: vi.fn().mockImplementation(function () {
      return {
        orders: {
          create: (...args: any[]) => mockRazorpayCreate(...args),
        },
      };
    }),
  };
});

vi.mock("../services/socket.service.js", () => {
  return {
    socketService: {
      toUser: vi.fn(),
      toPanditUser: vi.fn(),
      toAdmin: vi.fn(),
      emit: vi.fn(),
    },
  };
});

describe("SARV MANGAL Phase P3: Handmade Kundli Orders API", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    process.env.RAZORPAY_KEY_ID = "rzp_test_key_123";
    process.env.RAZORPAY_KEY_SECRET = "rzp_test_secret_123";
    mockFindFirstUser.mockResolvedValue({
      id: devoteeId,
      name: "Rahul Verma",
      phone: "+919876543210",
      role: "YAJMAN",
    });
  });

  describe("POST /api/v1/kundli-orders (Devotee Submission)", () => {
    it("201 – successfully creates handmade Kundli order with reference and price", async () => {
      const createdRecord = {
        id: testOrderId,
        orderNumber: "KND-20261019-2001",
        userId: devoteeId,
        devoteeName: "Rahul Verma",
        devoteePhone: "+919876543210",
        gender: "Male",
        dob: "1995-08-15",
        tob: "06:45 AM",
        pob: "Varanasi, UP",
        language: "Hindi",
        deliveryAddress: "45 Ganga Ghat Rd, Varanasi, UP 221001",
        specialNotes: "Include career and marriage prospects",
        amount: "1501.00",
        status: "REQUESTED",
        paymentStatus: "PENDING",
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };

      mockInsertKundli.mockResolvedValueOnce([createdRecord]);

      const res = await request(app)
        .post("/api/v1/kundli-orders")
        .set("Authorization", `Bearer ${yajmanToken}`)
        .send({
          devoteeName: "Rahul Verma",
          devoteePhone: "+919876543210",
          gender: "Male",
          dob: "1995-08-15",
          tob: "06:45 AM",
          pob: "Varanasi, UP",
          language: "Hindi",
          deliveryAddress: "45 Ganga Ghat Rd, Varanasi, UP 221001",
          specialNotes: "Include career and marriage prospects",
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.orderNumber).toBe("KND-20261019-2001");
      expect(res.body.data.amount).toBe("1501.00");
      expect(res.body.data.status).toBe("REQUESTED");
    });

    it("400 – rejects invalid or incomplete birth data", async () => {
      const res = await request(app)
        .post("/api/v1/kundli-orders")
        .set("Authorization", `Bearer ${yajmanToken}`)
        .send({
          devoteeName: "Rahul",
          // missing dob, tob, deliveryAddress
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it("401 – rejects unauthenticated submissions", async () => {
      const res = await request(app)
        .post("/api/v1/kundli-orders")
        .send({
          devoteeName: "Rahul Verma",
        });

      expect(res.status).toBe(401);
    });
  });

  describe("GET /api/v1/kundli-orders (Devotee List & Detail)", () => {
    it("200 – retrieves devotee orders with masked birth data in list view", async () => {
      mockCountKundli.mockResolvedValueOnce([{ count: 1 }]);
      mockFindManyKundli.mockResolvedValueOnce([
        {
          id: testOrderId,
          orderNumber: "KND-20261019-2001",
          userId: devoteeId,
          devoteeName: "Rahul Verma",
          dob: "1995-08-15",
          tob: "06:45 AM",
          status: "REQUESTED",
        },
      ]);

      const res = await request(app)
        .get("/api/v1/kundli-orders")
        .set("Authorization", `Bearer ${yajmanToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.items[0].orderNumber).toBe("KND-20261019-2001");
      // Masked for list privacy
      expect(res.body.data.items[0].dob).toBe("••••");
      expect(res.body.data.items[0].tob).toBe("••••");
    });

    it("200 – retrieves full unmasked details in single order view for owner", async () => {
      mockFindFirstKundli.mockResolvedValueOnce({
        id: testOrderId,
        orderNumber: "KND-20261019-2001",
        userId: devoteeId,
        devoteeName: "Rahul Verma",
        dob: "1995-08-15",
        tob: "06:45 AM",
        pob: "Varanasi, UP",
        status: "REQUESTED",
      });

      const res = await request(app)
        .get(`/api/v1/kundli-orders/${testOrderId}`)
        .set("Authorization", `Bearer ${yajmanToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.dob).toBe("1995-08-15");
      expect(res.body.data.tob).toBe("06:45 AM");
    });

    it("403 – forbids access to another devotee's Kundli order", async () => {
      mockFindFirstKundli.mockResolvedValueOnce({
        id: testOrderId,
        orderNumber: "KND-20261019-2001",
        userId: devoteeId,
        status: "REQUESTED",
      });

      const res = await request(app)
        .get(`/api/v1/kundli-orders/${testOrderId}`)
        .set("Authorization", `Bearer ${otherDevoteeToken}`);

      expect(res.status).toBe(403);
      expect(res.body.error.message).toContain("Access denied");
    });

    it("404 – returns 404 for nonexistent order", async () => {
      mockFindFirstKundli.mockResolvedValueOnce(null);

      const res = await request(app)
        .get("/api/v1/kundli-orders/00000000-0000-0000-0000-000000000404")
        .set("Authorization", `Bearer ${yajmanToken}`);

      expect(res.status).toBe(404);
    });
  });

  describe("PATCH /api/v1/kundli-orders/:id/cancel (Devotee Cancellation)", () => {
    it("200 – devotee can cancel REQUESTED Kundli order", async () => {
      mockFindFirstKundli.mockResolvedValueOnce({
        id: testOrderId,
        orderNumber: "KND-20261019-2001",
        userId: devoteeId,
        status: "REQUESTED",
      });

      mockUpdateKundli.mockResolvedValueOnce([
        {
          id: testOrderId,
          status: "CANCELLED",
          cancellationReason: "Mistake in details",
        },
      ]);

      const res = await request(app)
        .patch(`/api/v1/kundli-orders/${testOrderId}/cancel`)
        .set("Authorization", `Bearer ${yajmanToken}`)
        .send({ cancellationReason: "Mistake in details" });

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe("CANCELLED");
    });

    it("400 – cannot cancel once Kundli is PREPARING", async () => {
      mockFindFirstKundli.mockResolvedValueOnce({
        id: testOrderId,
        orderNumber: "KND-20261019-2001",
        userId: devoteeId,
        status: "PREPARING",
      });

      const res = await request(app)
        .patch(`/api/v1/kundli-orders/${testOrderId}/cancel`)
        .set("Authorization", `Bearer ${yajmanToken}`)
        .send({ cancellationReason: "Cancel please" });

      expect(res.status).toBe(400);
      expect(res.body.error.message).toContain("Cannot cancel Kundli order in PREPARING");
    });
  });

  describe("Admin Review & Operations", () => {
    it("403 – non-admin cannot access admin Kundli endpoints", async () => {
      const res = await request(app)
        .get("/api/v1/admin/kundli-orders")
        .set("Authorization", `Bearer ${yajmanToken}`);

      expect(res.status).toBe(403);
    });

    it("200 – admin can list all Kundli orders", async () => {
      mockCountKundli.mockResolvedValueOnce([{ count: 2 }]);
      mockFindManyKundli.mockResolvedValueOnce([
        { id: "k1", status: "REQUESTED" },
        { id: "k2", status: "ACCEPTED" },
      ]);

      const res = await request(app)
        .get("/api/v1/admin/kundli-orders")
        .set("Authorization", `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.items.length).toBe(2);
    });

    it("200 – admin decision: ACCEPT order (transitions to PAYMENT_PENDING)", async () => {
      mockFindFirstKundli.mockResolvedValueOnce({
        id: testOrderId,
        status: "REQUESTED",
      });

      mockUpdateKundli.mockResolvedValueOnce([
        {
          id: testOrderId,
          status: "PAYMENT_PENDING",
        },
      ]);

      const res = await request(app)
        .patch(`/api/v1/admin/kundli-orders/${testOrderId}/decision`)
        .set("Authorization", `Bearer ${adminToken}`)
        .send({ decision: "ACCEPT" });

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe("PAYMENT_PENDING");
    });

    it("200 – admin decision: REJECT order with reason", async () => {
      mockFindFirstKundli.mockResolvedValueOnce({
        id: testOrderId,
        status: "REQUESTED",
      });

      mockUpdateKundli.mockResolvedValueOnce([
        {
          id: testOrderId,
          status: "REJECTED",
          rejectionReason: "Incomplete address and unreachable",
        },
      ]);

      const res = await request(app)
        .patch(`/api/v1/admin/kundli-orders/${testOrderId}/decision`)
        .set("Authorization", `Bearer ${adminToken}`)
        .send({
          decision: "REJECT",
          reason: "Incomplete address and unreachable",
        });

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe("REJECTED");
    });

    it("200 – admin assigns verified Pandit/preparer", async () => {
      mockFindFirstKundli.mockResolvedValueOnce({
        id: testOrderId,
        status: "PAID",
      });

      mockFindFirstPandit.mockResolvedValueOnce({
        id: assignedPanditId,
        verificationStatus: "APPROVED",
        isVerified: true,
      });

      mockUpdateKundli.mockResolvedValueOnce([
        {
          id: testOrderId,
          assignedPanditId,
          status: "ASSIGNED",
        },
      ]);

      const res = await request(app)
        .patch(`/api/v1/admin/kundli-orders/${testOrderId}/assignment`)
        .set("Authorization", `Bearer ${adminToken}`)
        .send({ panditId: assignedPanditId });

      expect(res.status).toBe(200);
      expect(res.body.data.assignedPanditId).toBe(assignedPanditId);
      expect(res.body.data.status).toBe("ASSIGNED");
    });

    it("200 – admin updates preparation/fulfilment status to DISPATCHED with tracking", async () => {
      mockFindFirstKundli.mockResolvedValueOnce({
        id: testOrderId,
        status: "READY",
      });

      mockUpdateKundli.mockResolvedValueOnce([
        {
          id: testOrderId,
          status: "DISPATCHED",
          courierPartner: "India Post Speed Post",
          dispatchTrackingNumber: "SP123456789IN",
        },
      ]);

      const res = await request(app)
        .patch(`/api/v1/admin/kundli-orders/${testOrderId}/status`)
        .set("Authorization", `Bearer ${adminToken}`)
        .send({
          status: "DISPATCHED",
          courierPartner: "India Post Speed Post",
          dispatchTrackingNumber: "SP123456789IN",
        });

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe("DISPATCHED");
    });

    it("400 – admin rejects invalid status transition (DELIVERED -> REQUESTED)", async () => {
      mockFindFirstKundli.mockResolvedValueOnce({
        id: testOrderId,
        status: "DELIVERED",
      });

      const res = await request(app)
        .patch(`/api/v1/admin/kundli-orders/${testOrderId}/status`)
        .set("Authorization", `Bearer ${adminToken}`)
        .send({
          status: "REQUESTED",
        });

      expect(res.status).toBe(400);
      expect(res.body.error.message).toContain("Invalid status transition");
    });
  });

  describe("Razorpay Payments for Kundli Orders", () => {
    it("200 – creates Razorpay payment order when in PAYMENT_PENDING state", async () => {
      mockFindFirstKundli.mockResolvedValueOnce({
        id: testOrderId,
        userId: devoteeId,
        amount: "1501.00",
        status: "PAYMENT_PENDING",
        paymentStatus: "PENDING",
        orderNumber: "KND-12345",
        devoteeName: "Rahul Verma",
      });

      mockRazorpayCreate.mockResolvedValueOnce({
        id: "order_knd_99999",
        amount: 150100,
        currency: "INR",
        status: "created",
      });

      const res = await request(app)
        .post(`/api/v1/kundli-orders/${testOrderId}/payment/order`)
        .set("Authorization", `Bearer ${yajmanToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.orderId).toBe("order_knd_99999");
      expect(res.body.data.amount).toBe(150100);
    });

    it("400 – cannot create payment order if request is still under review", async () => {
      mockFindFirstKundli.mockResolvedValueOnce({
        id: testOrderId,
        userId: devoteeId,
        amount: "1501.00",
        status: "REQUESTED", // not yet accepted
        paymentStatus: "PENDING",
      });

      const res = await request(app)
        .post(`/api/v1/kundli-orders/${testOrderId}/payment/order`)
        .set("Authorization", `Bearer ${yajmanToken}`);

      expect(res.status).toBe(400);
      expect(res.body.error.message).toContain("Payment can only be initiated when order is in PAYMENT_PENDING state");
    });

    it("200 – verifies payment signature and marks order PAID", async () => {
      const orderId = "order_knd_99999";
      const paymentId = "pay_knd_123";
      const secret = process.env.RAZORPAY_KEY_SECRET || "rzp_test_secret_123";
      const generatedSignature = crypto
        .createHmac("sha256", secret)
        .update(`${orderId}|${paymentId}`)
        .digest("hex");

      mockFindFirstKundli.mockResolvedValueOnce({
        id: testOrderId,
        userId: devoteeId,
        razorpayOrderId: orderId,
        status: "PAYMENT_PENDING",
        paymentStatus: "PENDING",
      });

      mockUpdateKundli.mockResolvedValueOnce([
        {
          id: testOrderId,
          paymentStatus: "PAID",
          status: "PAID",
          razorpayPaymentId: paymentId,
        },
      ]);

      const res = await request(app)
        .post(`/api/v1/kundli-orders/${testOrderId}/payment/verify`)
        .set("Authorization", `Bearer ${yajmanToken}`)
        .send({
          razorpayOrderId: orderId,
          razorpayPaymentId: paymentId,
          razorpaySignature: generatedSignature,
        });

      expect(res.status).toBe(200);
      expect(res.body.data.paymentStatus).toBe("PAID");
      expect(res.body.data.status).toBe("PAID");
    });
  });
});
