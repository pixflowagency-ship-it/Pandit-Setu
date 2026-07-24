import type { SendOtpResponse, VerifyOtpResponse } from "../types/auth.js";
export declare function sendOtp(phone: string): Promise<SendOtpResponse>;
export declare function verifyOtpAndLogin(phone: string, otp: string, name?: string): Promise<VerifyOtpResponse>;
//# sourceMappingURL=auth.service.d.ts.map