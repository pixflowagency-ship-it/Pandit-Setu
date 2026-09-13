import { env } from "../config/env.js";
export async function sendSmsOtp(phone, otp) {
    const banner = [
        "",
        "============================================================",
        "  🔑 [SMS MOCK SERVICE] OTP GENERATED FOR DEV MODE",
        "  ----------------------------------------------------------",
        `  📱 Phone Number : ${phone}`,
        `  ⚡ OTP CODE     : ${otp}`,
        `  ⏱️ Expires In   : ${env.otpExpirySeconds} seconds`,
        "============================================================",
        "",
    ].join("\n");
    console.log(banner);
    try {
        process.stdout.write(banner + "\n");
    }
    catch (_) { }
}
//# sourceMappingURL=sms.service.js.map