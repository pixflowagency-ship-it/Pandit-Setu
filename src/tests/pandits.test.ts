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
  mockUpdate,
  mockGeoAdd,
  mockZRem,
} = vi.hoisted(() => {
  return {
    mockFindMany: vi.fn(),
    mockFindFirst: vi.fn(),
    mockUpdate: vi.fn(),
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
      }
    },
    update: (...args: any[]) => mockUpdate(...args),
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
    const dbPandit = { id: "pandit1", userId: panditUserId, latitude: 28.7041, longitude: 77.1025 };
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
    const dbPandit = { id: "pandit1", userId: panditUserId, latitude: 28.7041, longitude: 77.1025 };
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
    const dbPandit = { id: "pandit1", userId: panditUserId };
    mockFindFirst.mockResolvedValue(dbPandit);

    const res = await request(app)
      .patch("/api/v1/pandits/duty-status")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ isAvailable: true });

    expect(res.status).toBe(400);
    expect(res.body.error.message).toContain("location");
    expect(mockGeoAdd).not.toHaveBeenCalled();
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
    const dbPandit = { id: "pandit1", userId: panditUserId };
    mockFindFirst.mockResolvedValue(dbPandit);

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

  it("409 – returns conflict if booking was already taken (race condition)", async () => {
    const dbPandit = { id: "pandit1", userId: panditUserId };
    mockFindFirst.mockResolvedValue(dbPandit);

    mockUpdate.mockReturnValue({
      set: vi.fn().mockReturnValue({
        where: vi.fn().mockReturnValue({
          returning: vi.fn().mockResolvedValue([]) // Simulate 0 rows updated
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
      rating: "4.90" 
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
});
