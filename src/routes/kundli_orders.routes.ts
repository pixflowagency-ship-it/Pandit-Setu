import { Router } from "express";
import { verifyToken } from "../middleware/verify-token.js";
import { asyncHandler, validateBody } from "../middleware/async-handler.js";
import { apiLimiter, strictLimiter } from "../middleware/rate-limit.js";
import {
  createKundliOrderSchema,
  cancelKundliOrderSchema,
  verifyKundliPaymentSchema,
} from "../validators/kundli_orders.validator.js";
import {
  createKundliOrderHandler,
  getMyKundliOrdersHandler,
  getKundliOrderByIdHandler,
  cancelKundliOrderHandler,
  createKundliPaymentOrderHandler,
  verifyKundliPaymentHandler,
} from "../controllers/kundli_orders.controller.js";

const kundliOrdersRouter = Router();

kundliOrdersRouter.use(verifyToken);

kundliOrdersRouter.post(
  "/",
  strictLimiter,
  validateBody(createKundliOrderSchema),
  asyncHandler(createKundliOrderHandler)
);

kundliOrdersRouter.get(
  "/",
  apiLimiter,
  asyncHandler(getMyKundliOrdersHandler)
);

kundliOrdersRouter.get(
  "/:id",
  apiLimiter,
  asyncHandler(getKundliOrderByIdHandler)
);

kundliOrdersRouter.post(
  "/:id/cancel",
  strictLimiter,
  validateBody(cancelKundliOrderSchema),
  asyncHandler(cancelKundliOrderHandler)
);

kundliOrdersRouter.patch(
  "/:id/cancel",
  strictLimiter,
  validateBody(cancelKundliOrderSchema),
  asyncHandler(cancelKundliOrderHandler)
);

kundliOrdersRouter.post(
  "/:id/payment/order",
  strictLimiter,
  asyncHandler(createKundliPaymentOrderHandler)
);

kundliOrdersRouter.post(
  "/:id/payment/verify",
  strictLimiter,
  validateBody(verifyKundliPaymentSchema),
  asyncHandler(verifyKundliPaymentHandler)
);

export default kundliOrdersRouter;
