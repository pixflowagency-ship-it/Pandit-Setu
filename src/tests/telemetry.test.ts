import { describe, it, expect, vi, beforeEach } from "vitest";
import request from "supertest";
import { signTestToken, yajmanToken } from "./helpers/setup.js";

/* ------------------------------------------------------------------ *
 *  Mocks for DB and Redis
 * ------------------------------------------------------------------ */
const {
  mockPanditFindFirst,
  mockPanditFindMany,
  mockBookingFindFirst,
  mockBookingFindMany,
  mockDbUpdate,
  mockRedisGeoAdd,
  mockRedisSet,
  mockRedisGet,
  mockRedisGeopos,
  mockSocketEmit,
} = vi.hoisted(() => ({
  mockPanditFindFirst: vi.fn(),
  mockPanditFindMany: vi.fn(),
  mockBookingFindFirst: vi.fn(),
  mockBookingFindMany: vi.fn(),
  mockDbUpdate: vi.fn(),
  mockRedisGeoAdd: vi.fn(),
  mockRedisSet: vi.fn(),
  mockRedisGet: vi.fn(),
  mockRedisGeopos: vi.fn(),
  mockSocketEmit: vi.fn(),
}));

vi.mock("../db/index.js", () => ({
  db: {
    query: {
      pandits: {
        findFirst: (...args: any[]) => mockPanditFindFirst(...args),
        findMany: (...args: any[]) => mockPanditFindMany(...args),
      },
      bookings: {
        findFirst: (...args: any[]) => mockBookingFindFirst(...args),
        findMany: (...args: any[]) => mockBookingFindMany(...args),
      },
      bookingDeclines: {
        findMany: vi.fn().mockResolvedValue([]),
      },
    },
    update: () => ({
      set: () => ({
        where: () => mockDbUpdate(),
      }),
    }),
  },
  pandits: {
    id: "id",
    userId: "user_id",
  },
  bookings: {
    id: "id",
    panditId: "pandit_id",
    status: "status",
  },
  bookingDeclines: {
    bookingId: "booking_id",
    panditId: "pandit_id",
  },
}));

vi.mock("../config/redis.js", () => ({
  getRedis: vi.fn().mockResolvedValue({
    geoadd: (...args: any[]) => mockRedisGeoAdd(...args),
    set: (...args: any[]) => mockRedisSet(...args),
    get: (...args: any[]) => mockRedisGet(...args),
    geopos: (...args: any[]) => mockRedisGeopos(...args),
    setex: vi.fn().mockResolvedValue("OK"),
    del: vi.fn().mockResolvedValue(1),
  }),
  closeRedis: vi.fn().mockResolvedValue(undefined),
}));

vi.mock("../services/realtime.service.js", () => ({
  getIO: () => ({
    to: () => ({
      emit: mockSocketEmit,
    }),
  }),
  initializeSocket: vi.fn(),
  closeSocket: vi.fn(),
}));

import app from "../app.js";
import { dispatchBooking } from "../services/dispatch.service.js";

const approvedPanditToken = signTestToken({
  id: "00000000-0000-0000-0000-000000000002",
  phone: "+919876543211",
  role: "PANDIT",
});

const unapprovedPanditToken = signTestToken({
  id: "00000000-0000-0000-0000-000000000003",
  phone: "+919876543212",
  role: "PANDIT",
});

