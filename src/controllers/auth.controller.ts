import type { RequestHandler } from "express";
import { sendSuccess } from "../utils/response.js";
import { sendOtp, verifyOtpAndLogin } from "../services/auth.service.js";
import type { SendOtpInput, VerifyOtpInput } from "../validators/auth.validator.js";

export const sendOtpHandler: RequestHandler = async (req, res) => {
  const { phone } = req.body as SendOtpInput;
  const result = await sendOtp(phone);
  sendSuccess(res, result);
};

export const verifyOtpHandler: RequestHandler = async (req, res) => {
  const { phone, otp, name } = req.body as VerifyOtpInput;
  const result = await verifyOtpAndLogin(phone, otp, name);
  sendSuccess(res, result);
};
