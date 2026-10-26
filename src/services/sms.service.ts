import { env } from "../config/env.js";
import { logger } from "../utils/logger.js";

/**
 * Sends SMS OTP via Fast2SMS API when configured, or safely falls back to local logging.
 * In development or when credentials are absent, logs without interrupting the auth flow.
 */
export async function sendSmsOtp(phone: string, otp: string): Promise<void> {
  const apiKey = process.env.FAST2SMS_API_KEY;

  if (apiKey) {
    try {
      // Clean phone number (Fast2SMS expects 10 digits for Indian numbers)
      const cleanPhone = phone.replace(/^\+91/, "").replace(/\D/g, "");

      const response = await fetch("https://www.fast2sms.com/dev/bulkV2", {
        method: "POST",
        headers: {
          authorization: apiKey,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          variables_values: otp,
          route: "otp",
          numbers: cleanPhone,
        }),
        signal: AbortSignal.timeout(5000), // 5-second timeout
      });

      const result = (await response.json()) as any;
      if (!response.ok || result?.return === false) {
        logger.warn(
          { phone: cleanPhone, status: response.status, message: result?.message },
          "Fast2SMS API returned an error; OTP delivery may have failed"
        );
      } else {
        logger.info({ phone: cleanPhone }, "Fast2SMS OTP delivered successfully");
      }
    } catch (err: any) {
      logger.error(
        { phone, err: err?.message },
        "Failed to send SMS via Fast2SMS provider"
      );
      // In non-production, allow continuation
      if (process.env.NODE_ENV === "production" || env.nodeEnv === "production") {
        throw new Error("Failed to dispatch SMS OTP");
      }
    }
  } else {
    // Development / Mock fallback
    logger.info(
      { phone, otp, expiresInSeconds: env.otpExpirySeconds },
      "SMS OTP generated (mock / provider not configured)",
    );
  }
}
