import { Router } from "express";
import { asyncHandler, validateQuery } from "../middleware/async-handler.js";
import { getProductsHandler } from "../controllers/products.controller.js";
import { listProductsQuerySchema } from "../validators/products.validator.js";

const productsRouter = Router();

productsRouter.get(
  "/",
  validateQuery(listProductsQuerySchema),
  asyncHandler(getProductsHandler),
);

export default productsRouter;
