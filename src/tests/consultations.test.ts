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

const verifiedPanditId = "33333333-3333-3333-3333-333333333333";
const unverifiedPanditId = "44444444-4444-4444-4444-444444444444";

const testConsultationId = "11111111-1111-1111-1111-111111111111";

/* ------------------------------------------------------------------ *
 *  Mock DB, Redis, and Razorpay                                       *
 * ------------------------------------------------------------------ */
const {
  mockFindFirstUser,
  mockFindFirstConsultation,
  mockFindManyConsultations,
  mockCountConsultations,
  mockInsertConsultation,
  mockUpdateConsultation,
  mockFindFirstPandit,
  mockRazorpayCreate,
} = vi.hoisted(() => {
  return {
    mockFindFirstUser: vi.fn(),
    mockFindFirstConsultation: vi.fn(),
    mockFindManyConsultations: vi.fn(),
    mockCountConsultations: vi.fn(),
    mockInsertConsultation: vi.fn(),
    mockUpdateConsultation: vi.fn(),
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
        consultations: {
          findFirst: (...args: any[]) => mockFindFirstConsultation(...args),
          findMany: (...args: any[]) => mockFindManyConsultations(...args),
        },
        pandits: {
          findFirst: (...args: any[]) => mockFindFirstPandit(...args),
        },
      },
      select: () => ({
        from: () => ({
          where: () => mockCountConsultations(),
        }),
      }),
      insert: () => ({
        values: (data: any) => ({
          returning: () => mockInsertConsultation(data),
        }),
      }),
      update: () => ({
        set: (data: any) => ({
          where: () => ({
            returning: () => mockUpdateConsultation(data),
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

describe("SARV MANGAL Phase P3: Vedic Consultation API", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    process.env.RAZORPAY_KEY_ID = "rzp_test_key_123";
    process.env.RAZORPAY_KEY_SECRET = "rzp_test_secret_123";
    mockFindFirstUser.mockResolvedValue({
      id: devoteeId,
      name: "Aditya Sharma",
      phone: "+919876543210",
      role: "YAJMAN",
    });
  });

  describe("POST /api/v1/consultations (Devotee Booking)", () => {
    it("201 – successfully creates online consultation request with correct fee and reference", async () => {
      const createdRecord = {
        id: testConsultationId,
        consultationNumber: "CNS-20261019-1001",
        userId: devoteeId,
        devoteeName: "Aditya Sharma",
        devoteePhone: "+919876543210",
        type: "ONLINE",
        timing: "SCHEDULED",
        medium: "VIDEO",
        topic: "Career transition guidance",
        notes: "Detailed queries",
        requestedDate: "2026-10-25T10:00:00.000Z",
        requestedTimeSlot: "10:00 AM - 10:30 AM",
        durationMinutes: 30,
        amount: "349.00",
        status: "REQUESTED",
        paymentStatus: "PENDING",
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };

      mockInsertConsultation.mockResolvedValueOnce([createdRecord]);

      const res = await request(app)
        .post("/api/v1/consultations")
        .set("Authorization", `Bearer ${yajmanToken}`)
        .send({
          devoteeName: "Aditya Sharma",
          devoteePhone: "+919876543210",
          type: "ONLINE",
          timing: "SCHEDULED",
          medium: "VIDEO",
          topic: "Career transition guidance",
          notes: "Detailed queries",
          requestedDate: "2026-10-25T10:00:00.000Z",
          requestedTimeSlot: "10:00 AM - 10:30 AM",
          durationMinutes: 30,
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.consultationNumber).toBe("CNS-20261019-1001");
      expect(res.body.data.amount).toBe("349.00");
      expect(res.body.data.status).toBe("REQUESTED");
    });

    it("201 – correctly computes offline consultation fee (60 mins = ₹899)", async () => {
      const createdRecord = {
        id: testConsultationId,
        consultationNumber: "CNS-20261019-1002",
        userId: devoteeId,
        devoteeName: "Aditya Sharma",
        devoteePhone: "+919876543210",
        type: "OFFLINE",
        timing: "SCHEDULED",
        medium: "IN_PERSON",
        topic: "Health and wellness guidance",
        requestedDate: "2026-10-26T16:00:00.000Z",
        requestedTimeSlot: "04:00 PM - 05:00 PM",
        durationMinutes: 60,
        amount: "899.00",
        status: "REQUESTED",
        paymentStatus: "PENDING",
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };

      mockInsertConsultation.mockResolvedValueOnce([createdRecord]);

      const res = await request(app)
        .post("/api/v1/consultations")
        .set("Authorization", `Bearer ${yajmanToken}`)
        .send({
          devoteeName: "Aditya Sharma",
          devoteePhone: "+919876543210",
          type: "OFFLINE",
          timing: "SCHEDULED",
          medium: "IN_PERSON",
          topic: "Health and wellness guidance",
          requestedDate: "2026-10-26T16:00:00.000Z",
          requestedTimeSlot: "04:00 PM - 05:00 PM",
          durationMinutes: 60,
        });

      expect(res.status).toBe(201);
      expect(res.body.data.amount).toBe("899.00");
    });

    it("400 – rejects invalid duration or missing required fields", async () => {
      const res = await request(app)
        .post("/api/v1/consultations")
        .set("Authorization", `Bearer ${yajmanToken}`)
        .send({
          devoteeName: "",
          type: "ONLINE",
          durationMinutes: 45, // invalid duration
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it("401 – rejects request when unauthenticated", async () => {
      const res = await request(app)
        .post("/api/v1/consultations")
        .send({
          devoteeName: "Aditya",
          type: "ONLINE",
          durationMinutes: 15,
        });

      expect(res.status).toBe(401);
    });
  });

  describe("GET /api/v1/consultations (Devotee List & Detail)", () => {
    it("200 – retrieves devotee's own consultations", async () => {
      mockCountConsultations.mockResolvedValueOnce([{ count: 1 }]);
      mockFindManyConsultations.mockResolvedValueOnce([
        {
          id: testConsultationId,
          consultationNumber: "CNS-20261019-1001",
          userId: devoteeId,
          status: "REQUESTED",
        },
      ]);

      const res = await request(app)
        .get("/api/v1/consultations")
        .set("Authorization", `Bearer ${yajmanToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.items.length).toBe(1);
      expect(res.body.data.pagination.total).toBe(1);
    });

    it("200 – retrieves single consultation detail for owner", async () => {
      mockFindFirstConsultation.mockResolvedValueOnce({
        id: testConsultationId,
        consultationNumber: "CNS-20261019-1001",
        userId: devoteeId,
        status: "REQUESTED",
      });

      const res = await request(app)
        .get(`/api/v1/consultations/${testConsultationId}`)
        .set("Authorization", `Bearer ${yajmanToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.id).toBe(testConsultationId);
    });

    it("403 – forbids access to another devotee's consultation", async () => {
      mockFindFirstConsultation.mockResolvedValueOnce({
        id: testConsultationId,
        consultationNumber: "CNS-20261019-1001",
        userId: devoteeId, // owned by devoteeId
        status: "REQUESTED",
      });

      const res = await request(app)
        .get(`/api/v1/consultations/${testConsultationId}`)
        .set("Authorization", `Bearer ${otherDevoteeToken}`);

      expect(res.status).toBe(403);
      expect(res.body.error.message).toContain("Access denied");
    });

    it("404 – returns 404 for nonexistent consultation", async () => {
      mockFindFirstConsultation.mockResolvedValueOnce(null);

      const res = await request(app)
        .get("/api/v1/consultations/00000000-0000-0000-0000-000000000404")
        .set("Authorization", `Bearer ${yajmanToken}`);

      expect(res.status).toBe(404);
    });
  });

  describe("PATCH /api/v1/consultations/:id/cancel (Devotee Cancellation)", () => {
    it("200 – devotee can cancel REQUESTED consultation", async () => {
      mockFindFirstConsultation.mockResolvedValueOnce({
        id: testConsultationId,
        consultationNumber: "CNS-20261019-1001",
        userId: devoteeId,
        status: "REQUESTED",
      });

      mockUpdateConsultation.mockResolvedValueOnce([
        {
          id: testConsultationId,
          status: "CANCELLED",
          cancellationReason: "Change of plans",
        },
      ]);

      const res = await request(app)
        .patch(`/api/v1/consultations/${testConsultationId}/cancel`)
        .set("Authorization", `Bearer ${yajmanToken}`)
        .send({ cancellationReason: "Change of plans" });

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe("CANCELLED");
    });

    it("400 – cannot cancel COMPLETED consultation", async () => {
      mockFindFirstConsultation.mockResolvedValueOnce({
        id: testConsultationId,
        consultationNumber: "CNS-20261019-1001",
        userId: devoteeId,
        status: "COMPLETED",
      });

      const res = await request(app)
        .patch(`/api/v1/consultations/${testConsultationId}/cancel`)
        .set("Authorization", `Bearer ${yajmanToken}`)
        .send({ cancellationReason: "Change of plans" });

      expect(res.status).toBe(400);
      expect(res.body.error.message).toContain("Cannot cancel consultation");
    });
  });

  describe("Admin Review & Operations", () => {
    it("403 – non-admin cannot access admin consultation endpoints", async () => {
      const res = await request(app)
        .get("/api/v1/admin/consultations")
        .set("Authorization", `Bearer ${yajmanToken}`);

      expect(res.status).toBe(403);
    });

    it("200 – admin can list all consultations with status filter", async () => {
      mockCountConsultations.mockResolvedValueOnce([{ count: 2 }]);
      mockFindManyConsultations.mockResolvedValueOnce([
        { id: "c1", status: "REQUESTED" },
        { id: "c2", status: "UNDER_REVIEW" },
      ]);

      const res = await request(app)
        .get("/api/v1/admin/consultations?status=REQUESTED")
        .set("Authorization", `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.items.length).toBe(2);
    });

    it("200 – admin can schedule consultation", async () => {
      mockFindFirstConsultation.mockResolvedValueOnce({
        id: testConsultationId,
        status: "REQUESTED",
      });

      mockUpdateConsultation.mockResolvedValueOnce([
        {
          id: testConsultationId,
          status: "SCHEDULED",
          scheduledDateTime: "2026-10-25T10:00:00.000Z",
          notes: "Scheduled by admin",
        },
      ]);

      const res = await request(app)
        .patch(`/api/v1/admin/consultations/${testConsultationId}/schedule`)
        .set("Authorization", `Bearer ${adminToken}`)
        .send({
          scheduledDateTime: "2026-10-25T10:00:00.000Z",
          notes: "Scheduled by admin",
        });

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe("SCHEDULED");
    });

    it("200 – admin assigns verified pandit successfully", async () => {
      mockFindFirstConsultation.mockResolvedValueOnce({
        id: testConsultationId,
        status: "SCHEDULED",
      });

      mockFindFirstPandit.mockResolvedValueOnce({
        id: verifiedPanditId,
        verificationStatus: "APPROVED",
        isVerified: true,
      });

      mockUpdateConsultation.mockResolvedValueOnce([
        {
          id: testConsultationId,
          assignedPanditId: verifiedPanditId,
          status: "SCHEDULED",
        },
      ]);

      const res = await request(app)
        .patch(`/api/v1/admin/consultations/${testConsultationId}/assignment`)
        .set("Authorization", `Bearer ${adminToken}`)
        .send({
          panditId: verifiedPanditId,
        });

      expect(res.status).toBe(200);
      expect(res.body.data.assignedPanditId).toBe(verifiedPanditId);
    });

    it("400 – admin assignment rejected if pandit is not verified", async () => {
      mockFindFirstConsultation.mockResolvedValueOnce({
        id: testConsultationId,
        status: "SCHEDULED",
      });

      mockFindFirstPandit.mockResolvedValueOnce({
        id: unverifiedPanditId,
        verificationStatus: "PENDING",
        isVerified: false,
      });

      const res = await request(app)
        .patch(`/api/v1/admin/consultations/${testConsultationId}/assignment`)
        .set("Authorization", `Bearer ${adminToken}`)
        .send({
          panditId: unverifiedPanditId,
        });

      expect(res.status).toBe(400);
      expect(res.body.error.message).toContain("Only verified and approved Acharyas");
    });

    it("200 – admin updates status through valid transitions (IN_PROGRESS -> COMPLETED)", async () => {
      mockFindFirstConsultation.mockResolvedValueOnce({
        id: testConsultationId,
        status: "IN_PROGRESS",
      });

      mockUpdateConsultation.mockResolvedValueOnce([
        {
          id: testConsultationId,
          status: "COMPLETED",
        },
      ]);

      const res = await request(app)
        .patch(`/api/v1/admin/consultations/${testConsultationId}/status`)
        .set("Authorization", `Bearer ${adminToken}`)
        .send({
          status: "COMPLETED",
        });

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe("COMPLETED");
    });

    it("400 – admin rejects invalid status transition (COMPLETED -> REQUESTED)", async () => {
      mockFindFirstConsultation.mockResolvedValueOnce({
        id: testConsultationId,
        status: "COMPLETED",
      });

      const res = await request(app)
        .patch(`/api/v1/admin/consultations/${testConsultationId}/status`)
        .set("Authorization", `Bearer ${adminToken}`)
        .send({
          status: "REQUESTED",
        });

      expect(res.status).toBe(400);
      expect(res.body.error.message).toContain("Invalid status transition");
    });
  });

  describe("Razorpay Payments for Consultations", () => {
    it("200 – creates Razorpay payment order for consultation fee", async () => {
      mockFindFirstConsultation.mockResolvedValueOnce({
        id: testConsultationId,
        userId: devoteeId,
        amount: "349.00",
        paymentStatus: "PENDING",
        topic: "Career guidance",
        consultationNumber: "CNS-12345",
      });

      mockRazorpayCreate.mockResolvedValueOnce({
        id: "order_cns_12345",
        amount: 34900,
        currency: "INR",
        status: "created",
      });

      const res = await request(app)
        .post(`/api/v1/consultations/${testConsultationId}/payment/order`)
        .set("Authorization", `Bearer ${yajmanToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.orderId).toBe("order_cns_12345");
      expect(res.body.data.amount).toBe(34900);
    });

    it("200 – verifies payment signature and marks consultation CONFIRMED", async () => {
      const orderId = "order_cns_12345";
      const paymentId = "pay_test_999";
      const secret = process.env.RAZORPAY_KEY_SECRET || "rzp_test_secret_123";
      const generatedSignature = crypto
        .createHmac("sha256", secret)
        .update(`${orderId}|${paymentId}`)
        .digest("hex");

      mockFindFirstConsultation.mockResolvedValueOnce({
        id: testConsultationId,
        userId: devoteeId,
        razorpayOrderId: orderId,
        status: "SCHEDULED",
        paymentStatus: "PENDING",
      });

      mockUpdateConsultation.mockResolvedValueOnce([
        {
          id: testConsultationId,
          paymentStatus: "PAID",
          status: "CONFIRMED",
          razorpayPaymentId: paymentId,
        },
      ]);

      const res = await request(app)
        .post(`/api/v1/consultations/${testConsultationId}/payment/verify`)
        .set("Authorization", `Bearer ${yajmanToken}`)
        .send({
          razorpayOrderId: orderId,
          razorpayPaymentId: paymentId,
          razorpaySignature: generatedSignature,
        });

      expect(res.status).toBe(200);
      expect(res.body.data.paymentStatus).toBe("PAID");
      expect(res.body.data.status).toBe("CONFIRMED");
    });

    it("400 – rejects invalid Razorpay signature", async () => {
      mockFindFirstConsultation.mockResolvedValueOnce({
        id: testConsultationId,
        userId: devoteeId,
        razorpayOrderId: "order_cns_12345",
      });

      const res = await request(app)
        .post(`/api/v1/consultations/${testConsultationId}/payment/verify`)
        .set("Authorization", `Bearer ${yajmanToken}`)
        .send({
          razorpayOrderId: "order_cns_12345",
          razorpayPaymentId: "pay_test_999",
          razorpaySignature: "invalid_tampered_signature",
        });

      expect(res.status).toBe(400);
      expect(res.body.error.message).toContain("Invalid payment signature");
    });
  });
});
