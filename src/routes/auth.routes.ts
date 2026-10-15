import { Router } from "express";
import { asyncHandler, validateBody } from "../middleware/async-handler.js";
import {
  sendOtpHandler,
  verifyOtpHandler,
} from "../controllers/auth.controller.js";
import {
  sendOtpSchema,
  verifyOtpSchema,
} from "../validators/auth.validator.js";
import { otpSendLimiter, otpVerifyLimiter } from "../middleware/rate-limit.js";
import { verifyToken } from "../middleware/verify-token.js";
import { getProfileHandler } from "../controllers/users.controller.js";

const authRouter = Router();

authRouter.post(
  "/send-otp",
  otpSendLimiter,
  validateBody(sendOtpSchema),
  asyncHandler(sendOtpHandler),
);

authRouter.post(
  "/verify-otp",
  otpVerifyLimiter,
  validateBody(verifyOtpSchema),
  asyncHandler(verifyOtpHandler),
);

authRouter.get(
  "/profile",
  verifyToken,
  asyncHandler(getProfileHandler),
);

export default authRouter;
