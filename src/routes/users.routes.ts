import { Router } from "express";
import { verifyToken } from "../middleware/verify-token.js";
import { asyncHandler, validateBody } from "../middleware/async-handler.js";
import {
  getProfileHandler,
  updateProfileHandler,
  updateFcmTokenHandler,
} from "../controllers/users.controller.js";
import { updateProfileSchema, fcmTokenSchema } from "../validators/users.validator.js";

const usersRouter = Router();

usersRouter.get("/me", verifyToken, asyncHandler(getProfileHandler));

usersRouter.patch(
  "/me",
  verifyToken,
  validateBody(updateProfileSchema),
  asyncHandler(updateProfileHandler)
);

usersRouter.post(
  "/fcm-token",
  verifyToken,
  validateBody(fcmTokenSchema),
  asyncHandler(updateFcmTokenHandler)
);

export { usersRouter };
