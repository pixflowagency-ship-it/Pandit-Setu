import { env } from "../config/env.js";
const otpStore = new Map();
function normalizePhone(phone) {
    return phone.replace(/\s+/g, "").trim();
}
function generateOtp() {
    return Math.floor(100000 + Math.random() * 900000).toString();
}
export function createOtp(phone) {
    const normalizedPhone = normalizePhone(phone);
    const otp = generateOtp();
    const expiresAt = Date.now() + env.otpExpirySeconds * 1000;
    otpStore.set(normalizedPhone, { otp, expiresAt });
    return otp;
}
export function verifyOtp(phone, otp) {
    const normalizedPhone = normalizePhone(phone);
    const entry = otpStore.get(normalizedPhone);
    if (!entry) {
        return false;
    }
    if (Date.now() > entry.expiresAt) {
        otpStore.delete(normalizedPhone);
        return false;
    }
    if (entry.otp !== otp) {
        return false;
    }
    otpStore.delete(normalizedPhone);
    return true;
}
export function getOtpExpirySeconds() {
    return env.otpExpirySeconds;
}
export { normalizePhone };
//# sourceMappingURL=otp.service.js.map