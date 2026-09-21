import { Router } from "express";
import { verifyToken } from "../middleware/verify-token.js";
import { asyncHandler, validateQuery } from "../middleware/async-handler.js";
import { getNearbyTemplesHandler } from "../controllers/temples.controller.js";
import { nearbyTemplesSchema } from "../validators/temples.validator.js";
import { placesApiLimiter } from "../middleware/rate-limit.js";

const templesRouter = Router();

templesRouter.get(
  "/nearby",
  placesApiLimiter,
  verifyToken,
  validateQuery(nearbyTemplesSchema),
  asyncHandler(getNearbyTemplesHandler)
);

export default templesRouter;
