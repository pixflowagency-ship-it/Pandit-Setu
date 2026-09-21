import { db, bookings, poojas } from "../db/index.js";
import { eq } from "drizzle-orm";
import { AppError } from "../utils/api-error.js";
import type { CreateBookingInput } from "../validators/bookings.validator.js";
import { getRedis } from "../config/redis.js";
import { createHash } from "crypto";

export async function createBooking(
  yajmanId: string,
  input: CreateBookingInput,
  idempotencyKey?: string,
) {
  let idemHash: string | undefined;
  let redisKey: string | undefined;

  // 1. Idempotency Check
  if (idempotencyKey) {
    idemHash = createHash("sha256").update(idempotencyKey).digest("hex");
    redisKey = `idem:booking:${idemHash}`;

    const redis = await getRedis();
    if (redis) {
      const existingId = await redis.get(redisKey);
      if (existingId) {
        // Return existing booking if found in cache
        const existingBooking = await db.query.bookings.findFirst({
          where: eq(bookings.id, existingId),
          with: { pooja: true }, // assuming relation is set, or we fetch manually
        });
        if (existingBooking) return existingBooking;
      }
    } else {
      // Fallback: Check DB if Redis is down
      const existingBooking = await db.query.bookings.findFirst({
        where: eq(bookings.idempotencyKeyHash, idemHash),
      });
      if (existingBooking) {
        // We'll need to fetch the joined pooja separately since we didn't setup drizzle relations explicitly in the plan
        // Actually, let's just do a manual join or two queries to be safe.
        const pooja = await db.query.poojas.findFirst({
          where: eq(poojas.id, existingBooking.poojaId),
        });
        return { ...existingBooking, pooja };
      }
    }
  }

  // 2. Lookup Pooja
  const pooja = await db.query.poojas.findFirst({
    where: eq(poojas.id, input.poojaId),
  });

  if (!pooja || !pooja.isActive) {
    throw new AppError(404, "NOT_FOUND", "Pooja not found or inactive");
  }

  // 3. Compute Price (Server-side rule)
  let totalAmount = Number(pooja.basePrice);
  let finalSamagriIncluded = false;
  let venueLocation = null;
  let venueAddress = null;

  if (input.mode === "ONLINE") {
    // Online always includes samagri cost, ignore client input
    finalSamagriIncluded = true;
    totalAmount += Number(pooja.samagriPrice);
  } else {
    // IN_PERSON
    finalSamagriIncluded = input.samagriIncluded;
    if (finalSamagriIncluded) {
      totalAmount += Number(pooja.samagriPrice);
    }
    venueAddress = input.venueAddress;
    venueLocation = { lat: input.lat, lng: input.lng }; // geometryPoint handles this format
  }

  // 4. Insert Booking
  const [newBooking] = await db
    .insert(bookings)
    .values({
      yajmanId,
      poojaId: input.poojaId,
      mode: input.mode,
      bookingTime: new Date(input.bookingTime),
      venueLocation,
      venueAddress,
      samagriIncluded: finalSamagriIncluded,
      customNotes: input.customNotes,
      totalAmount: totalAmount.toFixed(2),
      status: "PENDING",
      idempotencyKeyHash: idemHash,
    })
    .returning();

  // 5. Cache Idempotency Key in Redis (24h TTL)
  if (redisKey) {
    const redis = await getRedis();
    if (redis) {
      await redis.set(redisKey, newBooking.id, "EX", 24 * 60 * 60);
    }
  }

  return { ...newBooking, pooja };
}

export async function listBookings(
  userId: string,
  role: string,
  cursor?: string,
  limit: number = 20
) {
  // Determine role-based filter
  let roleFilter = undefined;
  if (role === "YAJMAN") {
    roleFilter = eq(bookings.yajmanId, userId);
  } else if (role === "PANDIT") {
    roleFilter = eq(bookings.panditId, userId);
  } else {
    // Admin gets everything by default, but for now, we'll default to checking either
    // or just let them see all if we don't apply the filter.
    // Let's filter to either YAJMAN or PANDIT for safety if they are somehow both or neither.
    const { or } = await import("drizzle-orm");
    roleFilter = role === "ADMIN" ? undefined : or(eq(bookings.yajmanId, userId), eq(bookings.panditId, userId));
  }

  // Cursor filter
  let cursorFilter = undefined;
  if (cursor) {
    const { lt } = await import("drizzle-orm");
    cursorFilter = lt(bookings.createdAt, new Date(cursor));
  }

  const { and, desc } = await import("drizzle-orm");
  const whereCondition = and(roleFilter, cursorFilter);

  // Fetch limit + 1 to check if there is a next page
  const items = await db.query.bookings.findMany({
    where: whereCondition,
    orderBy: [desc(bookings.createdAt)],
    limit: limit + 1,
    with: {
      pooja: true,
      pandit: {
        columns: {
          name: true,
        },
        with: {
          panditProfile: {
            columns: {
              rating: true,
            },
          },
        },
      },
    },
  });

  let nextCursor: string | null = null;
  if (items.length > limit) {
    const nextItem = items.pop();
    nextCursor = nextItem!.createdAt.toISOString();
  }

  return { items, nextCursor };
}

