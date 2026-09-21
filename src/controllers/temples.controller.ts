import type { RequestHandler } from "express";
import { sendSuccess } from "../utils/response.js";
import { getNearbyTemples } from "../services/temples.service.js";
import { AppError } from "../utils/api-error.js";

export const getNearbyTemplesHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const query = req.validatedQuery as { lat: number; lng: number; radiusKm: number };
  
  const temples = await getNearbyTemples(query.lat, query.lng, query.radiusKm);

  sendSuccess(res, { temples });
};
