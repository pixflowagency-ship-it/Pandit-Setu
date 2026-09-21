import { describe, it, expect, vi, beforeEach } from "vitest";
import { processLocationUpdate, getLiveLocation } from "../services/tracking.service.js";

/* ------------------------------------------------------------------ *
 *  Mock DB, Redis, and Socket
 * ------------------------------------------------------------------ */
const {
  mockFindFirst,
  mockUpdate,
  mockRedisSet,
  mockRedisSetex,
  mockRedisGet,
  mockRedisGeoadd,
  mockRedisGeopos,
  mockEmit,
} = vi.hoisted(() => {
  return {
    mockFindFirst: vi.fn(),
    mockUpdate: vi.fn(),
    mockRedisSet: vi.fn(),
    mockRedisSetex: vi.fn(),
    mockRedisGet: vi.fn(),
    mockRedisGeoadd: vi.fn(),
    mockRedisGeopos: vi.fn(),
    mockEmit: vi.fn(),
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

vi.mock("drizzle-orm", async (importOriginal) => {
  const actual: any = await importOriginal();
  return {
    ...actual,
    sql: (...args: any[]) => `MOCK_SQL: ${args}`, // Simple mock for sql`` string template
  };
});

vi.mock("../config/redis.js", () => ({
  getRedis: vi.fn().mockResolvedValue({
    set: (...args: any[]) => mockRedisSet(...args),
    setex: (...args: any[]) => mockRedisSetex(...args),
    get: (...args: any[]) => mockRedisGet(...args),
    geoadd: (...args: any[]) => mockRedisGeoadd(...args),
    geopos: (...args: any[]) => mockRedisGeopos(...args),
  }),
}));

vi.mock("../services/realtime.service.js", () => ({
  getIO: vi.fn().mockReturnValue({
    to: vi.fn().mockReturnValue({
      emit: (...args: any[]) => mockEmit(...args),
    }),
  }),
}));

/* ------------------------------------------------------------------ *
 *  Test Suites
 * ------------------------------------------------------------------ */

describe("Tracking Service - processLocationUpdate", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  const panditId = "pandit123";
  const bookingId = "booking123";
  const lat = 28.7041;
  const lng = 77.1025;

  it("drops update if rate limit set fails (already updated in last 1s)", async () => {
    // Redis SETNX returns null/false if key exists
    mockRedisSet.mockResolvedValueOnce(null);

    await processLocationUpdate(panditId, bookingId, lat, lng);

    expect(mockRedisSet).toHaveBeenCalledWith(`tracking:rate_limit:${panditId}`, "1", "EX", 1, "NX");
    expect(mockRedisGeoadd).not.toHaveBeenCalled(); // Dropped
    expect(mockEmit).not.toHaveBeenCalled(); // Dropped
  });

  it("processes update, writes to GEO cache, broadcasts, and skips PG if recent sync exists", async () => {
    mockRedisSet.mockResolvedValueOnce("OK"); // Rate limit acquired
    mockRedisGet.mockResolvedValueOnce("1");  // PG sync occurred recently (within 30s)

    await processLocationUpdate(panditId, bookingId, lat, lng);

    expect(mockRedisGeoadd).toHaveBeenCalledWith("pandits:live", lng, lat, panditId);
    expect(mockEmit).toHaveBeenCalledWith("pandit:location-update", { bookingId, lat, lng });
    expect(mockUpdate).not.toHaveBeenCalled(); // DB skipped
  });

  it("processes update and performs PG batch sync if last sync expired", async () => {
    mockRedisSet.mockResolvedValueOnce("OK"); // Rate limit acquired
    mockRedisGet.mockResolvedValueOnce(null); // PG sync expired!

    const updateSetMock = vi.fn().mockReturnValue({
      where: vi.fn().mockResolvedValue(true)
    });
    mockUpdate.mockReturnValue({ set: updateSetMock });

    await processLocationUpdate(panditId, bookingId, lat, lng);

    expect(mockRedisGeoadd).toHaveBeenCalled();
    expect(updateSetMock).toHaveBeenCalled(); // DB Written!
    expect(mockRedisSetex).toHaveBeenCalledWith(`tracking:last_pg_sync:${panditId}`, 30, "1"); // Lock acquired
  });
});

describe("Tracking Service - getLiveLocation", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("retrieves location from Redis GEO instantly if available", async () => {
    const bookingId = "booking123";
    const panditId = "pandit123";
    
    mockFindFirst.mockResolvedValueOnce({ panditId, yajmanId: "yajman123" });
    // geopos returns an array of [lng, lat] pairs
    mockRedisGeopos.mockResolvedValueOnce([["77.1025", "28.7041"]]);

    const result = await getLiveLocation(bookingId, "yajman123", "YAJMAN");

    expect(result).toEqual({ lat: 28.7041, lng: 77.1025, source: "redis" });
  });

  it("enforces strict ownership validation based on role", async () => {
    const bookingId = "booking123";
    mockFindFirst.mockResolvedValueOnce({ panditId: "pandit123", yajmanId: "real_yajman" });

    await expect(getLiveLocation(bookingId, "imposter_yajman", "YAJMAN"))
      .rejects.toThrow(/You are not authorized/);
  });
});
