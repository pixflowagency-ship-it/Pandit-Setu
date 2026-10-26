import { randomUUID } from "crypto";
import { eq, and, sql, or, inArray } from "drizzle-orm";
import { db, bookings, pandits, poojas, bookingDeclines } from "../db/index.js";
import { getRedis } from "../config/redis.js";
import { getIO } from "./realtime.service.js";
import { logger } from "../utils/logger.js";

export interface DispatchOptions {
  searchRadiusKm?: number;
  maxLocationAgeMs?: number;
  dryRun?: boolean;
}

export interface DispatchNotificationPayload {
  bookingId: string;
  poojaId: string;
  poojaName: string;
  bookingTime: string;
  mode: "IN_PERSON" | "ONLINE";
  venueAddress?: string;
  approximateDistanceKm?: number;
  samagriIncluded: boolean;
  totalAmount: string;
  expiresAt: string;
  dispatchAttemptId: string;
}

export interface DispatchResult {
  success: boolean;
  bookingId: string;
  dispatchAttemptId: string;
  candidateCount: number;
  eligibleCount: number;
  notifiedCount: number;
  notifiedPandits: Array<{
    panditId: string;
    userId: string;
    distanceKm?: number;
  }>;
  reason?: string;
  error?: string;
}

/**
 * Calculates Great-Circle distance using Haversine formula
 */
