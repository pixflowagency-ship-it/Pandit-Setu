import { env } from "../config/env.js";
export async function sendSmsOtp(phone, otp) {
    // Mock SMS gateway — replace with Twilio/MSG91/etc. in production
    console.log(`[SMS Mock] OTP for ${phone}: ${otp} (expires in ${env.otpExpirySeconds}s)`);
}
//# sourceMappingURL=sms.service.js.map