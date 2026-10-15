import { describe, it, expect, vi, beforeEach } from "vitest";
import request from "supertest";
import app from "../app.js";
import { signTestToken, yajmanToken } from "./helpers/setup.js";

/* ------------------------------------------------------------------ *
 *  Mock DB and Redis
 * ------------------------------------------------------------------ */
const {
  mockFindMany,
  mockFindFirst,
  mockBookingFindFirst,
  mockDeclineFindFirst,
  mockDeclineFindMany,
  mockUpdate,
  mockInsert,
  mockGeoAdd,
  mockZRem,
} = vi.hoisted(() => {
  return {
    mockFindMany: vi.fn(),
    mockFindFirst: vi.fn(),
    mockBookingFindFirst: vi.fn(),
    mockDeclineFindFirst: vi.fn(),
    mockDeclineFindMany: vi.fn(),
    mockUpdate: vi.fn(),
    mockInsert: vi.fn(),
    mockGeoAdd: vi.fn(),
    mockZRem: vi.fn(),
  };
});

vi.mock("../db/index.js", () => ({
  db: {
    query: {
      pandits: {
        findMany: (...args: any[]) => mockFindMany(...args),
        findFirst: (...args: any[]) => mockFindFirst(...args),
      },
      bookings: {
        findMany: (...args: any[]) => mockFindMany(...args),
        findFirst: (...args: any[]) => mockBookingFindFirst(...args),
      },
      bookingDeclines: {
        findMany: (...args: any[]) => mockDeclineFindMany(...args),
        findFirst: (...args: any[]) => mockDeclineFindFirst(...args),
      },
    },
    update: (...args: any[]) => mockUpdate(...args),
    insert: (...args: any[]) => mockInsert(...args),
  },
}));

vi.mock("../config/redis.js", () => ({
  getRedis: vi.fn().mockResolvedValue({
    geoadd: (...args: any[]) => mockGeoAdd(...args),
    zrem: (...args: any[]) => mockZRem(...args),
  }),
}));

/* ------------------------------------------------------------------ *
 *  Test Suites
 * ------------------------------------------------------------------ */

