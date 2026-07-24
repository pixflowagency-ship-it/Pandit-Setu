import { sendSuccess } from "../utils/response.js";
import { sendOtp, verifyOtpAndLogin } from "../services/auth.service.js";
export const sendOtpHandler = async (req, res) => {
    const { phone } = req.body;
    const result = await sendOtp(phone);
    sendSuccess(res, result);
};
export const verifyOtpHandler = async (req, res) => {
    const { phone, otp, name } = req.body;
    const result = await verifyOtpAndLogin(phone, otp, name);
    sendSuccess(res, result);
};
//# sourceMappingURL=auth.controller.js.map