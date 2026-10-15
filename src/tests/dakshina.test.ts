import { describe, it, expect, vi, beforeEach } from "vitest";
import request from "supertest";
import app from "../app.js";
import { yajmanToken, signTestToken } from "./helpers/setup.js";
import crypto from "crypto";

const yajmanId = "00000000-0000-0000-0000-000000000001";
const panditId = "33333333-3333-3333-3333-333333333333";
const otherPanditId = "44444444-4444-4444-4444-444444444444";

const panditToken = signTestToken({
  id: panditId,
  phone: "+919876543210",
  role: "PANDIT",
});

const otherPanditToken = signTestToken({
  id: otherPanditId,
  phone: "+919876543211",
  role: "PANDIT",
});


/* ------------------------------------------------------------------ *
 *  Mock DB, Redis, Razorpay, Socket.IO, Notifications
 * ------------------------------------------------------------------ */
const {
  mockFindFirstBooking,
  mockFindFirstPandit,
  mockFindFirstDakshina,
  mockFindManyDakshina,
  mockInsert,
  mockUpdate,
  mockRazorpayCreate,
} = vi.hoisted(() => {
  return {
    mockFindFirstBooking: vi.fn(),
    mockFindFirstPandit: vi.fn(),
    mockFindFirstDakshina: vi.fn(),
    mockFindManyDakshina: vi.fn(),
    mockInsert: vi.fn(),
    mockUpdate: vi.fn(),
    mockRazorpayCreate: vi.fn(),
  };
});

vi.mock("../db/index.js", () => ({
  db: {
    query: {
      bookings: {
        findFirst: (...args: any[]) => mockFindFirstBooking(...args),
      },
      pandits: {
        findFirst: (...args: any[]) => mockFindFirstPandit(...args),
      },
      dakshinaCollections: {
        findFirst: (...args: any[]) => mockFindFirstDakshina(...args),
        findMany: (...args: any[]) => mockFindManyDakshina(...args),
      },
    },
    insert: (...args: any[]) => mockInsert(...args),
    update: (...args: any[]) => mockUpdate(...args),
  },
  dakshinaCollections: {
    id: "id",
    bookingId: "booking_id",
    panditId: "pandit_id",
    paymentMethod: "payment_method",
    paymentStatus: "payment_status",
    razorpayOrderId: "razorpay_order_id",
  },
  bookings: {
    id: "id",
    status: "status",
    panditId: "pandit_id",
  },
}));

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

vi.mock("../services/realtime.service.js", () => ({
  getIO: vi.fn().mockReturnValue({
    to: vi.fn().mockReturnValue({
      emit: vi.fn(),
    }),
  }),
}));

vi.mock("../services/notification.service.js", () => ({
  sendPush: vi.fn().mockResolvedValue({ success: true }),
}));

/* ------------------------------------------------------------------ *
 *  Test Suites
 * ------------------------------------------------------------------ */

