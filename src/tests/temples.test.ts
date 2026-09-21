import { describe, it, expect, vi, beforeEach } from "vitest";
import request from "supertest";
import app from "../app.js";
import { yajmanToken } from "./helpers/setup.js";
import geohash from "ngeohash";

/* ------------------------------------------------------------------ *
 *  Mock Redis and global fetch
 * ------------------------------------------------------------------ */
const { mockRedisGet, mockRedisSetex } = vi.hoisted(() => {
  return {
    mockRedisGet: vi.fn(),
    mockRedisSetex: vi.fn(),
  };
});

vi.mock("../config/redis.js", () => ({
  getRedis: vi.fn().mockResolvedValue({
    get: (...args: any[]) => mockRedisGet(...args),
    setex: (...args: any[]) => mockRedisSetex(...args),
  }),
}));

// Mock global fetch
const mockFetch = vi.fn();
global.fetch = mockFetch;

/* ------------------------------------------------------------------ *
 *  Test Suites
 * ------------------------------------------------------------------ */

describe("GET /api/v1/temples/nearby", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  const lat = 28.7041;
  const lng = 77.1025;
  const radiusKm = 5;

  it("200 – returns cached results from Redis directly without fetching", async () => {
    const hash = geohash.encode(lat, lng, 5);
    const cacheKey = `temples:nearby:${hash}`;
    const cachedData = [{ placeId: "cache1", name: "Cached Temple" }];

    mockRedisGet.mockResolvedValueOnce(JSON.stringify(cachedData));

    const res = await request(app)
      .get(`/api/v1/temples/nearby?lat=${lat}&lng=${lng}&radiusKm=${radiusKm}`)
      .set("Authorization", `Bearer ${yajmanToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.temples).toHaveLength(1);
    expect(res.body.data.temples[0].name).toBe("Cached Temple");
    expect(mockRedisGet).toHaveBeenCalledWith(cacheKey);
    expect(mockFetch).not.toHaveBeenCalled();
  });

  it("200 – fetches from Google Places API on cache miss and saves to Redis", async () => {
    mockRedisGet.mockResolvedValueOnce(null); // Cache miss

    const mockPlacesResponse = {
      results: [
        {
          place_id: "place1",
          name: "Live Fetched Temple",
          geometry: { location: { lat: 28.7, lng: 77.1 } },
          vicinity: "Delhi",
          rating: 4.8,
          user_ratings_total: 150,
        },
      ],
    };

    mockFetch.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve(mockPlacesResponse),
    });

    const res = await request(app)
      .get(`/api/v1/temples/nearby?lat=${lat}&lng=${lng}&radiusKm=${radiusKm}`)
      .set("Authorization", `Bearer ${yajmanToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.temples).toHaveLength(1);
    expect(res.body.data.temples[0].name).toBe("Live Fetched Temple");
    expect(mockFetch).toHaveBeenCalled();
    expect(mockRedisSetex).toHaveBeenCalled(); // Should cache the result
  });

  it("500 – handles Google Places API failure gracefully", async () => {
    mockRedisGet.mockResolvedValueOnce(null); // Cache miss

    mockFetch.mockResolvedValueOnce({
      ok: false,
      statusText: "Internal Server Error",
    });

    const res = await request(app)
      .get(`/api/v1/temples/nearby?lat=${lat}&lng=${lng}&radiusKm=${radiusKm}`)
      .set("Authorization", `Bearer ${yajmanToken}`);

    expect(res.status).toBe(500);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe("INTERNAL_ERROR");
  });
});
