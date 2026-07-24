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

const authRouter = Router();

authRouter.post(
  "/send-otp",
  validateBody(sendOtpSchema),
  asyncHandler(sendOtpHandler),
);

authRouter.post(
  "/verify-otp",
  validateBody(verifyOtpSchema),
  asyncHandler(verifyOtpHandler),
);

export default authRouter;