describe("SARV MANGAL Phase P2-B Task 6: Dakshina Collection & Booking Closure", () => {
  const validBookingId = "77777777-7777-7777-7777-777777777777";
  const mockPoojaBooking = {
    id: validBookingId,
    yajmanId,
    panditId,
    status: "PUJA_STARTED",
    totalAmount: "2500.00",
    pooja: { id: "p1", title: "Satyanarayan Katha" },
  };

  const approvedPandit = {
    id: "pandit_prof_1",
    userId: panditId,
    verificationStatus: "APPROVED",
    isVerified: true,
  };

  beforeEach(() => {
    vi.clearAllMocks();
    vi.stubEnv("RAZORPAY_KEY_ID", "rzp_test_key_123");
    vi.stubEnv("RAZORPAY_KEY_SECRET", "rzp_test_secret_456");
  });

  describe("POST /api/v1/bookings/:id/dakshina/cash (Cash Dakshina)", () => {
    it("200 – successfully collects cash Dakshina and completes booking", async () => {
      mockFindFirstBooking.mockResolvedValue(mockPoojaBooking);
      mockFindFirstPandit.mockResolvedValue(approvedPandit);
      mockFindFirstDakshina.mockResolvedValue(null); // Not already paid

      const createdCollection = {
        id: "dakshina-uuid-1",
        bookingId: validBookingId,
        panditId,
        amount: "2500.00",
        currency: "INR",
        paymentMethod: "CASH",
        paymentStatus: "PAID",
        collectedAt: new Date(),
      };

      mockInsert.mockReturnValue({
        values: vi.fn().mockReturnValue({
          returning: vi.fn().mockResolvedValue([createdCollection]),
        }),
      });

      mockUpdate.mockReturnValue({
        set: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            returning: vi.fn().mockResolvedValue([{ ...mockPoojaBooking, status: "COMPLETED" }]),
          }),
        }),
      });

      const res = await request(app)
        .post(`/api/v1/bookings/${validBookingId}/dakshina/cash`)
        .set("Authorization", `Bearer ${panditToken}`)
        .send({ completeBooking: true });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.dakshina.paymentMethod).toBe("CASH");
      expect(res.body.data.dakshina.paymentStatus).toBe("PAID");
      expect(res.body.data.booking.status).toBe("COMPLETED");
      expect(res.body.data.alreadyPaid).toBe(false);
    });

    it("200 – supports custom positive amount within bounds", async () => {
      mockFindFirstBooking.mockResolvedValue(mockPoojaBooking);
      mockFindFirstPandit.mockResolvedValue(approvedPandit);
      mockFindFirstDakshina.mockResolvedValue(null);

      const createdCollection = {
        id: "dakshina-uuid-2",
        bookingId: validBookingId,
        panditId,
        amount: "3000.00",
        currency: "INR",
        paymentMethod: "CASH",
        paymentStatus: "PAID",
        collectedAt: new Date(),
      };

      mockInsert.mockReturnValue({
        values: vi.fn().mockReturnValue({
          returning: vi.fn().mockResolvedValue([createdCollection]),
        }),
      });

      const res = await request(app)
        .post(`/api/v1/bookings/${validBookingId}/dakshina/cash`)
        .set("Authorization", `Bearer ${panditToken}`)
        .send({ amount: 3000, notes: "Devotee offered extra prasad dakshina", completeBooking: false });

      expect(res.status).toBe(200);
      expect(res.body.data.dakshina.amount).toBe("3000.00");
    });

    it("200 – idempotency returns existing record if already paid", async () => {
      mockFindFirstBooking.mockResolvedValue(mockPoojaBooking);
      mockFindFirstPandit.mockResolvedValue(approvedPandit);
      mockFindFirstDakshina.mockResolvedValue({
        id: "dakshina-existing",
        bookingId: validBookingId,
        paymentStatus: "PAID",
        paymentMethod: "CASH",
        amount: "2500.00",
      });

      const res = await request(app)
        .post(`/api/v1/bookings/${validBookingId}/dakshina/cash`)
        .set("Authorization", `Bearer ${panditToken}`)
        .send({ completeBooking: true });

      expect(res.status).toBe(200);
      expect(res.body.data.alreadyPaid).toBe(true);
      expect(res.body.data.dakshina.id).toBe("dakshina-existing");
      expect(mockInsert).not.toHaveBeenCalled();
    });

    it("400 – rejects zero or negative amount", async () => {
      const res = await request(app)
        .post(`/api/v1/bookings/${validBookingId}/dakshina/cash`)
        .set("Authorization", `Bearer ${panditToken}`)
        .send({ amount: -500 });

      expect(res.status).toBe(400);
    });

    it("400 – rejects cash collection before puja has started", async () => {
      mockFindFirstBooking.mockResolvedValue({ ...mockPoojaBooking, status: "CONFIRMED" });
      mockFindFirstPandit.mockResolvedValue(approvedPandit);

      const res = await request(app)
        .post(`/api/v1/bookings/${validBookingId}/dakshina/cash`)
        .set("Authorization", `Bearer ${panditToken}`)
        .send({});

      expect(res.status).toBe(400);
      expect(res.body.error.message).toContain("Dakshina can only be collected during or after puja execution");
    });

    it("403 – rejects Yajman attempting cash collection", async () => {
      const res = await request(app)
        .post(`/api/v1/bookings/${validBookingId}/dakshina/cash`)
        .set("Authorization", `Bearer ${yajmanToken}`)
        .send({});

      expect(res.status).toBe(403);
    });

    it("403 – rejects unapproved pandit", async () => {
      mockFindFirstBooking.mockResolvedValue(mockPoojaBooking);
      mockFindFirstPandit.mockResolvedValue({
        ...approvedPandit,
        verificationStatus: "PENDING",
        isVerified: false,
      });

      const res = await request(app)
        .post(`/api/v1/bookings/${validBookingId}/dakshina/cash`)
        .set("Authorization", `Bearer ${panditToken}`)
        .send({});

      expect(res.status).toBe(403);
      expect(res.body.error.message).toContain("approved");
    });

    it("403 – rejects competing pandit attempting collection on another pandit's booking", async () => {
      mockFindFirstBooking.mockResolvedValue(mockPoojaBooking);
      mockFindFirstPandit.mockResolvedValue({
        id: "pandit_prof_2",
        userId: otherPanditId,
        verificationStatus: "APPROVED",
        isVerified: true,
      });

      const res = await request(app)
        .post(`/api/v1/bookings/${validBookingId}/dakshina/cash`)
        .set("Authorization", `Bearer ${otherPanditToken}`)
        .send({});

      expect(res.status).toBe(403);
      expect(res.body.error.message).toContain("Only the assigned Pandit");
    });
  });

  describe("POST /api/v1/bookings/:id/dakshina/create-order (Online Dakshina Order)", () => {
    it("200 – creates Razorpay order with server-controlled amount", async () => {
      mockFindFirstBooking.mockResolvedValue(mockPoojaBooking);
      mockFindFirstPandit.mockResolvedValue(approvedPandit);
      mockFindFirstDakshina
        .mockResolvedValueOnce(null) // Not paid
        .mockResolvedValueOnce(null); // No pending order

      mockRazorpayCreate.mockResolvedValue({ id: "order_dakshina_123" });
      mockInsert.mockReturnValue({
        values: vi.fn().mockReturnValue({
          returning: vi.fn().mockResolvedValue([{
            id: "dakshina-online-1",
            bookingId: validBookingId,
            panditId,
            amount: "2500.00",
            paymentMethod: "ONLINE",
            paymentStatus: "PENDING",
            razorpayOrderId: "order_dakshina_123",
          }]),
        }),
      });

      const res = await request(app)
        .post(`/api/v1/bookings/${validBookingId}/dakshina/create-order`)
        .set("Authorization", `Bearer ${panditToken}`)
        .send({});

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.order.id).toBe("order_dakshina_123");
      // 2500.00 * 100 = 250000 paise
      expect(mockRazorpayCreate).toHaveBeenCalledWith(expect.objectContaining({
        amount: 250000,
        currency: "INR",
      }));
    });

    it("200 – idempotency returns existing pending order", async () => {
      mockFindFirstBooking.mockResolvedValue(mockPoojaBooking);
      mockFindFirstPandit.mockResolvedValue(approvedPandit);
      mockFindFirstDakshina
        .mockResolvedValueOnce(null) // Not paid
        .mockResolvedValueOnce({
          id: "dakshina-online-pending",
          bookingId: validBookingId,
          amount: "2500.00",
          paymentMethod: "ONLINE",
          paymentStatus: "PENDING",
          razorpayOrderId: "order_existing_456",
        });

      const res = await request(app)
        .post(`/api/v1/bookings/${validBookingId}/dakshina/create-order`)
        .set("Authorization", `Bearer ${panditToken}`)
        .send({});

      expect(res.status).toBe(200);
      expect(res.body.data.order.id).toBe("order_existing_456");
      expect(mockRazorpayCreate).not.toHaveBeenCalled();
    });

    it("400 – rejects creating order if Dakshina is already paid", async () => {
      mockFindFirstBooking.mockResolvedValue(mockPoojaBooking);
      mockFindFirstPandit.mockResolvedValue(approvedPandit);
      mockFindFirstDakshina.mockResolvedValue({
        id: "dakshina-paid",
        paymentStatus: "PAID",
      });

      const res = await request(app)
        .post(`/api/v1/bookings/${validBookingId}/dakshina/create-order`)
        .set("Authorization", `Bearer ${panditToken}`)
        .send({});

      expect(res.status).toBe(400);
      expect(res.body.error.message).toContain("Dakshina for this booking has already been collected");
    });
  });

  describe("POST /api/v1/bookings/:id/dakshina/verify (Online Signature Verification)", () => {
    it("200 – verifies HMAC signature and confirms online payment", async () => {
      const orderId = "order_dakshina_verify_1";
      const paymentId = "pay_dakshina_test_1";
      const secret = "rzp_test_secret_456";

      const validSignature = crypto
        .createHmac("sha256", secret)
        .update(`${orderId}|${paymentId}`)
        .digest("hex");

      mockFindFirstDakshina.mockResolvedValue({
        id: "dakshina-rec-1",
        bookingId: validBookingId,
        amount: "2500.00",
        paymentStatus: "PENDING",
        razorpayOrderId: orderId,
      });

      mockFindFirstBooking.mockResolvedValue(mockPoojaBooking);
      mockUpdate.mockReturnValue({
        set: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            returning: vi.fn().mockResolvedValue([{
              id: "dakshina-rec-1",
              bookingId: validBookingId,
              amount: "2500.00",
              paymentStatus: "PAID",
              razorpayOrderId: orderId,
              razorpayPaymentId: paymentId,
            }]),
          }),
        }),
      });

      const res = await request(app)
        .post(`/api/v1/bookings/${validBookingId}/dakshina/verify`)
        .set("Authorization", `Bearer ${panditToken}`)
        .send({
          orderId,
          paymentId,
          signature: validSignature,
          completeBooking: true,
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.dakshina.paymentStatus).toBe("PAID");
    });

    it("400 – rejects invalid cryptographic signature", async () => {
      const res = await request(app)
        .post(`/api/v1/bookings/${validBookingId}/dakshina/verify`)
        .set("Authorization", `Bearer ${panditToken}`)
        .send({
          orderId: "order_1",
          paymentId: "pay_1",
          signature: "fraudulent_signature_hex",
        });

      expect(res.status).toBe(400);
      expect(res.body.error.message).toContain("Invalid payment signature");
    });
  });

  describe("GET /api/v1/bookings/:id/dakshina (Audit & Status Recovery)", () => {
    it("200 – returns Dakshina status for assigned Pandit", async () => {
      mockFindFirstBooking.mockResolvedValue(mockPoojaBooking);
      mockFindManyDakshina.mockResolvedValue([{
        id: "dakshina-1",
        bookingId: validBookingId,
        amount: "2500.00",
        paymentMethod: "CASH",
        paymentStatus: "PAID",
      }]);

      const res = await request(app)
        .get(`/api/v1/bookings/${validBookingId}/dakshina`)
        .set("Authorization", `Bearer ${panditToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.isPaid).toBe(true);
      expect(res.body.data.collection.paymentStatus).toBe("PAID");
    });

    it("200 – returns Dakshina status for Yajman", async () => {
      mockFindFirstBooking.mockResolvedValue(mockPoojaBooking);
      mockFindManyDakshina.mockResolvedValue([{
        id: "dakshina-1",
        bookingId: validBookingId,
        amount: "2500.00",
        paymentMethod: "CASH",
        paymentStatus: "PAID",
      }]);

      const res = await request(app)
        .get(`/api/v1/bookings/${validBookingId}/dakshina`)
        .set("Authorization", `Bearer ${yajmanToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.isPaid).toBe(true);
    });

    it("403 – rejects unauthorized unrelated Pandit", async () => {
      mockFindFirstBooking.mockResolvedValue(mockPoojaBooking);

      const res = await request(app)
        .get(`/api/v1/bookings/${validBookingId}/dakshina`)
        .set("Authorization", `Bearer ${otherPanditToken}`);

      expect(res.status).toBe(403);
    });
  });
});
