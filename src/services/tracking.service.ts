import { db } from "../db/index.js";
import { pandits } from "../db/schema/pandits.js";
import { bookings } from "../db/schema/bookings.js";
import { eq, sql } from "drizzle-orm";
import { getRedis } from "../config/redis.js";
import { AppError } from "../utils/api-error.js";

/**
 * High-frequency location update processor.
 * Includes: 1 req/sec strict rate-limiting, Redis GEO write-through, 
 * Socket broadcasting, and 30-second debounced Postgres batch-syncing.
 */
export async function processLocationUpdate(
  panditId: string,
  bookingId: string,
  lat: number,
  lng: number
) {
  const redis = await getRedis();
  
  if (redis) {
    // 1. Strict Server-Side Rate Limiter (1 req/sec)
    const rateLimitKey = `tracking:rate_limit:${panditId}`;
    const acquired = await redis.set(rateLimitKey, "1", "EX", 1, "NX");
    if (!acquired) {
      // Silently drop updates exceeding 1/sec
      return;
    }

    // 2. Write-Through to Redis GEO (Source of Truth for live coords)
    await redis.geoadd("pandits:live", lng, lat, panditId);

    // 3. Broadcast to WebSocket Room
    // Dynamic import to avoid circular dependencies with Socket init
    const { getIO } = await import("./realtime.service.js");
    try {
      getIO().to(`booking:${bookingId}`).emit("pandit:location-update", { bookingId, lat, lng });
    } catch (err) {
      // Ignore emit errors if socket isn't running (e.g. in REST tests)
    }

    // 4. Batch Sync to Postgres (Debounced to once every 30 seconds)
    const syncKey = `tracking:last_pg_sync:${panditId}`;
    const lastSync = await redis.get(syncKey);

    if (!lastSync) {
      // Update Postgres
      await db
        .update(pandits)
        .set({
          location: sql`ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)`,
          updatedAt: new Date(),
        })
        .where(eq(pandits.id, panditId));
      
      // Set lock for 30 seconds
      await redis.setex(syncKey, 30, "1");
    }
  } else {
    // Fallback if Redis is totally down (not ideal for high freq, but prevents complete failure)
    await db
      .update(pandits)
      .set({
        location: sql`ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)`,
        updatedAt: new Date(),
      })
      .where(eq(pandits.id, panditId));
  }
}

/**
 * Retrieves the live location of a Pandit for a specific booking.
 * Fallbacks to Postgres if Redis doesn't have it.
 */
export async function getLiveLocation(bookingId: string, userId: string, role: string) {
  const booking = await db.query.bookings.findFirst({
    where: eq(bookings.id, bookingId),
    columns: { panditId: true, yajmanId: true },
  });

  if (!booking) {
    throw new AppError(404, "NOT_FOUND", "Booking not found");
  }

  // Ownership verification
  if (role === "YAJMAN" && booking.yajmanId !== userId) {
    throw new AppError(403, "FORBIDDEN", "You are not authorized to track this booking");
  }
  if (role === "PANDIT" && booking.panditId !== userId) {
    throw new AppError(403, "FORBIDDEN", "You are not authorized to track this booking");
  }
  
  if (!booking.panditId) {
    throw new AppError(404, "NOT_FOUND", "No Pandit is assigned to this booking yet");
  }

  const redis = await getRedis();
  
  if (redis) {
    // Fetch from Redis for sub-millisecond response
    const positions = await redis.geopos("pandits:live", booking.panditId);
    
    if (positions && positions[0]) {
      const [lng, lat] = positions[0];
      return { lat: parseFloat(lat), lng: parseFloat(lng), source: "redis" };
    }
  }

  // Fallback to Postgres
  const pandit = await db
    .select({
      lat: sql<number>`ST_Y(location::geometry)`,
      lng: sql<number>`ST_X(location::geometry)`,
    })
    .from(pandits)
    .where(eq(pandits.id, booking.panditId))
    .limit(1);

  if (!pandit || pandit.length === 0 || pandit[0].lat === null) {
    return null; // Location unknown
  }

  return { lat: pandit[0].lat, lng: pandit[0].lng, source: "postgres" };
}
