import { eq } from "drizzle-orm";
import { db, users } from "../db/index.js";
import { AppError } from "../utils/api-error.js";
import {
  createOtp,
  getOtpExpirySeconds,
  normalizePhone,
  verifyOtp,
} from "./otp.service.js";
import { sendSmsOtp } from "./sms.service.js";
import { signToken } from "./jwt.service.js";
import { env } from "../config/env.js";
import type { SendOtpResponse, VerifyOtpResponse } from "../types/auth.js";

export async function sendOtp(phone: string): Promise<SendOtpResponse> {
  console.log('🔔 Received OTP request for phone:', phone);
  const normalizedPhone = normalizePhone(phone);
  const otp = createOtp(normalizedPhone);
  console.log('🔢 Generated OTP for', normalizedPhone, ':', otp);
  await sendSmsOtp(normalizedPhone, otp);

  const response: SendOtpResponse = {
    message: "OTP sent successfully",
    expiresInSeconds: getOtpExpirySeconds(),
  };

  if (env.nodeEnv !== "production") {
    response.mockOtp = otp;
  }

  return response;
}

export async function verifyOtpAndLogin(
  phone: string,
  otp: string,
  name?: string,
): Promise<VerifyOtpResponse> {
  const normalizedPhone = normalizePhone(phone);

  const isValid = verifyOtp(normalizedPhone, otp);
  if (!isValid) {
    throw new AppError(
      401,
      "INVALID_OTP",
      "The OTP provided is invalid or has expired",
    );
  }

  const existingUser = await db.query.users.findFirst({
    where: eq(users.phone, normalizedPhone),
  });

  let user = existingUser;

  if (!user) {
    if (!name?.trim()) {
      throw new AppError(
        400,
        "NAME_REQUIRED",
        "Name is required for new user registration",
      );
    }

    const [createdUser] = await db
      .insert(users)
      .values({
        phone: normalizedPhone,
        name: name.trim(),
        role: "YAJMAN",
      })
      .returning();

    user = createdUser;
  }

  const token = signToken({
    id: user.id,
    phone: user.phone,
    role: user.role,
  });

  return {
    token,
    user: {
      id: user.id,
      phone: user.phone,
      name: user.name,
      role: user.role,
    },
  };
}
