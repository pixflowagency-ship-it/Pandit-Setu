import { Router } from "express";
import { verifyToken } from "../middleware/verify-token.js";
import { asyncHandler, validateBody } from "../middleware/async-handler.js";
import { updateLocationHandler, getLocationHandler } from "../controllers/tracking.controller.js";
import { updateLocationSchema } from "../validators/tracking.validator.js";

const trackingRouter = Router();

trackingRouter.post(
  "/:bookingId/update",
  verifyToken,
  validateBody(updateLocationSchema),
  asyncHandler(updateLocationHandler)
);

trackingRouter.get(
  "/:bookingId",
  verifyToken,
  asyncHandler(getLocationHandler)
);

export default trackingRouter;
