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

export async function updateDutyStatus(
  panditUserId: string,
  isAvailable: boolean,
  lat?: number,
  lng?: number
) {
  const pandit = await db.query.pandits.findFirst({
    where: eq(pandits.userId, panditUserId),
  });

  if (!pandit) {
    throw new AppError(404, "NOT_FOUND", "Pandit profile not found");
  }

  // If attempting to go available, ensure coordinates are provided or already stored
  const hasCoordinates = (lat !== undefined && lng !== undefined) || (pandit.latitude && pandit.longitude);
  if (isAvailable && !hasCoordinates) {
    throw new AppError(400, "BAD_REQUEST", "You must set your location before becoming available.");
  }

  const updateData: Record<string, any> = {
    isAvailable,
    updatedAt: new Date(),
  };

  if (lat !== undefined && lng !== undefined) {
    updateData.latitude = lat;
    updateData.longitude = lng;
    updateData.location = sql`ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)`;
  }

  const [updatedPandit] = await db.update(pandits)
    .set(updateData)
    .where(eq(pandits.id, pandit.id))
    .returning();

  // Sync with Redis Geo index
  const redis = await getRedis();
  if (redis) {
    const geoKey = "pandits:live";
    const finalLat = lat ?? updatedPandit.latitude;
    const finalLng = lng ?? updatedPandit.longitude;

    if (isAvailable && finalLat && finalLng) {
      await redis.geoadd(geoKey, finalLng, finalLat, updatedPandit.id);
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

  if (pandit.verificationStatus !== "APPROVED" || !pandit.isVerified) {
    throw new AppError(
      403,
      "PANDIT_NOT_APPROVED",
      "Your Pandit profile is not yet approved. Please complete onboarding and verification."
    );
  }

  // To prevent circular import dependencies if bookings.ts imports pandits.ts
  const { bookings } = await import("../db/schema/bookings.js");

  // Verify booking exists before attempting update
  const existingBooking = await db.query.bookings.findFirst({
    where: eq(bookings.id, bookingId),
  });

  if (!existingBooking) {
    throw new AppError(404, "NOT_FOUND", "Booking not found");
  }

  // Idempotent: If this authenticated pandit already accepted this booking, return it cleanly
  if (existingBooking.panditId === panditUserId && existingBooking.status === "CONFIRMED") {
    return existingBooking;
  }

  // Check if already assigned to another Pandit
  if (existingBooking.panditId && existingBooking.panditId !== panditUserId) {
    throw new AppError(409, "CONFLICT", "BOOKING_ALREADY_TAKEN");
  }

  // Verify booking status eligibility (must be PENDING)
  if (existingBooking.status !== "PENDING") {
    if (["CONFIRMED", "HEADING_TO_VENUE", "ARRIVED", "PUJA_STARTED", "IN_PROGRESS", "COMPLETED"].includes(existingBooking.status)) {
      throw new AppError(409, "CONFLICT", "BOOKING_ALREADY_TAKEN");
    }
    if (existingBooking.status === "CANCELLED") {
      throw new AppError(400, "BAD_REQUEST", "BOOKING_ALREADY_CANCELLED: Cannot accept a cancelled booking");
    }
    throw new AppError(400, "BAD_REQUEST", `BOOKING_INELIGIBLE: Booking status is ${existingBooking.status}`);
  }

  // Atomic conditional update with PostgreSQL row-level locks
  const [updatedBooking] = await db.update(bookings)
    .set({ 
      panditId: panditUserId, // Note: bookings.panditId is a FK to users.id, which matches panditUserId
      status: "CONFIRMED", 
      updatedAt: new Date() 
    })
    .where(and(
      eq(bookings.id, bookingId),
      eq(bookings.status, "PENDING"),
      sql`${bookings.panditId} IS NULL`
    ))
    .returning();

  if (!updatedBooking) {
    // Another concurrent transaction won the assignment race in PostgreSQL
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

export async function declineBooking(
  panditUserId: string,
  bookingId: string,
  reason: "TOO_FAR" | "BUSY" | "SCHEDULE_CONFLICT" | "OTHER" = "OTHER",
  notes?: string
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

  const { bookings } = await import("../db/schema/bookings.js");
  const { bookingDeclines } = await import("../db/schema/booking_declines.js");

  // Verify booking exists before attempting decline
  const booking = await db.query.bookings.findFirst({
    where: eq(bookings.id, bookingId),
  });

  if (!booking) {
    throw new AppError(404, "NOT_FOUND", "Booking not found");
  }

  // Check booking eligibility
  if (booking.status === "CANCELLED") {
    throw new AppError(400, "BAD_REQUEST", "BOOKING_ALREADY_CANCELLED: Cannot decline a cancelled booking");
  }
  if (booking.status === "COMPLETED") {
    throw new AppError(400, "BAD_REQUEST", "BOOKING_INELIGIBLE: Cannot decline a completed booking");
  }
  if (booking.panditId === panditUserId) {
    throw new AppError(400, "BAD_REQUEST", "BOOKING_ALREADY_ACCEPTED: Cannot decline an already accepted booking");
  }
  if (booking.panditId !== null && booking.panditId !== panditUserId) {
    throw new AppError(409, "CONFLICT", "BOOKING_ALREADY_TAKEN");
  }

  // Check if already declined by this Pandit (Idempotent)
  const existingDecline = await db.query.bookingDeclines.findFirst({
    where: and(
      eq(bookingDeclines.bookingId, bookingId),
      eq(bookingDeclines.panditId, panditUserId)
    ),
  });

  let declineRecord = existingDecline;

  if (!declineRecord) {
    const [created] = await db.insert(bookingDeclines)
      .values({
        bookingId,
        panditId: panditUserId,
        reason: reason || "OTHER",
        notes,
      })
      .onConflictDoNothing()
      .returning();

    declineRecord = created || (await db.query.bookingDeclines.findFirst({
      where: and(
        eq(bookingDeclines.bookingId, bookingId),
        eq(bookingDeclines.panditId, panditUserId)
      ),
    }));
  }

  // Fast Redis caching for dispatch candidate filtering
  try {
    const redis = await getRedis();
    if (redis) {
      await redis.set(`dispatch:declined:${bookingId}:${pandit.id}`, "1", "EX", 86400);
      await redis.set(`dispatch:notified:${bookingId}:${pandit.id}`, "1", "EX", 86400);
    }
  } catch (_) {}

  return declineRecord;
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
    isAvailable: pandit.isAvailable ?? false,
    todayCount,
    totalEarnings: totalEarnings.toFixed(2),
    rating: pandit.rating || "0.00",
    pendingRequests,
  };
}

