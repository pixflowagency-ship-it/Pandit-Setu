import { describe, it, expect, vi, beforeEach } from "vitest";
import {
  dispatchBooking,
  calculateHaversineDistanceKm,
} from "../services/dispatch.service.js";

/* ------------------------------------------------------------------ *
 *  Mock DB, Redis, and Realtime Service                              *
 * ------------------------------------------------------------------ */
const {
  mockBookingFindFirst,
  mockPanditFindMany,
  mockConflictingBookingFindFirst,
  mockDeclineFindMany,
  mockRedisGet,
  mockRedisSet,
  mockRedisDel,
  mockRedisGeoradius,
  mockSocketEmit,
  mockSocketTo,
} = vi.hoisted(() => {
  return {
    mockBookingFindFirst: vi.fn(),
    mockPanditFindMany: vi.fn(),
    mockConflictingBookingFindFirst: vi.fn(),
    mockDeclineFindMany: vi.fn(),
    mockRedisGet: vi.fn(),
    mockRedisSet: vi.fn(),
    mockRedisDel: vi.fn(),
    mockRedisGeoradius: vi.fn(),
    mockSocketEmit: vi.fn(),
    mockSocketTo: vi.fn(),
  };
});

vi.mock("../db/index.js", () => ({
  db: {
    query: {
      bookings: {
        findFirst: (...args: any[]) => {
          // If query checks conflicting bookings for a pandit
          const whereStr = JSON.stringify(args[0]);
          if (whereStr && whereStr.includes("IN_PROGRESS")) {
            return mockConflictingBookingFindFirst(...args);
          }
          return mockBookingFindFirst(...args);
        },
      },
      pandits: {
        findMany: (...args: any[]) => mockPanditFindMany(...args),
      },
      bookingDeclines: {
        findMany: (...args: any[]) => mockDeclineFindMany(...args),
      },
    },
  },
  bookings: { id: "id", panditId: "panditId", status: "status", bookingTime: "bookingTime" },
  pandits: { id: "id", location: "location", isAvailable: "isAvailable", isVerified: "isVerified", verificationStatus: "verificationStatus" },
  poojas: { id: "id" },
  bookingDeclines: { bookingId: "bookingId", panditId: "panditId" },
}));

vi.mock("../config/redis.js", () => ({
  getRedis: vi.fn().mockResolvedValue({
    get: (...args: any[]) => mockRedisGet(...args),
    set: (...args: any[]) => mockRedisSet(...args),
    del: (...args: any[]) => mockRedisDel(...args),
    georadius: (...args: any[]) => mockRedisGeoradius(...args),
  }),
}));

vi.mock("../services/realtime.service.js", () => ({
  getIO: vi.fn().mockReturnValue({
    to: (...args: any[]) => {
      mockSocketTo(...args);
      return {
        emit: (...emitArgs: any[]) => mockSocketEmit(...emitArgs),
      };
    },
  }),
}));