describe("Pandit GPS Telemetry & Live Tracking (Phase P4)", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockDbUpdate.mockResolvedValue([]);
    mockRedisSet.mockResolvedValue("OK");
    mockRedisGeoAdd.mockResolvedValue(1);
    mockBookingFindMany.mockResolvedValue([]);
  });

  describe("POST /api/v1/pandits/me/telemetry", () => {
    it("401 – rejects request when unauthenticated", async () => {
      const res = await request(app)
        .post("/api/v1/pandits/me/telemetry")
        .send({ lat: 28.5355, lng: 77.3910 });
      expect(res.status).toBe(401);
    });

    it("403 – rejects request if user is Devotee/Yajman", async () => {
      const res = await request(app)
        .post("/api/v1/pandits/me/telemetry")
        .set("Authorization", `Bearer ${yajmanToken}`)
        .send({ lat: 28.5355, lng: 77.3910 });
      expect(res.status).toBe(403);
    });

    it("403 – rejects telemetry from unapproved Pandit", async () => {
      mockPanditFindFirst.mockResolvedValue({
        id: "pandit-profile-2",
        userId: "00000000-0000-0000-0000-000000000003",
        isVerified: false,
        verificationStatus: "PENDING",
        isAvailable: true,
      });

      const res = await request(app)
        .post("/api/v1/pandits/me/telemetry")
        .set("Authorization", `Bearer ${unapprovedPanditToken}`)
        .send({ lat: 28.5355, lng: 77.3910 });

      expect(res.status).toBe(403);
      expect(res.body.error.code).toBe("PANDIT_NOT_APPROVED");
    });

    it("400 – rejects telemetry when Pandit is off-duty", async () => {
      mockPanditFindFirst.mockResolvedValue({
        id: "pandit-profile-1",
        userId: "00000000-0000-0000-0000-000000000002",
        isVerified: true,
        verificationStatus: "APPROVED",
        isAvailable: false, // OFF DUTY
      });

      const res = await request(app)
        .post("/api/v1/pandits/me/telemetry")
        .set("Authorization", `Bearer ${approvedPanditToken}`)
        .send({ lat: 28.5355, lng: 77.3910 });

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe("PANDIT_OFF_DUTY");
    });

    it("400 – rejects invalid coordinates (latitude > 90)", async () => {
      mockPanditFindFirst.mockResolvedValue({
        id: "pandit-profile-1",
        userId: "00000000-0000-0000-0000-000000000002",
        isVerified: true,
        verificationStatus: "APPROVED",
        isAvailable: true,
      });

      const res = await request(app)
        .post("/api/v1/pandits/me/telemetry")
        .set("Authorization", `Bearer ${approvedPanditToken}`)
        .send({ lat: 95.0, lng: 77.3910 });

      expect(res.status).toBe(400);
    });

    it("400 – rejects stale timestamp (> 5 minutes old)", async () => {
      mockPanditFindFirst.mockResolvedValue({
        id: "pandit-profile-1",
        userId: "00000000-0000-0000-0000-000000000002",
        isVerified: true,
        verificationStatus: "APPROVED",
        isAvailable: true,
      });

      const staleTimestamp = new Date(Date.now() - 6 * 60 * 1000).toISOString();

      const res = await request(app)
        .post("/api/v1/pandits/me/telemetry")
        .set("Authorization", `Bearer ${approvedPanditToken}`)
        .send({
          lat: 28.5355,
          lng: 77.3910,
          timestamp: staleTimestamp,
        });

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe("STALE_LOCATION_UPDATE");
    });

    it("400 – rejects future timestamp (> 1 minute into future)", async () => {
      mockPanditFindFirst.mockResolvedValue({
        id: "pandit-profile-1",
        userId: "00000000-0000-0000-0000-000000000002",
        isVerified: true,
        verificationStatus: "APPROVED",
        isAvailable: true,
      });

      const futureTimestamp = new Date(Date.now() + 2 * 60 * 1000).toISOString();

      const res = await request(app)
        .post("/api/v1/pandits/me/telemetry")
        .set("Authorization", `Bearer ${approvedPanditToken}`)
        .send({
          lat: 28.5355,
          lng: 77.3910,
          timestamp: futureTimestamp,
        });

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe("INVALID_TIMESTAMP");
    });

    it("200 – successfully records telemetry, updates Redis GEO & metadata, and updates PostgreSQL", async () => {
      mockPanditFindFirst.mockResolvedValue({
        id: "pandit-profile-1",
        userId: "00000000-0000-0000-0000-000000000002",
        isVerified: true,
        verificationStatus: "APPROVED",
        isAvailable: true,
      });

      const res = await request(app)
        .post("/api/v1/pandits/me/telemetry")
        .set("Authorization", `Bearer ${approvedPanditToken}`)
        .send({
          lat: 28.5355,
          lng: 77.3910,
          accuracy: 10.5,
          heading: 90,
          speed: 12.0,
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe("RECORDED");
      expect(res.body.data.panditId).toBe("pandit-profile-1");
      expect(res.body.data.lat).toBe(28.5355);
      expect(res.body.data.lng).toBe(77.3910);
      expect(mockRedisGeoAdd).toHaveBeenCalledWith("pandits:live", 77.3910, 28.5355, "pandit-profile-1");
      expect(mockDbUpdate).toHaveBeenCalled();
    });

    it("emits real-time location update to active booking room when assigned", async () => {
      mockPanditFindFirst.mockResolvedValue({
        id: "pandit-profile-1",
        userId: "00000000-0000-0000-0000-000000000002",
        isVerified: true,
        verificationStatus: "APPROVED",
        isAvailable: true,
      });

      mockBookingFindMany.mockResolvedValue([
        { id: "booking-active-101", status: "HEADING_TO_VENUE" },
      ]);

      const res = await request(app)
        .post("/api/v1/pandits/me/telemetry")
        .set("Authorization", `Bearer ${approvedPanditToken}`)
        .send({
          lat: 28.5355,
          lng: 77.3910,
          accuracy: 10.5,
        });

      expect(res.status).toBe(200);
      expect(mockSocketEmit).toHaveBeenCalledWith(
        "pandit:location-update",
        expect.objectContaining({
          bookingId: "booking-active-101",
          lat: 28.5355,
          lng: 77.3910,
        })
      );
    });
  });

  describe("GET /api/v1/tracking/:bookingId", () => {
    it("401 – rejects unauthenticated user", async () => {
      const res = await request(app).get("/api/v1/tracking/booking-1");
      expect(res.status).toBe(401);
    });

    it("403 – rejects unauthorized devotee tracking someone else's booking", async () => {
      mockBookingFindFirst.mockResolvedValue({
        id: "booking-1",
        yajmanId: "other-yajman-uuid",
        panditId: "00000000-0000-0000-0000-000000000002",
      });

      const res = await request(app)
        .get("/api/v1/tracking/booking-1")
        .set("Authorization", `Bearer ${yajmanToken}`);

      expect(res.status).toBe(403);
    });

    it("200 – returns live coordinates to authorized booking owner from Redis", async () => {
      mockBookingFindFirst.mockResolvedValue({
        id: "booking-1",
        yajmanId: "00000000-0000-0000-0000-000000000001",
        panditId: "00000000-0000-0000-0000-000000000002",
      });

      mockPanditFindFirst.mockResolvedValue({
        id: "pandit-profile-1",
        userId: "00000000-0000-0000-0000-000000000002",
      });

      mockRedisGet.mockResolvedValue(
        JSON.stringify({
          lat: 28.5355,
          lng: 77.3910,
          accuracy: 12.0,
          updatedAt: "2026-10-20T00:00:00.000Z",
        })
      );

      const res = await request(app)
        .get("/api/v1/tracking/booking-1")
        .set("Authorization", `Bearer ${yajmanToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.location.lat).toBe(28.5355);
      expect(res.body.data.location.lng).toBe(77.3910);
      expect(res.body.data.location.source).toBe("redis");
    });
  });

  describe("Dispatch Freshness Exclusion", () => {
    it("excludes Pandits whose GPS location is older than 10 minutes from in-person dispatch", async () => {
      mockBookingFindFirst.mockResolvedValue({
        id: "booking-freshness-check",
        mode: "IN_PERSON",
        status: "PENDING",
        panditId: null,
        yajmanId: "00000000-0000-0000-0000-000000000001",
        bookingTime: new Date(),
        samagriIncluded: false,
        totalAmount: "2100.00",
        venueLocation: { lat: 28.5355, lng: 77.3910 },
      });

      // Pandit with stale coordinates (15 minutes ago > 10m threshold)
      const staleTimestamp = new Date(Date.now() - 15 * 60 * 1000);

      mockPanditFindMany
        .mockResolvedValueOnce([{ id: "pandit-stale" }]) // Candidate discovery
        .mockResolvedValueOnce([
          {
            id: "pandit-stale",
            userId: "user-stale",
            isVerified: true,
            verificationStatus: "APPROVED",
            isAvailable: true,
            latitude: 28.5356,
            longitude: 77.3911,
            serviceRadiusKm: 15,
            updatedAt: staleTimestamp, // Stale!
            user: { id: "user-stale", name: "Pt. Stale", phone: "+919876500000" },
          },
        ]);

      const result = await dispatchBooking("booking-freshness-check");
      expect(result.eligibleCount).toBe(0);
      expect(result.notifiedCount).toBe(0);
      expect(result.reason).toBe("NO_ELIGIBLE_PANDITS_AFTER_FILTERING");
    });
  });
});
