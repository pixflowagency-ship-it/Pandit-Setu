import { eq, and, sql, asc } from "drizzle-orm";
import { db } from "../db/index.js";
import { pandits } from "../db/schema/pandits.js";
import { AppError } from "../utils/api-error.js";
import { getRedis } from "../config/redis.js";

export async function getNearbyPandits(lat: number, lng: number, radiusKm: number) {
  const radiusMeters = radiusKm * 1000;
  
  // Create a PostGIS point with SRID 4326 (WGS 84) using bound parameters
  const point = sql`ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)`;

  // Note: we can map the distance column into an extra field for sorting, or just order by it.
  // We'll use orderBy and let drizzle handle the query.
  const nearby = await db.query.pandits.findMany({
    where: (pandits, { eq, and }) => and(
      eq(pandits.isAvailable, true),
      eq(pandits.isVerified, true),
      sql`ST_DWithin(${pandits.location}, ${point}, ${radiusMeters})`
    ),
    orderBy: (pandits) => [asc(sql`ST_Distance(${pandits.location}, ${point})`)],
    limit: 20,
    with: {
      user: {
        columns: {
          id: true,
          name: true,
          phone: true,
          profilePictureUrl: true,
        }
      }
    }
  });

  return nearby;
}

export async function updateDutyStatus(panditUserId: string, isAvailable: boolean) {
  const pandit = await db.query.pandits.findFirst({
    where: eq(pandits.userId, panditUserId),
  });

  if (!pandit) {
    throw new AppError(404, "NOT_FOUND", "Pandit profile not found");
  }

  // If attempting to go available, ensure they have location coordinates
  if (isAvailable && (!pandit.latitude || !pandit.longitude)) {
    throw new AppError(400, "BAD_REQUEST", "You must set your location before becoming available.");
  }

  const [updatedPandit] = await db.update(pandits)
    .set({ isAvailable, updatedAt: new Date() })
    .where(eq(pandits.id, pandit.id))
    .returning();

  // Sync with Redis Geo index
  const redis = await getRedis();
  if (redis) {
    const geoKey = "pandits:live";
    if (isAvailable && updatedPandit.longitude && updatedPandit.latitude) {
      await redis.geoadd(geoKey, updatedPandit.longitude, updatedPandit.latitude, updatedPandit.id);
    } else {
      await redis.zrem(geoKey, updatedPandit.id);
    }
  }

  return updatedPandit;
}

export async function acceptBooking(panditUserId: string, bookingId: string) {
  const pandit = await db.query.pandits.findFirst({
    where: eq(pandits.userId, panditUserId),
  });

  if (!pandit) {
    throw new AppError(404, "NOT_FOUND", "Pandit profile not found");
  }

  // To prevent circular import dependencies if bookings.ts imports pandits.ts
  // it's safer to import it locally or from index.js here
  const { bookings } = await import("../db/schema/bookings.js");

  // Atomic update to prevent race conditions
  const [updatedBooking] = await db.update(bookings)
    .set({ 
      panditId: panditUserId, // Note: bookings.panditId is a FK to users.id, which matches panditUserId
      status: "CONFIRMED", 
      updatedAt: new Date() 
    })
    .where(and(
      eq(bookings.id, bookingId),
      eq(bookings.status, "PENDING")
    ))
    .returning();

  if (!updatedBooking) {
    throw new AppError(409, "CONFLICT", "BOOKING_ALREADY_TAKEN");
  }

  // Phase 8 Notification Service Integration
  const { sendPush } = await import("./notification.service.js");
  sendPush(
    updatedBooking.yajmanId,
    "Booking Confirmed",
    "A Pandit has accepted your booking and is on the way to help you.",
    { bookingId: updatedBooking.id }
  ).catch(console.error);

  return updatedBooking;
}

export async function getPanditDashboard(panditUserId: string) {
  const { bookings } = await import("../db/schema/bookings.js");

  const pandit = await db.query.pandits.findFirst({
    where: eq(pandits.userId, panditUserId),
  });

  if (!pandit) {
    throw new AppError(404, "NOT_FOUND", "Pandit profile not found");
  }

  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);

  // 1. Today's booking count
  // 2. Earnings summary (COMPLETED bookings)
  const allPanditBookings = await db.query.bookings.findMany({
    where: eq(bookings.panditId, panditUserId),
  });

  let todayCount = 0;
  let totalEarnings = 0;

  for (const b of allPanditBookings) {
    if (new Date(b.bookingTime) >= startOfDay) {
      todayCount++;
    }
    if (b.status === "COMPLETED") {
      totalEarnings += parseFloat(b.totalAmount.toString());
    }
  }

  // 3. Pending requests within radius (or ONLINE)
  const radiusMeters = (pandit.serviceRadiusKm || 15) * 1000;
  let point: ReturnType<typeof sql> | null = null;
  if (pandit.longitude && pandit.latitude) {
    point = sql`ST_SetSRID(ST_MakePoint(${pandit.longitude}, ${pandit.latitude}), 4326)`;
  }

  const { or } = await import("drizzle-orm");

  const pendingRequests = await db.query.bookings.findMany({
    where: (bookings, { eq, and }) => and(
      eq(bookings.status, "PENDING"),
      or(
        eq(bookings.mode, "ONLINE"), // ONLINE doesn't need physical proximity
        point ? sql`ST_DWithin(${bookings.venueLocation}, ${point}, ${radiusMeters})` : sql`1=0` // if no location, can't match IN_PERSON
      )
    ),
    with: {
      pooja: true
    }
  });

  return {
    todayCount,
    totalEarnings: totalEarnings.toFixed(2),
    rating: pandit.rating || "0.00",
    pendingRequests,
  };
}
