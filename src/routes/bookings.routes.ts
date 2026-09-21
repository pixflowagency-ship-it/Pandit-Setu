import { Router } from "express";
import { verifyToken } from "../middleware/verify-token.js";
import { asyncHandler, validateBody, validateQuery, validateParams } from "../middleware/async-handler.js";
import { createBookingHandler, listBookingsHandler, getBookingHandler, cancelBookingHandler, updateBookingStatusHandler, generateVideoTokenHandler } from "../controllers/bookings.controller.js";
import { createBookingSchema, listBookingsQuerySchema, getBookingParamsSchema, updateBookingStatusSchema } from "../validators/bookings.validator.js";
import { strictLimiter, apiLimiter } from "../middleware/rate-limit.js";

const bookingsRouter = Router();

bookingsRouter.post(
  "/",
  strictLimiter,
  verifyToken,
  validateBody(createBookingSchema),
  asyncHandler(createBookingHandler)
);

bookingsRouter.get(
  "/",
  apiLimiter,
  verifyToken,
  validateQuery(listBookingsQuerySchema),
  asyncHandler(listBookingsHandler)
);

bookingsRouter.get(
  "/:id",
  apiLimiter,
  verifyToken,
  validateParams(getBookingParamsSchema),
  asyncHandler(getBookingHandler)
);

bookingsRouter.patch(
  "/:id/cancel",
  strictLimiter,
  verifyToken,
  validateParams(getBookingParamsSchema),
  asyncHandler(cancelBookingHandler)
);

bookingsRouter.patch(
  "/:id/status",
  strictLimiter,
  verifyToken,
  validateParams(getBookingParamsSchema),
  validateBody(updateBookingStatusSchema),
  asyncHandler(updateBookingStatusHandler)
);

bookingsRouter.post(
  "/:id/video-token",
  strictLimiter,
  verifyToken,
  validateParams(getBookingParamsSchema),
  asyncHandler(generateVideoTokenHandler)
);

export default bookingsRouter;