describe("GET /api/v1/pandits/nearby", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("200 – returns nearby pandits with default radius", async () => {
    const mockPanditsList = [
      { id: "p1", isAvailable: true, isVerified: true, user: { name: "Pandit 1" } }
    ];
    mockFindMany.mockResolvedValue(mockPanditsList);

    const res = await request(app)
      .get("/api/v1/pandits/nearby?lat=28.7041&lng=77.1025")
      .set("Authorization", `Bearer ${yajmanToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.pandits).toHaveLength(1);
    expect(mockFindMany).toHaveBeenCalled();
  });

  it("400 – rejects invalid coordinates", async () => {
    const res = await request(app)
      .get("/api/v1/pandits/nearby?lat=95&lng=77.1025") // lat > 90
      .set("Authorization", `Bearer ${yajmanToken}`);

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("VALIDATION_ERROR");
  });
});

describe("PATCH /api/v1/pandits/duty-status", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  const panditUserId = "33333333-3333-3333-3333-333333333333";
  const panditToken = signTestToken({
    id: panditUserId,
    phone: "+919876543210",
    role: "PANDIT",
  });

  it("200 – updates duty status to available and syncs with Redis GEO", async () => {
    const dbPandit = { id: "pandit1", userId: panditUserId, latitude: 28.7041, longitude: 77.1025, verificationStatus: "APPROVED", isVerified: true };
    mockFindFirst.mockResolvedValue(dbPandit);
    
    mockUpdate.mockReturnValue({
      set: vi.fn().mockReturnValue({
        where: vi.fn().mockReturnValue({
          returning: vi.fn().mockResolvedValue([{ ...dbPandit, isAvailable: true }])
        })
      })
    });

    const res = await request(app)
      .patch("/api/v1/pandits/duty-status")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ isAvailable: true });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(mockGeoAdd).toHaveBeenCalledWith("pandits:live", 77.1025, 28.7041, "pandit1");
  });

  it("200 – updates duty status to offline and removes from Redis GEO", async () => {
    const dbPandit = { id: "pandit1", userId: panditUserId, latitude: 28.7041, longitude: 77.1025, verificationStatus: "APPROVED", isVerified: true };
    mockFindFirst.mockResolvedValue(dbPandit);
    
    mockUpdate.mockReturnValue({
      set: vi.fn().mockReturnValue({
        where: vi.fn().mockReturnValue({
          returning: vi.fn().mockResolvedValue([{ ...dbPandit, isAvailable: false }])
        })
      })
    });

    const res = await request(app)
      .patch("/api/v1/pandits/duty-status")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ isAvailable: false });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(mockZRem).toHaveBeenCalledWith("pandits:live", "pandit1");
  });

  it("400 – rejects going available if location is missing", async () => {
    // Missing lat/lng
    const dbPandit = { id: "pandit1", userId: panditUserId, verificationStatus: "APPROVED", isVerified: true };
    mockFindFirst.mockResolvedValue(dbPandit);

    const res = await request(app)
      .patch("/api/v1/pandits/duty-status")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ isAvailable: true });

    expect(res.status).toBe(400);
    expect(res.body.error.message).toContain("location");
    expect(mockGeoAdd).not.toHaveBeenCalled();
  });

  it("200 – accepts valid coordinates, updates DB location, and syncs Redis GEO", async () => {
    const dbPandit = { id: "pandit1", userId: panditUserId, verificationStatus: "APPROVED", isVerified: true };
    mockFindFirst.mockResolvedValue(dbPandit);

    mockUpdate.mockReturnValue({
      set: vi.fn().mockReturnValue({
        where: vi.fn().mockReturnValue({
          returning: vi.fn().mockResolvedValue([{ ...dbPandit, isAvailable: true, latitude: 28.4744, longitude: 77.5040 }])
        })
      })
    });

    const res = await request(app)
      .patch("/api/v1/pandits/duty-status")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ isAvailable: true, lat: 28.4744, lng: 77.5040 });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(mockGeoAdd).toHaveBeenCalledWith("pandits:live", 77.504, 28.4744, "pandit1");
  });

  it("400 – rejects invalid latitude (> 90)", async () => {
    const res = await request(app)
      .patch("/api/v1/pandits/duty-status")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ isAvailable: true, lat: 95.0, lng: 77.5040 });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("VALIDATION_ERROR");
  });

  it("400 – rejects invalid longitude (> 180)", async () => {
    const res = await request(app)
      .patch("/api/v1/pandits/duty-status")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ isAvailable: true, lat: 28.4744, lng: 185.0 });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("VALIDATION_ERROR");
  });

  it("400 – rejects supplying lat without lng", async () => {
    const res = await request(app)
      .patch("/api/v1/pandits/duty-status")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ isAvailable: true, lat: 28.4744 });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("VALIDATION_ERROR");
    expect(res.body.error.details.fields.lat[0]).toContain("Both lat and lng must be provided together");
  });

  it("400 – rejects supplying lng without lat", async () => {
    const res = await request(app)
      .patch("/api/v1/pandits/duty-status")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ isAvailable: true, lng: 77.5040 });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("VALIDATION_ERROR");
    expect(res.body.error.details.fields.lat[0]).toContain("Both lat and lng must be provided together");
  });

  it("404 – returns 404 when pandit profile is not found", async () => {
    mockFindFirst.mockResolvedValue(null);

    const res = await request(app)
      .patch("/api/v1/pandits/duty-status")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ isAvailable: false });

    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe("NOT_FOUND");
  });

  it("403 – forbids unapproved pandit from updating duty status", async () => {
    const unapprovedPandit = { id: "pandit1", userId: panditUserId, verificationStatus: "PENDING", isVerified: false };
    mockFindFirst.mockResolvedValue(unapprovedPandit);

    const res = await request(app)
      .patch("/api/v1/pandits/duty-status")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ isAvailable: true });

    expect(res.status).toBe(403);
    expect(res.body.error.code).toBe("PANDIT_NOT_APPROVED");
  });

  it("403 – forbids non-pandit users from updating duty status", async () => {
    const res = await request(app)
      .patch("/api/v1/pandits/duty-status")
      .set("Authorization", `Bearer ${yajmanToken}`)
      .send({ isAvailable: true });

    expect(res.status).toBe(403);
    expect(res.body.error.code).toBe("FORBIDDEN");
  });
});

describe("POST /api/v1/pandits/accept-booking", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  const panditUserId = "33333333-3333-3333-3333-333333333333";
  const panditToken = signTestToken({
    id: panditUserId,
    phone: "+919876543210",
    role: "PANDIT",
  });

  const validBookingId = "55555555-5555-5555-5555-555555555555";

  it("200 – successfully accepts a pending booking", async () => {
    const dbPandit = { id: "pandit1", userId: panditUserId, verificationStatus: "APPROVED", isVerified: true };
    mockFindFirst.mockResolvedValue(dbPandit);
    mockBookingFindFirst.mockResolvedValue({ id: validBookingId, status: "PENDING", panditId: null });

    const dbBooking = { id: validBookingId, status: "CONFIRMED", panditId: panditUserId };
    mockUpdate.mockReturnValue({
      set: vi.fn().mockReturnValue({
        where: vi.fn().mockReturnValue({
          returning: vi.fn().mockResolvedValue([dbBooking])
        })
      })
    });

    const res = await request(app)
      .post("/api/v1/pandits/accept-booking")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ bookingId: validBookingId });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.booking.status).toBe("CONFIRMED");
    expect(res.body.data.booking.panditId).toBe(panditUserId);
  });

  it("200 – idempotent acceptance if same pandit accepts already confirmed booking", async () => {
    const dbPandit = { id: "pandit1", userId: panditUserId, verificationStatus: "APPROVED", isVerified: true };
    mockFindFirst.mockResolvedValue(dbPandit);
    mockBookingFindFirst.mockResolvedValue({ id: validBookingId, status: "CONFIRMED", panditId: panditUserId });

    const res = await request(app)
      .post("/api/v1/pandits/accept-booking")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ bookingId: validBookingId });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.booking.status).toBe("CONFIRMED");
    expect(res.body.data.booking.panditId).toBe(panditUserId);
  });

  it("404 – returns 404 when booking does not exist", async () => {
    const dbPandit = { id: "pandit1", userId: panditUserId, verificationStatus: "APPROVED", isVerified: true };
    mockFindFirst.mockResolvedValue(dbPandit);
    mockBookingFindFirst.mockResolvedValue(null);

    const res = await request(app)
      .post("/api/v1/pandits/accept-booking")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ bookingId: validBookingId });

    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe("NOT_FOUND");
    expect(res.body.error.message).toContain("Booking not found");
  });

  it("400 – rejects missing or non-UUID bookingId", async () => {
    const res = await request(app)
      .post("/api/v1/pandits/accept-booking")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ bookingId: "invalid-not-uuid" });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("VALIDATION_ERROR");
  });

  it("409 – returns conflict if booking was already taken by another pandit", async () => {
    const dbPandit = { id: "pandit1", userId: panditUserId, verificationStatus: "APPROVED", isVerified: true };
    mockFindFirst.mockResolvedValue(dbPandit);
    mockBookingFindFirst.mockResolvedValue({ id: validBookingId, status: "CONFIRMED", panditId: "other-pandit-uuid" });

    const res = await request(app)
      .post("/api/v1/pandits/accept-booking")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ bookingId: validBookingId });

    expect(res.status).toBe(409);
    expect(res.body.error.message).toBe("BOOKING_ALREADY_TAKEN");
  });

  it("409 – returns conflict on concurrent atomic race condition (0 rows updated)", async () => {
    const dbPandit = { id: "pandit1", userId: panditUserId, verificationStatus: "APPROVED", isVerified: true };
    mockFindFirst.mockResolvedValue(dbPandit);
    mockBookingFindFirst.mockResolvedValue({ id: validBookingId, status: "PENDING", panditId: null });

    mockUpdate.mockReturnValue({
      set: vi.fn().mockReturnValue({
        where: vi.fn().mockReturnValue({
          returning: vi.fn().mockResolvedValue([]) // Simulate 0 rows updated because another Pandit committed first
        })
      })
    });

    const res = await request(app)
      .post("/api/v1/pandits/accept-booking")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ bookingId: validBookingId });

    expect(res.status).toBe(409);
    expect(res.body.error.message).toBe("BOOKING_ALREADY_TAKEN");
  });

  it("400 – rejects accepting a cancelled booking", async () => {
    const dbPandit = { id: "pandit1", userId: panditUserId, verificationStatus: "APPROVED", isVerified: true };
    mockFindFirst.mockResolvedValue(dbPandit);
    mockBookingFindFirst.mockResolvedValue({ id: validBookingId, status: "CANCELLED", panditId: null });

    const res = await request(app)
      .post("/api/v1/pandits/accept-booking")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ bookingId: validBookingId });

    expect(res.status).toBe(400);
    expect(res.body.error.message).toContain("BOOKING_ALREADY_CANCELLED");
  });

  it("403 – rejects unapproved pandit from accepting booking", async () => {
    const unapprovedPandit = { id: "pandit1", userId: panditUserId, verificationStatus: "PENDING", isVerified: false };
    mockFindFirst.mockResolvedValue(unapprovedPandit);

    const res = await request(app)
      .post("/api/v1/pandits/accept-booking")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ bookingId: validBookingId });

    expect(res.status).toBe(403);
    expect(res.body.error.code).toBe("PANDIT_NOT_APPROVED");
  });
});

describe("POST /api/v1/pandits/decline-booking", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  const panditUserId = "33333333-3333-3333-3333-333333333333";
  const panditToken = signTestToken({
    id: panditUserId,
    phone: "+919876543210",
    role: "PANDIT",
  });

  const validBookingId = "55555555-5555-5555-5555-555555555555";

  it("200 – successfully declines a pending booking and persists decline record", async () => {
    const dbPandit = { id: "pandit1", userId: panditUserId, verificationStatus: "APPROVED", isVerified: true };
    mockFindFirst.mockResolvedValue(dbPandit);
    mockBookingFindFirst.mockResolvedValue({ id: validBookingId, status: "PENDING", panditId: null });
    mockDeclineFindFirst.mockResolvedValue(null);

    const dbDecline = { id: "dec-1", bookingId: validBookingId, panditId: panditUserId, reason: "TOO_FAR" };
    mockInsert.mockReturnValue({
      values: vi.fn().mockReturnValue({
        onConflictDoNothing: vi.fn().mockReturnValue({
          returning: vi.fn().mockResolvedValue([dbDecline])
        })
      })
    });

    const res = await request(app)
      .post("/api/v1/pandits/decline-booking")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ bookingId: validBookingId, reason: "TOO_FAR", notes: "Beyond 20km radius" });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.decline.reason).toBe("TOO_FAR");
    expect(mockInsert).toHaveBeenCalled();
  });

  it("200 – handles duplicate declines idempotently without duplicate records", async () => {
    const dbPandit = { id: "pandit1", userId: panditUserId, verificationStatus: "APPROVED", isVerified: true };
    mockFindFirst.mockResolvedValue(dbPandit);
    mockBookingFindFirst.mockResolvedValue({ id: validBookingId, status: "PENDING", panditId: null });

    const existingDecline = { id: "dec-1", bookingId: validBookingId, panditId: panditUserId, reason: "BUSY" };
    mockDeclineFindFirst.mockResolvedValue(existingDecline);

    const res = await request(app)
      .post("/api/v1/pandits/decline-booking")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ bookingId: validBookingId, reason: "BUSY" });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.decline.id).toBe("dec-1");
    expect(mockInsert).not.toHaveBeenCalled();
  });

  it("400 – rejects invalid decline reason", async () => {
    const res = await request(app)
      .post("/api/v1/pandits/decline-booking")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ bookingId: validBookingId, reason: "INVALID_REASON" });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("VALIDATION_ERROR");
  });

  it("404 – returns 404 when booking does not exist", async () => {
    const dbPandit = { id: "pandit1", userId: panditUserId, verificationStatus: "APPROVED", isVerified: true };
    mockFindFirst.mockResolvedValue(dbPandit);
    mockBookingFindFirst.mockResolvedValue(null);

    const res = await request(app)
      .post("/api/v1/pandits/decline-booking")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ bookingId: validBookingId });

    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe("NOT_FOUND");
    expect(res.body.error.message).toContain("Booking not found");
  });

  it("400 – rejects declining a cancelled booking", async () => {
    const dbPandit = { id: "pandit1", userId: panditUserId, verificationStatus: "APPROVED", isVerified: true };
    mockFindFirst.mockResolvedValue(dbPandit);
    mockBookingFindFirst.mockResolvedValue({ id: validBookingId, status: "CANCELLED", panditId: null });

    const res = await request(app)
      .post("/api/v1/pandits/decline-booking")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ bookingId: validBookingId });

    expect(res.status).toBe(400);
    expect(res.body.error.message).toContain("BOOKING_ALREADY_CANCELLED");
  });

  it("400 – rejects declining an already accepted booking by this pandit", async () => {
    const dbPandit = { id: "pandit1", userId: panditUserId, verificationStatus: "APPROVED", isVerified: true };
    mockFindFirst.mockResolvedValue(dbPandit);
    mockBookingFindFirst.mockResolvedValue({ id: validBookingId, status: "CONFIRMED", panditId: panditUserId });

    const res = await request(app)
      .post("/api/v1/pandits/decline-booking")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ bookingId: validBookingId });

    expect(res.status).toBe(400);
    expect(res.body.error.message).toContain("BOOKING_ALREADY_ACCEPTED");
  });

  it("409 – returns conflict if booking is already taken by another pandit", async () => {
    const dbPandit = { id: "pandit1", userId: panditUserId, verificationStatus: "APPROVED", isVerified: true };
    mockFindFirst.mockResolvedValue(dbPandit);
    mockBookingFindFirst.mockResolvedValue({ id: validBookingId, status: "CONFIRMED", panditId: "other-pandit-id" });

    const res = await request(app)
      .post("/api/v1/pandits/decline-booking")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ bookingId: validBookingId });

    expect(res.status).toBe(409);
    expect(res.body.error.message).toBe("BOOKING_ALREADY_TAKEN");
  });

  it("403 – rejects unapproved pandit from declining booking", async () => {
    const unapprovedPandit = { id: "pandit1", userId: panditUserId, verificationStatus: "PENDING", isVerified: false };
    mockFindFirst.mockResolvedValue(unapprovedPandit);

    const res = await request(app)
      .post("/api/v1/pandits/decline-booking")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ bookingId: validBookingId });

    expect(res.status).toBe(403);
    expect(res.body.error.code).toBe("PANDIT_NOT_APPROVED");
  });
});

describe("GET /api/v1/pandits/dashboard", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  const panditUserId = "33333333-3333-3333-3333-333333333333";
  const panditToken = signTestToken({
    id: panditUserId,
    phone: "+919876543210",
    role: "PANDIT",
  });

  it("200 – returns dashboard with aggregated metrics and pending requests", async () => {
    const dbPandit = { 
      id: "pandit1", 
      userId: panditUserId,
      serviceRadiusKm: 15,
      latitude: 28.7,
      longitude: 77.1,
      rating: "4.90",
      verificationStatus: "APPROVED",
      isVerified: true,
    };
    mockFindFirst.mockResolvedValue(dbPandit);

    // Mock today's bookings for earnings & count
    const today = new Date().toISOString();
    mockFindMany
      .mockResolvedValueOnce([ // For allPanditBookings
        { id: "b1", bookingTime: today, status: "COMPLETED", totalAmount: "1000.00" },
        { id: "b2", bookingTime: today, status: "COMPLETED", totalAmount: "500.00" },
        { id: "b3", bookingTime: today, status: "CONFIRMED", totalAmount: "1000.00" },
      ])
      .mockResolvedValueOnce([ // For pendingRequests
        { id: "p1", status: "PENDING", totalAmount: "1500.00" }
      ]);

    const res = await request(app)
      .get("/api/v1/pandits/dashboard")
      .set("Authorization", `Bearer ${panditToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.dashboard.todayCount).toBe(3);
    expect(res.body.data.dashboard.totalEarnings).toBe("1500.00");
    expect(res.body.data.dashboard.rating).toBe("4.90");
    expect(res.body.data.dashboard.pendingRequests).toHaveLength(1);
  });

  it("403 – forbids unapproved pandit from accessing dashboard", async () => {
    const unapprovedPandit = {
      id: "pandit1",
      userId: panditUserId,
      verificationStatus: "PENDING",
      isVerified: false,
    };
    mockFindFirst.mockResolvedValue(unapprovedPandit);

    const res = await request(app)
      .get("/api/v1/pandits/dashboard")
      .set("Authorization", `Bearer ${panditToken}`);

    expect(res.status).toBe(403);
    expect(res.body.error.code).toBe("PANDIT_NOT_APPROVED");
  });
});
