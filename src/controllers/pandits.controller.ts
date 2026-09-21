import type { RequestHandler } from "express";
import { sendSuccess } from "../utils/response.js";
import { AppError } from "../utils/api-error.js";
import { getNearbyPandits, updateDutyStatus, acceptBooking, getPanditDashboard } from "../services/pandits.service.js";

export const getNearbyPanditsHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const query = req.validatedQuery as { lat: number; lng: number; radiusKm: number };
  
  const pandits = await getNearbyPandits(query.lat, query.lng, query.radiusKm);

  sendSuccess(res, { pandits });
};

export const updateDutyStatusHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const body = req.body as { isAvailable: boolean };
  
  const pandit = await updateDutyStatus(req.user.id, body.isAvailable);

  sendSuccess(res, { pandit });
};

export const acceptBookingHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const body = req.body as { bookingId: string };
  
  const booking = await acceptBooking(req.user.id, body.bookingId);

  sendSuccess(res, { booking });
};

export const getPanditDashboardHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }
  
  const dashboard = await getPanditDashboard(req.user.id);

  sendSuccess(res, { dashboard });
};