export async function getBookingById(
  bookingId: string,
  userId: string,
  role: string
) {
  const booking = await db.query.bookings.findFirst({
    where: eq(bookings.id, bookingId),
    with: {
      pooja: true,
      pandit: {
        columns: {
          name: true,
        },
        with: {
          panditProfile: {
            columns: {
              rating: true,
            },
          },
        },
      },
    },
  });

  if (!booking) {
    throw new AppError(404, "NOT_FOUND", "Booking not found");
  }

  // Authorization Check (Rule 3)
  if (
    role !== "ADMIN" &&
    booking.yajmanId !== userId &&
    booking.panditId !== userId
  ) {
    throw new AppError(403, "FORBIDDEN", "You do not have permission to view this booking");
  }

  return booking;
}

export async function cancelBooking(
  bookingId: string,
  userId: string,
  role: string
) {
  const { and } = await import("drizzle-orm");
  const booking = await db.query.bookings.findFirst({
    where: eq(bookings.id, bookingId),
  });

  if (!booking) {
    throw new AppError(404, "NOT_FOUND", "Booking not found");
  }

  // Only Yajman owner or Admin can cancel
  if (role !== "ADMIN" && booking.yajmanId !== userId) {
    throw new AppError(403, "FORBIDDEN", "Only the Yajman or Admin can cancel this booking");
  }

  // Can only cancel from PENDING or CONFIRMED
  if (booking.status !== "PENDING" && booking.status !== "CONFIRMED") {
    throw new AppError(400, "BAD_REQUEST", "Only pending or confirmed bookings can be cancelled");
  }

  // Atomic update to handle concurrency
  const [updatedBooking] = await db.update(bookings)
    .set({ status: "CANCELLED", updatedAt: new Date() })
    .where(and(
      eq(bookings.id, bookingId),
      eq(bookings.status, booking.status)
    ))
    .returning();

  if (!updatedBooking) {
    throw new AppError(409, "CONFLICT", "Booking status was updated by another request. Please refresh.");
  }

  return updatedBooking;
}

export async function updateBookingStatus(
  bookingId: string,
  userId: string,
  expectedStatus: string,
  newStatus: string
) {
  const { and } = await import("drizzle-orm");

  const validTransitions: Record<string, string[]> = {
    PENDING: ["CONFIRMED", "CANCELLED"],
    CONFIRMED: ["IN_PROGRESS", "CANCELLED"],
    IN_PROGRESS: ["COMPLETED"],
  };

  if (!validTransitions[expectedStatus]?.includes(newStatus)) {
    throw new AppError(400, "BAD_REQUEST", `Invalid status transition from ${expectedStatus} to ${newStatus}`);
  }

  const booking = await db.query.bookings.findFirst({
    where: eq(bookings.id, bookingId),
  });

  if (!booking) {
    throw new AppError(404, "NOT_FOUND", "Booking not found");
  }

  // Only assigned Pandit can update status
  if (booking.panditId !== userId) {
    throw new AppError(403, "FORBIDDEN", "Only the assigned Pandit can update the status");
  }

  // Atomic update
  const [updatedBooking] = await db.update(bookings)
    .set({ status: newStatus as any, updatedAt: new Date() }) // cast to any because TS enum type inference via drizzle might complain, but validation passed
    .where(and(
      eq(bookings.id, bookingId),
      eq(bookings.status, expectedStatus as any)
    ))
    .returning();

  if (!updatedBooking) {
    throw new AppError(409, "CONFLICT", "Booking status mismatch or was updated concurrently. Please refresh.");
  }

  return updatedBooking;
}
