import { Router } from "express";
import { verifyToken } from "../middleware/verify-token.js";
import { asyncHandler, validateBody } from "../middleware/async-handler.js";
import { createSubscriptionHandler } from "../controllers/subscriptions.controller.js";
import { createSubscriptionSchema } from "../validators/subscriptions.validator.js";
import { strictLimiter } from "../middleware/rate-limit.js";

const subscriptionsRouter = Router();

subscriptionsRouter.post(
  "/",
  strictLimiter,
  verifyToken,
  validateBody(createSubscriptionSchema),
  asyncHandler(createSubscriptionHandler)
);

export default subscriptionsRouter;
