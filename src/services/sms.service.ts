import { env } from "../config/env.js";
import { logger } from "../utils/logger.js";

export async function sendSmsOtp(phone: string, otp: string): Promise<void> {
  logger.info(
    { phone, otp, expiresInSeconds: env.otpExpirySeconds },
    "SMS OTP generated (mock)",
  );
}
