import { Router } from "express";
import { asyncHandler, validateQuery, validateParams } from "../middleware/async-handler.js";
import { getProductsHandler, getProductByIdHandler } from "../controllers/products.controller.js";
import {
  listProductsQuerySchema,
  getProductByIdParamsSchema,
} from "../validators/products.validator.js";

const productsRouter = Router();

productsRouter.get(
  "/",
  validateQuery(listProductsQuerySchema),
  asyncHandler(getProductsHandler),
);

productsRouter.get(
  "/:id",
  validateParams(getProductByIdParamsSchema),
  asyncHandler(getProductByIdHandler),
);

export default productsRouter;