export function calculateHaversineDistanceKm(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371; // Earth's mean radius in km
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

/**
 * Anonymizes precise venue address for dispatch alert broadcast to protect Yajman privacy.
 * E.g., "Flat 402, Lotus Greens, Sector 78 Noida" -> "Lotus Greens, Sector 78 Noida"
 */
function sanitizeAddressForAlert(address?: string | null): string | undefined {
  if (!address) return undefined;
  // If address has multiple commas, strip leading unit/flat number
  const parts = address.split(",").map((s) => s.trim());
  if (parts.length > 1 && /^(flat|house|plot|room|apt|h\.no|#|\d+)/i.test(parts[0])) {
    return parts.slice(1).join(", ");
  }
  return address;
}

/**
 * Real Pooja Request Dispatch Engine:
 * Discovers nearby available, approved Pandits and emits targeted Socket.IO events.
 */
export async function dispatchBooking(
  bookingId: string,
  options: DispatchOptions = {}
): Promise<DispatchResult> {
  const dispatchAttemptId = randomUUID();
  const searchRadiusKm = options.searchRadiusKm ?? 15;
  const maxLocationAgeMs = options.maxLocationAgeMs ?? 10 * 60 * 1000; // 10 minutes freshness threshold
  const redis = await getRedis();

  logger.info({ bookingId, dispatchAttemptId }, "Starting Pooja request dispatch attempt");

  // 1. Fetch Authoritative Booking Record
  const booking = await db.query.bookings.findFirst({
    where: eq(bookings.id, bookingId),
    with: { pooja: true },
  });

  if (!booking) {
    logger.warn({ bookingId, dispatchAttemptId }, "Dispatch rejected: Booking not found");
    return {
      success: false,
      bookingId,
      dispatchAttemptId,
      candidateCount: 0,
      eligibleCount: 0,
      notifiedCount: 0,
      notifiedPandits: [],
      reason: "BOOKING_NOT_FOUND",
    };
  }

  // 2. Lifecycle State & Assignment Checks
  if (booking.status !== "PENDING") {
    logger.warn(
      { bookingId, status: booking.status, dispatchAttemptId },
      "Dispatch rejected: Booking status is not PENDING"
    );
    return {
      success: false,
      bookingId,
      dispatchAttemptId,
      candidateCount: 0,
      eligibleCount: 0,
      notifiedCount: 0,
      notifiedPandits: [],
      reason: `INELIGIBLE_STATUS_${booking.status}`,
    };
  }

  if (booking.panditId) {
    logger.warn(
      { bookingId, panditId: booking.panditId, dispatchAttemptId },
      "Dispatch rejected: Booking already assigned"
    );
    return {
      success: false,
      bookingId,
      dispatchAttemptId,
      candidateCount: 0,
      eligibleCount: 0,
      notifiedCount: 0,
      notifiedPandits: [],
      reason: "ALREADY_ASSIGNED",
    };
  }

  // 3. Location Validity Check for IN_PERSON Bookings
  let venueLat: number | undefined;
  let venueLng: number | undefined;

  if (booking.mode === "IN_PERSON") {
    if (booking.venueLocation && typeof booking.venueLocation === "object") {
      venueLat = booking.venueLocation.lat;
      venueLng = booking.venueLocation.lng;
    }

    if (
      venueLat === undefined ||
      venueLng === undefined ||
      isNaN(venueLat) ||
      isNaN(venueLng) ||
      venueLat < -90 ||
      venueLat > 90 ||
      venueLng < -180 ||
      venueLng > 180
    ) {
      logger.warn(
        { bookingId, venueLocation: booking.venueLocation, dispatchAttemptId },
        "Dispatch rejected: IN_PERSON booking lacks valid geographic coordinates"
      );
      return {
        success: false,
        bookingId,
        dispatchAttemptId,
        candidateCount: 0,
        eligibleCount: 0,
        notifiedCount: 0,
        notifiedPandits: [],
        reason: "MISSING_OR_INVALID_VENUE_COORDINATES",
      };
    }
  }

  // 4. Distributed Concurrency Lock via Redis
  const lockKey = `dispatch:lock:${bookingId}`;
  let lockAcquired = false;

  if (redis) {
    try {
      const lockRes = await redis.set(lockKey, dispatchAttemptId, "EX", 15, "NX");
      lockAcquired = lockRes === "OK";
    } catch (err) {
      logger.warn({ err, bookingId }, "Redis lock acquisition failed, proceeding defensively");
      lockAcquired = true;
    }
  } else {
    lockAcquired = true;
  }

  if (!lockAcquired) {
    logger.warn({ bookingId, dispatchAttemptId }, "Dispatch rejected: Concurrent dispatch in progress");
    return {
      success: false,
      bookingId,
      dispatchAttemptId,
      candidateCount: 0,
      eligibleCount: 0,
      notifiedCount: 0,
      notifiedPandits: [],
      reason: "CONCURRENT_DISPATCH_IN_PROGRESS",
    };
  }

  try {
    // 5. Candidate Discovery
    let candidatePanditIds: string[] = [];

    if (booking.mode === "IN_PERSON" && venueLat !== undefined && venueLng !== undefined) {
      // Step 5A: Try Redis GEO discovery
      if (redis) {
        try {
          const rawMembers = await redis.georadius(
            "pandits:live",
            venueLng,
            venueLat,
            searchRadiusKm,
            "km"
          );
          if (Array.isArray(rawMembers)) {
            candidatePanditIds = rawMembers.map((m: any) => (typeof m === "string" ? m : m[0]));
          }
        } catch (err) {
          logger.warn({ err, bookingId }, "Redis GEORADIUS query failed, falling back to PostGIS");
        }
      }

      // Step 5B: PostGIS Fallback if Redis returned 0 or failed
      if (candidatePanditIds.length === 0) {
        const radiusMeters = searchRadiusKm * 1000;
        const point = sql`ST_SetSRID(ST_MakePoint(${venueLng}, ${venueLat}), 4326)`;

        const postgisCandidates = await db.query.pandits.findMany({
          where: (p, { eq, and }) =>
            and(
              eq(p.isAvailable, true),
              eq(p.isVerified, true),
              eq(p.verificationStatus, "APPROVED"),
              sql`ST_DWithin(${p.location}, ${point}, ${radiusMeters})`
            ),
          columns: { id: true },
        });

        candidatePanditIds = postgisCandidates.map((p) => p.id);
      }
    } else {
      // ONLINE Mode: Any available, approved Pandit
      const onlineCandidates = await db.query.pandits.findMany({
        where: (p, { eq, and }) =>
          and(
            eq(p.isAvailable, true),
            eq(p.isVerified, true),
            eq(p.verificationStatus, "APPROVED")
          ),
        columns: { id: true },
      });

      candidatePanditIds = onlineCandidates.map((p) => p.id);
    }

    const candidateCount = candidatePanditIds.length;
    logger.debug({ bookingId, candidateCount, candidatePanditIds }, "Discovered initial candidates");

    if (candidateCount === 0) {
      logger.info({ bookingId, dispatchAttemptId }, "Dispatch outcome: No candidate Pandits discovered");
      return {
        success: false,
        bookingId,
        dispatchAttemptId,
        candidateCount: 0,
        eligibleCount: 0,
        notifiedCount: 0,
        notifiedPandits: [],
        reason: "NO_CANDIDATES_AVAILABLE",
      };
    }

    // 6. Authoritative Database Eligibility Validation
    // Query authoritative records from DB for all candidate IDs
    const dbCandidates = await db.query.pandits.findMany({
      where: (p, { inArray }) => inArray(p.id, candidatePanditIds),
      with: {
        user: {
          columns: {
            id: true,
            name: true,
            phone: true,
          },
        },
      },
    });

    // Query persistent declines for this booking to prevent re-notifying pandits who declined
    const persistentDeclines = await db.query.bookingDeclines.findMany({
      where: eq(bookingDeclines.bookingId, bookingId),
      columns: { panditId: true },
    });
    const declinedPanditUserIds = new Set(persistentDeclines.map((d) => d.panditId));

    const now = Date.now();
    const eligiblePandits: Array<{
      panditId: string;
      userId: string;
      distanceKm?: number;
    }> = [];

    for (const cand of dbCandidates) {
      // Rule 0: Persistent Decline Check (Pandit who previously declined active booking will not receive retry dispatch)
      if (declinedPanditUserIds.has(cand.userId)) {
        logger.debug(
          { bookingId, panditId: cand.id, userId: cand.userId },
          "Excluding candidate: Pandit previously declined this booking"
        );
        continue;
      }

      // Rule 1: Approval Status
      if (!cand.isVerified || cand.verificationStatus !== "APPROVED") {
        continue;
      }

      // Rule 2: Current PostgreSQL Availability
      if (!cand.isAvailable) {
        continue;
      }

      // Rule 3: Yajman Exclusion (Pandit cannot be assigned to their own booking)
      if (cand.userId === booking.yajmanId) {
        continue;
      }

      // Rule 4: Valid Coordinates for IN_PERSON
      if (booking.mode === "IN_PERSON") {
        if (
          cand.latitude === null ||
          cand.longitude === null ||
          cand.latitude === undefined ||
          cand.longitude === undefined
        ) {
          continue;
        }

        // Rule 5: Location Freshness Check
        const lastUpdatedMs = cand.updatedAt ? new Date(cand.updatedAt).getTime() : 0;
        if (now - lastUpdatedMs > maxLocationAgeMs) {
          continue;
        }

        // Rule 6: Service Radius Check
        const distKm = calculateHaversineDistanceKm(
          cand.latitude,
          cand.longitude,
          venueLat!,
          venueLng!
        );

        const maxAllowedRadius = cand.serviceRadiusKm || searchRadiusKm;
        if (distKm > maxAllowedRadius) {
          continue;
        }

        // Rule 7: Busy / Conflicting Booking Check
        // Exclude pandits who already have an active/in-progress booking or a CONFIRMED booking around this time
        const conflictingBooking = await db.query.bookings.findFirst({
          where: and(
            eq(bookings.panditId, cand.userId),
            or(
              inArray(bookings.status, [
                "IN_PROGRESS",
                "HEADING_TO_VENUE",
                "ARRIVED",
                "PUJA_STARTED",
              ]),
              and(
                eq(bookings.status, "CONFIRMED"),
                sql`ABS(EXTRACT(EPOCH FROM (${bookings.bookingTime} - ${booking.bookingTime}::timestamp with time zone))) < 7200`
              )
            )
          ),
          columns: { id: true },
        });

        if (conflictingBooking) {
          continue;
        }

        eligiblePandits.push({
          panditId: cand.id,
          userId: cand.userId,
          distanceKm: distKm,
        });
      } else {
        // ONLINE Mode: No geographic distance constraint
        const conflictingBooking = await db.query.bookings.findFirst({
          where: and(
            eq(bookings.panditId, cand.userId),
            or(
              inArray(bookings.status, [
                "IN_PROGRESS",
                "HEADING_TO_VENUE",
                "ARRIVED",
                "PUJA_STARTED",
              ]),
              and(
                eq(bookings.status, "CONFIRMED"),
                sql`ABS(EXTRACT(EPOCH FROM (${bookings.bookingTime} - ${booking.bookingTime}::timestamp with time zone))) < 7200`
              )
            )
          ),
          columns: { id: true },
        });

        if (conflictingBooking) {
          continue;
        }

        eligiblePandits.push({
          panditId: cand.id,
          userId: cand.userId,
        });
      }
    }

    const eligibleCount = eligiblePandits.length;
    logger.info(
      { bookingId, candidateCount, eligibleCount, dispatchAttemptId },
      "Eligibility verification complete"
    );

    if (eligibleCount === 0) {
      return {
        success: false,
        bookingId,
        dispatchAttemptId,
        candidateCount,
        eligibleCount: 0,
        notifiedCount: 0,
        notifiedPandits: [],
        reason: "NO_ELIGIBLE_PANDITS_AFTER_FILTERING",
      };
    }

    // 7. Emit Targeted Notifications
    const notifiedPandits: Array<{
      panditId: string;
      userId: string;
      distanceKm?: number;
    }> = [];

    let io: ReturnType<typeof getIO> | null = null;
    try {
      io = getIO();
    } catch (err) {
      logger.warn({ err }, "Socket.IO not initialized or running in headless mode");
    }

    for (const eligible of eligiblePandits) {
      // Deduplication check: Avoid notifying the same Pandit multiple times within 5 minutes for the same booking
      if (redis) {
        const notifKey = `dispatch:notified:${bookingId}:${eligible.panditId}`;
        const alreadyNotified = await redis.get(notifKey);
        if (alreadyNotified) {
          continue;
        }
      }

      const payload: DispatchNotificationPayload = {
        bookingId: booking.id,
        poojaId: booking.poojaId,
        poojaName: (booking.pooja as any)?.title || (booking.pooja as any)?.name || "Sacred Pooja Ritual",
        bookingTime: booking.bookingTime.toISOString(),
        mode: booking.mode,
        venueAddress: sanitizeAddressForAlert(booking.venueAddress),
        approximateDistanceKm:
          eligible.distanceKm !== undefined
            ? parseFloat(eligible.distanceKm.toFixed(1))
            : undefined,
        samagriIncluded: booking.samagriIncluded,
        totalAmount: booking.totalAmount,
        expiresAt: new Date(now + 60 * 1000).toISOString(), // 60s response window
        dispatchAttemptId,
      };

      if (!options.dryRun && io) {
        try {
          // Emit strictly to authenticated pandit user room
          io.to(`pandit:user:${eligible.userId}`).emit("booking:new-request", payload);
          io.to(`user:${eligible.userId}`).emit("booking:new-request", payload);
        } catch (emitErr) {
          logger.warn({ emitErr, userId: eligible.userId }, "Socket.IO emission failed for candidate");
        }
      }

      notifiedPandits.push(eligible);

      // Record notification deduplication in Redis with 300-second TTL
      if (redis) {
        await redis.set(`dispatch:notified:${bookingId}:${eligible.panditId}`, "1", "EX", 300);
      }
    }

    const notifiedCount = notifiedPandits.length;
    logger.info(
      {
        bookingId,
        dispatchAttemptId,
        candidateCount,
        eligibleCount,
        notifiedCount,
      },
      "Pooja dispatch attempt finished successfully"
    );

    return {
      success: notifiedCount > 0,
      bookingId,
      dispatchAttemptId,
      candidateCount,
      eligibleCount,
      notifiedCount,
      notifiedPandits,
      reason: notifiedCount > 0 ? "SUCCESS" : "ALL_CANDIDATES_ALREADY_NOTIFIED",
    };
  } finally {
    // Release distributed lock
    if (redis) {
      try {
        await redis.del(lockKey);
      } catch (_) {}
    }
  }
}
