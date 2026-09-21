import { Router } from "express";
import { verifyToken, requireRole } from "../middleware/verify-token.js";
import { asyncHandler, validateBody, validateQuery } from "../middleware/async-handler.js";
import { getNearbyPanditsHandler, updateDutyStatusHandler, acceptBookingHandler, getPanditDashboardHandler } from "../controllers/pandits.controller.js";
import { nearbyQuerySchema, dutyStatusSchema, acceptBookingSchema } from "../validators/pandits.validator.js";
import { strictLimiter, nearbyLimiter, apiLimiter } from "../middleware/rate-limit.js";

const panditsRouter = Router();

panditsRouter.get(
  "/dashboard",
  apiLimiter,
  verifyToken,
  requireRole(["PANDIT"]),
  asyncHandler(getPanditDashboardHandler)
);

panditsRouter.get(
  "/nearby",
  nearbyLimiter,
  verifyToken,
  validateQuery(nearbyQuerySchema),
  asyncHandler(getNearbyPanditsHandler)
);

panditsRouter.patch(
  "/duty-status",
  strictLimiter,
  verifyToken,
  requireRole(["PANDIT"]),
  validateBody(dutyStatusSchema),
  asyncHandler(updateDutyStatusHandler)
);

panditsRouter.post(
  "/accept-booking",
  strictLimiter,
  verifyToken,
  requireRole(["PANDIT"]),
  validateBody(acceptBookingSchema),
  asyncHandler(acceptBookingHandler)
);

export default panditsRouter;
