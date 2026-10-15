import { Router } from "express";
import { verifyToken, requireApprovedPandit } from "../middleware/verify-token.js";
import { asyncHandler, validateBody, validateQuery, validateParams } from "../middleware/async-handler.js";
import {
  createBookingHandler,
  listBookingsHandler,
  getBookingHandler,
  cancelBookingHandler,
  updateBookingStatusHandler,
  generateVideoTokenHandler,
  dispatchBookingHandler,
  collectCashDakshinaHandler,
  createDakshinaOrderHandler,
  verifyDakshinaPaymentHandler,
  getDakshinaStatusHandler,
} from "../controllers/bookings.controller.js";
import {
  createBookingSchema,
  listBookingsQuerySchema,
  getBookingParamsSchema,
  updateBookingStatusSchema,
} from "../validators/bookings.validator.js";
import {
  collectCashDakshinaSchema,
  createDakshinaOrderSchema,
  verifyDakshinaPaymentSchema,
} from "../validators/dakshina.validator.js";
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
  "/my-bookings",
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
  "/:id/dispatch",
  strictLimiter,
  verifyToken,
  validateParams(getBookingParamsSchema),
  asyncHandler(dispatchBookingHandler)
);

bookingsRouter.post(
  "/:id/video-token",
  strictLimiter,
  verifyToken,
  validateParams(getBookingParamsSchema),
  asyncHandler(generateVideoTokenHandler)
);

// Dakshina Collection & Booking Closure Routes
bookingsRouter.post(
  "/:id/dakshina/cash",
  strictLimiter,
  verifyToken,
  requireApprovedPandit,
  validateParams(getBookingParamsSchema),
  validateBody(collectCashDakshinaSchema),
  asyncHandler(collectCashDakshinaHandler)
);

bookingsRouter.post(
  "/:id/dakshina/create-order",
  strictLimiter,
  verifyToken,
  requireApprovedPandit,
  validateParams(getBookingParamsSchema),
  validateBody(createDakshinaOrderSchema),
  asyncHandler(createDakshinaOrderHandler)
);

bookingsRouter.post(
  "/:id/dakshina/verify",
  strictLimiter,
  verifyToken,
  requireApprovedPandit,
  validateParams(getBookingParamsSchema),
  validateBody(verifyDakshinaPaymentSchema),
  asyncHandler(verifyDakshinaPaymentHandler)
);

bookingsRouter.get(
  "/:id/dakshina",
  apiLimiter,
  verifyToken,
  validateParams(getBookingParamsSchema),
  asyncHandler(getDakshinaStatusHandler)
);

export default bookingsRouter;

