import { Router } from "express";
import { verifyToken } from "../middleware/verify-token.js";
import { asyncHandler, validateBody } from "../middleware/async-handler.js";
import { createOrderHandler, verifyPaymentHandler } from "../controllers/payments.controller.js";
import { createOrderSchema, verifyPaymentSchema } from "../validators/payments.validator.js";
import { strictLimiter } from "../middleware/rate-limit.js";

const paymentsRouter = Router();

paymentsRouter.post(
  "/create-order",
  strictLimiter,
  verifyToken,
  validateBody(createOrderSchema),
  asyncHandler(createOrderHandler)
);

paymentsRouter.post(
  "/verify",
  strictLimiter,
  verifyToken,
  validateBody(verifyPaymentSchema),
  asyncHandler(verifyPaymentHandler)
);

export default paymentsRouter;
