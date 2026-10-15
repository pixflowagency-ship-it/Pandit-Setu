import { Router } from "express";
import { verifyToken } from "../middleware/verify-token.js";
import {
  asyncHandler,
  validateBody,
  validateQuery,
  validateParams,
} from "../middleware/async-handler.js";
import {
  createProductOrderHandler,
  listProductOrdersHandler,
  getProductOrderByIdHandler,
  createOrderPaymentHandler,
  verifyOrderPaymentHandler,
} from "../controllers/product-orders.controller.js";
import {
  createProductOrderSchema,
  listProductOrdersQuerySchema,
  getOrderByIdParamsSchema,
  verifyOrderPaymentSchema,
} from "../validators/product-orders.validator.js";
import { strictLimiter, apiLimiter } from "../middleware/rate-limit.js";

const productOrdersRouter = Router();

productOrdersRouter.post(
  "/",
  strictLimiter,
  verifyToken,
  validateBody(createProductOrderSchema),
  asyncHandler(createProductOrderHandler)
);

productOrdersRouter.get(
  "/",
  apiLimiter,
  verifyToken,
  validateQuery(listProductOrdersQuerySchema),
  asyncHandler(listProductOrdersHandler)
);

productOrdersRouter.get(
  "/:id",
  apiLimiter,
  verifyToken,
  validateParams(getOrderByIdParamsSchema),
  asyncHandler(getProductOrderByIdHandler)
);

productOrdersRouter.post(
  "/:id/create-payment",
  strictLimiter,
  verifyToken,
  validateParams(getOrderByIdParamsSchema),
  asyncHandler(createOrderPaymentHandler)
);

productOrdersRouter.post(
  "/:id/verify-payment",
  strictLimiter,
  verifyToken,
  validateParams(getOrderByIdParamsSchema),
  validateBody(verifyOrderPaymentSchema),
  asyncHandler(verifyOrderPaymentHandler)
);

export default productOrdersRouter;
