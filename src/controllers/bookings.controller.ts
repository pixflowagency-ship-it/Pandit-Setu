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

  // Trigger background dispatch to eligible Pandits without blocking HTTP 201 response
  import("../services/dispatch.service.js").then(({ dispatchBooking }) => {
    dispatchBooking(booking.id).catch((err) => {
      console.error("Background booking dispatch failed:", err);
    });
  });

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
      const statusPayload = {
        bookingId: booking.id,
        status: booking.status,
        timestamp: new Date().toISOString(),
      };
      const io = getIO();
      io.to(`booking:${booking.id}`).emit("booking:status-change", statusPayload);
      io.to(`booking:${booking.id}`).emit("booking:status-changed", statusPayload);
      io.to(`user:${booking.yajmanId}`).emit("booking:status-change", statusPayload);
      if (booking.panditId) {
        io.to(`user:${booking.panditId}`).emit("booking:status-change", statusPayload);
      }
    } catch (err) {
      console.warn("Socket.io emit failed (server might be running tests without socket init):", err);
    }
  });

  // Phase 8 Notification Service Integration (Fire-and-forget)
  import("../services/notification.service.js").then(({ sendPush }) => {
    if (body.newStatus === "HEADING_TO_VENUE") {
      sendPush(
        booking.yajmanId,
        "Pandit En Route",
        "Your Pandit Ji is on the way to the venue.",
        { bookingId: booking.id }
      ).catch(console.error);
    } else if (body.newStatus === "ARRIVED") {
      sendPush(
        booking.yajmanId,
        "Pandit Arrived",
        "Your Pandit Ji has arrived at the venue.",
        { bookingId: booking.id }
      ).catch(console.error);
    } else if (body.newStatus === "PUJA_STARTED") {
      sendPush(
        booking.yajmanId,
        "Pooja Commenced",
        "Sacred sankalpa and rituals have commenced.",
        { bookingId: booking.id }
      ).catch(console.error);
    } else if (body.newStatus === "IN_PROGRESS") {
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

  const activeStatuses = ["CONFIRMED", "HEADING_TO_VENUE", "ARRIVED", "PUJA_STARTED", "IN_PROGRESS"];
  if (!activeStatuses.includes(booking.status)) {
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

export const dispatchBookingHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const params = req.validatedParams as { id: string };
  const { dispatchBooking } = await import("../services/dispatch.service.js");
  const result = await dispatchBooking(params.id);

  sendSuccess(res, { dispatch: result });
};

export const collectCashDakshinaHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const params = req.validatedParams as { id: string };
  const { collectCashDakshina } = await import("../services/dakshina.service.js");
  const result = await collectCashDakshina(params.id, req.user.id, req.body);

  sendSuccess(res, result);
};

export const createDakshinaOrderHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const params = req.validatedParams as { id: string };
  const { createDakshinaOrder } = await import("../services/dakshina.service.js");
  const result = await createDakshinaOrder(params.id, req.user.id, req.body);

  sendSuccess(res, result);
};

export const verifyDakshinaPaymentHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const params = req.validatedParams as { id: string };
  const { verifyDakshinaPayment } = await import("../services/dakshina.service.js");
  const result = await verifyDakshinaPayment(params.id, req.user.id, req.body);

  sendSuccess(res, result);
};

export const getDakshinaStatusHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const params = req.validatedParams as { id: string };
  const { getDakshinaStatus } = await import("../services/dakshina.service.js");
  const result = await getDakshinaStatus(params.id, req.user.id);

  sendSuccess(res, result);
};

