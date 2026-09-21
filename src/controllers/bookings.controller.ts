import type { RequestHandler } from "express";
import { sendSuccess } from "../utils/response.js";
import { AppError } from "../utils/api-error.js";
import type { CreateBookingInput } from "../validators/bookings.validator.js";
import { createBooking, listBookings, getBookingById, cancelBooking, updateBookingStatus } from "../services/bookings.service.js";

export const createBookingHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const input = req.body as CreateBookingInput;
  const idempotencyKey = req.headers["idempotency-key"] as string | undefined;

  const booking = await createBooking(req.user.id, input, idempotencyKey);

  // Return 201 Created
  sendSuccess(res, { booking }, 201);
};

export const listBookingsHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const query = req.validatedQuery as { cursor?: string; limit: number };
  const { items, nextCursor } = await listBookings(
    req.user.id,
    req.user.role,
    query.cursor,
    query.limit
  );

  sendSuccess(res, { items, nextCursor });
};

export const getBookingHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const params = req.validatedParams as { id: string };
  const booking = await getBookingById(params.id, req.user.id, req.user.role);

  sendSuccess(res, { booking });
};

export const cancelBookingHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const params = req.validatedParams as { id: string };
  const booking = await cancelBooking(params.id, req.user.id, req.user.role);

  sendSuccess(res, { booking });
};

export const updateBookingStatusHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const params = req.validatedParams as { id: string };
  const body = req.body as { expectedStatus: string; newStatus: string };
  const booking = await updateBookingStatus(
    params.id,
    req.user.id,
    body.expectedStatus,
    body.newStatus
  );

  // Phase 9 Realtime Service Integration
  import("../services/realtime.service.js").then(({ getIO }) => {
    try {
      getIO().to(`booking:${booking.id}`).emit("booking:status-change", { status: body.newStatus });
    } catch (err) {
      console.warn("Socket.io emit failed (server might be running tests without socket init):", err);
    }
  });

  // Phase 8 Notification Service Integration (Fire-and-forget)
  import("../services/notification.service.js").then(({ sendPush }) => {
    if (body.newStatus === "IN_PROGRESS") {
      sendPush(
        booking.yajmanId,
        "Pandit Arriving",
        "Your Pandit is on the way for the Pooja.",
        { bookingId: booking.id }
      ).catch(console.error);
    } else if (body.newStatus === "COMPLETED") {
      sendPush(
        booking.yajmanId,
        "Pooja Completed",
        "Your Pooja has been successfully completed. Har Har Mahadev!",
        { bookingId: booking.id }
      ).catch(console.error);
    }
  }).catch(console.error);

  sendSuccess(res, { booking });
};

export const generateVideoTokenHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const { id } = req.validatedParams as { id: string };

  const { poojas } = await import("../db/schema/poojas.js");
  const { eq } = await import("drizzle-orm");
  const { bookings } = await import("../db/schema/bookings.js");
  const { db } = await import("../db/index.js");

  const booking = await db
    .select({
      id: bookings.id,
      status: bookings.status,
      yajmanId: bookings.yajmanId,
      panditId: bookings.panditId,
      durationMinutes: poojas.durationMinutes,
    })
    .from(bookings)
    .innerJoin(poojas, eq(bookings.poojaId, poojas.id))
    .where(eq(bookings.id, id))
    .limit(1)
    .then((results: any[]) => results[0]);

  if (!booking) {
    throw new AppError(404, "NOT_FOUND", "Booking not found");
  }

  if (booking.yajmanId !== req.user.id && booking.panditId !== req.user.id) {
    throw new AppError(403, "FORBIDDEN", "You are not authorized to join this booking's video call");
  }

  if (booking.status !== "CONFIRMED" && booking.status !== "IN_PROGRESS") {
    throw new AppError(403, "FORBIDDEN", "Video calls are only allowed for active bookings");
  }

  const { generateRtcToken } = await import("../services/agora.service.js");
  const { RtcRole } = await import("agora-token");

  const channelName = `booking_${booking.id}`;
  
  // Expiration: Current time + duration + 30 mins buffer (in seconds)
  const currentTimestamp = Math.floor(Date.now() / 1000);
  const durationSeconds = (booking.durationMinutes || 60) * 60; // Default 1 hour if not specified
  const expireTimestamp = currentTimestamp + durationSeconds + 1800; 

  const token = generateRtcToken(channelName, RtcRole.PUBLISHER, expireTimestamp);

  sendSuccess(res, { token, channelName });
};
