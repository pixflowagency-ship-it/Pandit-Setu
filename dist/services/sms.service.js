import { env } from "../config/env.js";
export async function sendSmsOtp(phone, otp) {
    console.log(`[SMS Mock] OTP for ${phone}: ${otp} (expires in ${env.otpExpirySeconds}s)`);
}
//# sourceMappingURL=sms.service.js.map