import { db } from "../db/index.js";
import { pandits } from "../db/schema/pandits.js";
import { bookings } from "../db/schema/bookings.js";
import { eq, and, inArray, sql } from "drizzle-orm";
import { getRedis } from "../config/redis.js";
import { AppError } from "../utils/api-error.js";
import type { PanditTelemetryInput } from "../validators/tracking.validator.js";

/**
 * Continuous GPS telemetry ingestion for authenticated, approved, on-duty Pandits.
 * Enforces duty check, timestamp freshness, 3s rate-limiting, Redis GEO caching,
 * and real-time Socket.IO emission to assigned devotees.
 */
export async function recordPanditTelemetry(
  panditUserId: string,
  input: PanditTelemetryInput
) {
  const pandit = await db.query.pandits.findFirst({
    where: eq(pandits.userId, panditUserId),
  });

  if (!pandit) {
    throw new AppError(404, "NOT_FOUND", "Pandit profile not found");
  }

  if (pandit.verificationStatus !== "APPROVED" || !pandit.isVerified) {
    throw new AppError(
      403,
      "PANDIT_NOT_APPROVED",
      "Your Pandit profile is not yet approved. Please complete onboarding and verification."
    );
  }

  if (!pandit.isAvailable) {
    throw new AppError(
      400,
      "PANDIT_OFF_DUTY",
      "Telemetry updates are only accepted when Pandit is on duty"
    );
  }

  // Validate timestamp freshness if provided
  if (input.timestamp !== undefined) {
    const timestampMs =
      typeof input.timestamp === "number"
        ? input.timestamp
        : new Date(input.timestamp).getTime();

    if (isNaN(timestampMs)) {
      throw new AppError(400, "INVALID_TIMESTAMP", "Provided timestamp is invalid");
    }

    const now = Date.now();
    // Reject older than 5 minutes (300,000 ms)
    if (now - timestampMs > 5 * 60 * 1000) {
      throw new AppError(
        400,
        "STALE_LOCATION_UPDATE",
        "Location update timestamp is older than 5 minutes"
      );
    }
    // Reject future timestamps > 1 minute
    if (timestampMs - now > 60 * 1000) {
      throw new AppError(
        400,
        "INVALID_TIMESTAMP",
        "Location update timestamp cannot be in the future"
      );
    }
  }

  const { lat, lng, accuracy, heading, speed } = input;
  const now = new Date();
  const redis = await getRedis();

  if (redis) {
    // 1. Strict Server-Side Rate Limiter (1 update per 3 seconds per Pandit)
    const throttleKey = `telemetry:throttle:${pandit.id}`;
    const acquired = await redis.set(throttleKey, "1", "EX", 3, "NX");
    if (!acquired) {
      return {
        status: "THROTTLED",
        message: "Telemetry update rate limit (1 per 3s)",
        panditId: pandit.id,
      };
    }

    // 2. Write-Through to Redis GEO
    await redis.geoadd("pandits:live", lng, lat, pandit.id);

    // 3. Cache latest location metadata with 10-minute TTL
    const locationData = {
      lat,
      lng,
      accuracy,
      heading,
      speed,
      updatedAt: now.toISOString(),
    };
    await redis.set(`pandit:location:${pandit.id}`, JSON.stringify(locationData), "EX", 600);
  }

  // 4. Update Postgres pandits table
  await db
    .update(pandits)
    .set({
      latitude: lat,
      longitude: lng,
      location: sql`ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)`,
      updatedAt: now,
    })
    .where(eq(pandits.id, pandit.id));

  // 5. Emit real-time update to active bookings
  try {
    const activeBookings = await db.query.bookings.findMany({
      where: and(
        eq(bookings.panditId, panditUserId),
        inArray(bookings.status, [
          "CONFIRMED",
          "HEADING_TO_VENUE",
          "ARRIVED",
          "PUJA_STARTED",
          "IN_PROGRESS",
        ])
      ),
      columns: { id: true },
    });

    if (activeBookings.length > 0) {
      const { getIO } = await import("./realtime.service.js");
      const io = getIO();
      for (const b of activeBookings) {
        io.to(`booking:${b.id}`).emit("pandit:location-update", {
          bookingId: b.id,
          panditId: pandit.id,
          lat,
          lng,
          heading,
          speed,
          accuracy,
          updatedAt: now.toISOString(),
        });
      }
    }
  } catch {
    // Non-fatal if socket not running
  }

  return {
    status: "RECORDED",
    panditId: pandit.id,
    lat,
    lng,
    updatedAt: now.toISOString(),
  };
}

/**
 * High-frequency location update processor for specific booking (backward compatible).
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
      return;
    }

    // 2. Write-Through to Redis GEO
    await redis.geoadd("pandits:live", lng, lat, panditId);

    // 3. Broadcast to WebSocket Room
    try {
      const { getIO } = await import("./realtime.service.js");
      getIO().to(`booking:${bookingId}`).emit("pandit:location-update", { bookingId, lat, lng });
    } catch {
      // Non-fatal if socket not running
    }

    // 4. Batch Sync to Postgres
    const syncKey = `tracking:last_pg_sync:${panditId}`;
    const lastSync = await redis.get(syncKey);

    if (!lastSync) {
      await db
        .update(pandits)
        .set({
          location: sql`ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)`,
          updatedAt: new Date(),
        })
        .where(eq(pandits.id, panditId));
      await redis.setex(syncKey, 30, "1");
    }
  } else {
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
 * Retrieves the live or last-known location of a Pandit for a specific booking.
 * Fallbacks to Postgres if Redis does not have fresh coordinates.
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
    // 1. Try reading detailed metadata cache (includes timestamp, accuracy, heading, speed)
    const cachedMeta = await redis.get(`pandit:location:${booking.panditId}`);
    if (cachedMeta) {
      try {
        const parsed = JSON.parse(cachedMeta);
        return { ...parsed, source: "redis" };
      } catch (_) {}
    }

    // 2. Try Redis GEO position using booking.panditId
    const positions = await redis.geopos("pandits:live", booking.panditId);
    if (positions && positions[0]) {
      const [lng, lat] = positions[0];
      return {
        lat: parseFloat(lat),
        lng: parseFloat(lng),
        source: "redis",
      };
    }
  }

  // 3. Fallback to Postgres
  if (db.query?.pandits?.findFirst) {
    const panditProfile = await db.query.pandits.findFirst({
      where: eq(pandits.userId, booking.panditId),
    });
    if (panditProfile && panditProfile.latitude !== null && panditProfile.longitude !== null) {
      return {
        lat: panditProfile.latitude,
        lng: panditProfile.longitude,
        updatedAt: panditProfile.updatedAt?.toISOString() || null,
        source: "postgres",
      };
    }
  }

  return null;
}
