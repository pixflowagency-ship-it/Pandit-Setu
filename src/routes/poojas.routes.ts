import { Router } from "express";
import { asyncHandler, validateQuery } from "../middleware/async-handler.js";
import { listPoojasHandler } from "../controllers/poojas.controller.js";
import { listPoojasQuerySchema } from "../validators/poojas.validator.js";

const poojasRouter = Router();

poojasRouter.get(
  "/",
  validateQuery(listPoojasQuerySchema),
  asyncHandler(listPoojasHandler),
);

export default poojasRouter;