describe("Pooja Request Dispatch Engine (Phase P2-B Task 2)", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockRedisSet.mockResolvedValue("OK");
    mockRedisGet.mockResolvedValue(null);
    mockRedisDel.mockResolvedValue(1);
    mockConflictingBookingFindFirst.mockResolvedValue(null); // No conflicts by default
    mockDeclineFindMany.mockResolvedValue([]); // No declines by default
  });

  const validBookingId = "11111111-1111-1111-1111-111111111111";
  const validPoojaId = "22222222-2222-2222-2222-222222222222";
  const yajmanUserId = "33333333-3333-3333-3333-333333333333";

  const sampleBooking = {
    id: validBookingId,
    yajmanId: yajmanUserId,
    poojaId: validPoojaId,
    mode: "IN_PERSON",
    bookingTime: new Date(Date.now() + 3600 * 1000), // 1 hour in future
    venueLocation: { lat: 28.5355, lng: 77.3910 },
    venueAddress: "Flat 402, Lotus Greens, Sector 78 Noida",
    samagriIncluded: true,
    totalAmount: "2500.00",
    status: "PENDING",
    panditId: null,
    pooja: { id: validPoojaId, title: "Satyanarayan Katha with Havan" },
  };

  const samplePandit1 = {
    id: "pandit-pk-1",
    userId: "pandit-user-1",
    verificationStatus: "APPROVED",
    isVerified: true,
    isAvailable: true,
    serviceRadiusKm: 15,
    latitude: 28.5400,
    longitude: 77.3950,
    updatedAt: new Date(),
    user: { id: "pandit-user-1", name: "Acharya Shastri", phone: "+919876543210" },
  };

  const samplePandit2 = {
    id: "pandit-pk-2",
    userId: "pandit-user-2",
    verificationStatus: "APPROVED",
    isVerified: true,
    isAvailable: true,
    serviceRadiusKm: 15,
    latitude: 28.5420,
    longitude: 77.3970,
    updatedAt: new Date(),
    user: { id: "pandit-user-2", name: "Pandit Sharma", phone: "+919876543211" },
  };

  it("Haversine distance calculation is accurate", () => {
    // Distance between Sector 78 Noida (28.5355, 77.3910) and Botanical Garden Noida (28.5644, 77.3344)
    const dist = calculateHaversineDistanceKm(28.5355, 77.3910, 28.5644, 77.3344);
    expect(dist).toBeGreaterThan(6.0);
    expect(dist).toBeLessThan(7.5);
  });

  it("successfully discovers and dispatches to eligible approved nearby Pandits", async () => {
    mockBookingFindFirst.mockResolvedValue(sampleBooking);
    mockRedisGeoradius.mockResolvedValue(["pandit-pk-1"]);
    mockPanditFindMany.mockResolvedValue([samplePandit1]);

    const result = await dispatchBooking(validBookingId);

    expect(result.success).toBe(true);
    expect(result.candidateCount).toBe(1);
    expect(result.eligibleCount).toBe(1);
    expect(result.notifiedCount).toBe(1);
    expect(result.notifiedPandits[0].panditId).toBe("pandit-pk-1");
    expect(mockSocketTo).toHaveBeenCalledWith("pandit:user:pandit-user-1");
    expect(mockSocketEmit).toHaveBeenCalledWith("booking:new-request", expect.objectContaining({
      bookingId: validBookingId,
      poojaName: "Satyanarayan Katha with Havan",
      totalAmount: "2500.00",
      mode: "IN_PERSON",
    }));
  });

  it("excludes unapproved Pandits (verificationStatus !== APPROVED or isVerified === false)", async () => {
    mockBookingFindFirst.mockResolvedValue(sampleBooking);
    mockRedisGeoradius.mockResolvedValue(["pandit-pk-unapproved"]);
    mockPanditFindMany.mockResolvedValue([{
      ...samplePandit1,
      id: "pandit-pk-unapproved",
      verificationStatus: "PENDING",
      isVerified: false,
    }]);

    const result = await dispatchBooking(validBookingId);

    expect(result.success).toBe(false);
    expect(result.eligibleCount).toBe(0);
    expect(result.notifiedCount).toBe(0);
    expect(result.reason).toBe("NO_ELIGIBLE_PANDITS_AFTER_FILTERING");
    expect(mockSocketEmit).not.toHaveBeenCalled();
  });

  it("excludes offline Pandits (isAvailable === false)", async () => {
    mockBookingFindFirst.mockResolvedValue(sampleBooking);
    mockRedisGeoradius.mockResolvedValue(["pandit-pk-offline"]);
    mockPanditFindMany.mockResolvedValue([{
      ...samplePandit1,
      id: "pandit-pk-offline",
      isAvailable: false,
    }]);

    const result = await dispatchBooking(validBookingId);

    expect(result.success).toBe(false);
    expect(result.eligibleCount).toBe(0);
    expect(result.notifiedCount).toBe(0);
    expect(mockSocketEmit).not.toHaveBeenCalled();
  });

  it("excludes Pandits with stale location (> 24 hours)", async () => {
    mockBookingFindFirst.mockResolvedValue(sampleBooking);
    mockRedisGeoradius.mockResolvedValue(["pandit-pk-stale"]);
    mockPanditFindMany.mockResolvedValue([{
      ...samplePandit1,
      id: "pandit-pk-stale",
      updatedAt: new Date(Date.now() - 30 * 3600 * 1000), // 30 hours old
    }]);

    const result = await dispatchBooking(validBookingId);

    expect(result.success).toBe(false);
    expect(result.eligibleCount).toBe(0);
    expect(result.notifiedCount).toBe(0);
  });

  it("excludes Pandits outside the configured service radius", async () => {
    mockBookingFindFirst.mockResolvedValue(sampleBooking);
    mockRedisGeoradius.mockResolvedValue(["pandit-pk-far"]);
    // Delhi Connaught Place coordinates (approx 25 km away from Sector 78 Noida)
    mockPanditFindMany.mockResolvedValue([{
      ...samplePandit1,
      id: "pandit-pk-far",
      latitude: 28.6315,
      longitude: 77.2167,
      serviceRadiusKm: 10, // Max 10 km, but distance is ~25 km
    }]);

    const result = await dispatchBooking(validBookingId);

    expect(result.success).toBe(false);
    expect(result.eligibleCount).toBe(0);
    expect(result.notifiedCount).toBe(0);
  });

  it("excludes Pandits already assigned to conflicting active bookings", async () => {
    mockBookingFindFirst.mockResolvedValue(sampleBooking);
    mockRedisGeoradius.mockResolvedValue(["pandit-pk-1"]);
    mockPanditFindMany.mockResolvedValue([samplePandit1]);
    // Conflicting booking exists
    mockConflictingBookingFindFirst.mockResolvedValue({ id: "conflicting-booking-id" });

    const result = await dispatchBooking(validBookingId);

    expect(result.success).toBe(false);
    expect(result.eligibleCount).toBe(0);
    expect(result.notifiedCount).toBe(0);
    expect(mockSocketEmit).not.toHaveBeenCalled();
  });

  it("excludes the booking's Yajman if Yajman is also an approved Pandit", async () => {
    mockBookingFindFirst.mockResolvedValue(sampleBooking);
    mockRedisGeoradius.mockResolvedValue(["pandit-pk-1"]);
    mockPanditFindMany.mockResolvedValue([{
      ...samplePandit1,
      userId: yajmanUserId, // Same as booking.yajmanId
    }]);

    const result = await dispatchBooking(validBookingId);

    expect(result.success).toBe(false);
    expect(result.eligibleCount).toBe(0);
  });

  it("rejects dispatch for cancelled or completed bookings", async () => {
    mockBookingFindFirst.mockResolvedValue({
      ...sampleBooking,
      status: "CANCELLED",
    });

    const result = await dispatchBooking(validBookingId);

    expect(result.success).toBe(false);
    expect(result.reason).toBe("INELIGIBLE_STATUS_CANCELLED");
    expect(mockRedisGeoradius).not.toHaveBeenCalled();
    expect(mockSocketEmit).not.toHaveBeenCalled();
  });

  it("rejects dispatch for already-assigned bookings", async () => {
    mockBookingFindFirst.mockResolvedValue({
      ...sampleBooking,
      panditId: "some-assigned-pandit-user-id",
    });

    const result = await dispatchBooking(validBookingId);

    expect(result.success).toBe(false);
    expect(result.reason).toBe("ALREADY_ASSIGNED");
    expect(mockSocketEmit).not.toHaveBeenCalled();
  });

  it("rejects IN_PERSON dispatch when venue coordinates are missing or invalid", async () => {
    mockBookingFindFirst.mockResolvedValue({
      ...sampleBooking,
      venueLocation: null,
    });

    const result = await dispatchBooking(validBookingId);

    expect(result.success).toBe(false);
    expect(result.reason).toBe("MISSING_OR_INVALID_VENUE_COORDINATES");
  });

  it("prevents concurrent dispatch attempts using Redis lock", async () => {
    mockBookingFindFirst.mockResolvedValue(sampleBooking);
    mockRedisSet.mockResolvedValue(null); // Lock could not be acquired (NX failed)

    const result = await dispatchBooking(validBookingId);

    expect(result.success).toBe(false);
    expect(result.reason).toBe("CONCURRENT_DISPATCH_IN_PROGRESS");
    expect(mockSocketEmit).not.toHaveBeenCalled();
  });

  it("prevents duplicate dispatch notifications for the same Pandit within the TTL window", async () => {
    mockBookingFindFirst.mockResolvedValue(sampleBooking);
    mockRedisGeoradius.mockResolvedValue(["pandit-pk-1"]);
    mockPanditFindMany.mockResolvedValue([samplePandit1]);
    // Already notified in Redis
    mockRedisGet.mockResolvedValue("1");

    const result = await dispatchBooking(validBookingId);

    expect(result.success).toBe(false);
    expect(result.reason).toBe("ALL_CANDIDATES_ALREADY_NOTIFIED");
    expect(mockSocketEmit).not.toHaveBeenCalled();
  });

  it("falls back to PostGIS when Redis GEO returns zero candidates", async () => {
    mockBookingFindFirst.mockResolvedValue(sampleBooking);
    mockRedisGeoradius.mockResolvedValue([]); // Redis empty
    mockPanditFindMany
      .mockResolvedValueOnce([{ id: "pandit-pk-1" }]) // PostGIS query returns candidate IDs
      .mockResolvedValueOnce([samplePandit1]); // Authoritative query returns full pandit

    const result = await dispatchBooking(validBookingId);

    expect(result.success).toBe(true);
    expect(result.notifiedCount).toBe(1);
    expect(mockSocketEmit).toHaveBeenCalled();
  });

  it("protects Yajman privacy by excluding phone number and full address unit numbers from dispatch payload", async () => {
    mockBookingFindFirst.mockResolvedValue(sampleBooking);
    mockRedisGeoradius.mockResolvedValue(["pandit-pk-1"]);
    mockPanditFindMany.mockResolvedValue([samplePandit1]);

    await dispatchBooking(validBookingId);

    const emittedPayload = mockSocketEmit.mock.calls[0][1];
    expect(emittedPayload.venueAddress).not.toContain("Flat 402"); // Anonymized
    expect(emittedPayload).not.toHaveProperty("yajmanPhone");
    expect(emittedPayload).not.toHaveProperty("phone");
    expect(emittedPayload).not.toHaveProperty("secret");
  });

  it("excludes Pandits who have persistently declined this booking from receiving the request", async () => {
    mockBookingFindFirst.mockResolvedValue(sampleBooking);
    mockRedisGeoradius.mockResolvedValue(["pandit-pk-1"]);
    mockPanditFindMany.mockResolvedValue([samplePandit1]);

    // Candidate pandit-pk-1 (userId: pandit-user-1) has declined
    mockDeclineFindMany.mockResolvedValue([
      { panditId: "pandit-user-1" },
    ]);

    const result = await dispatchBooking(validBookingId);

    expect(result.success).toBe(false);
    expect(result.eligibleCount).toBe(0);
    expect(result.notifiedCount).toBe(0);
    expect(mockSocketEmit).not.toHaveBeenCalled();
  });

  it("declining by one Pandit does not prevent other eligible Pandits from being notified", async () => {
    mockBookingFindFirst.mockResolvedValue(sampleBooking);
    mockRedisGeoradius.mockResolvedValue(["pandit-pk-1", "pandit-pk-2"]);
    mockPanditFindMany.mockResolvedValue([samplePandit1, samplePandit2]);

    // Only pandit-user-1 has declined; pandit-user-2 is still eligible
    mockDeclineFindMany.mockResolvedValue([
      { panditId: "pandit-user-1" },
    ]);

    const result = await dispatchBooking(validBookingId);

    expect(result.success).toBe(true);
    expect(result.eligibleCount).toBe(1);
    expect(result.notifiedCount).toBe(1);
    expect(result.notifiedPandits[0].userId).toBe("pandit-user-2");
    expect(mockSocketEmit).toHaveBeenCalledTimes(2); // pandit:user:pandit-user-2 and user:pandit-user-2
  });
});
