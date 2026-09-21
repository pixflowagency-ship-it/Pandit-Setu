import type { RequestHandler } from "express";
import { sendSuccess } from "../utils/response.js";
import { AppError } from "../utils/api-error.js";
import { processLocationUpdate, getLiveLocation } from "../services/tracking.service.js";
import type { UpdateLocationInput } from "../validators/tracking.validator.js";

export const updateLocationHandler: RequestHandler = async (req, res) => {
  if (!req.user || req.user.role !== "PANDIT") {
    throw new AppError(403, "FORBIDDEN", "Only pandits can update tracking location");
  }

  const { lat, lng } = req.body as UpdateLocationInput;
  const { bookingId } = req.validatedParams as { bookingId: string };

  await processLocationUpdate(req.user.id, bookingId, lat, lng);

  sendSuccess(res, { message: "Location updated successfully" });
};

export const getLocationHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const { bookingId } = req.validatedParams as { bookingId: string };

  const location = await getLiveLocation(bookingId, req.user.id, req.user.role);

  sendSuccess(res, { location });
};
