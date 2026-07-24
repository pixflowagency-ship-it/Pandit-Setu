import { env } from "../config/env.js";

export async function sendSmsOtp(phone: string, otp: string): Promise<void> {
  // Mock SMS gateway — replace with Twilio/MSG91/etc. in production
  console.log(
    `[SMS Mock] OTP for ${phone}: ${otp} (expires in ${env.otpExpirySeconds}s)`,
  );
}
