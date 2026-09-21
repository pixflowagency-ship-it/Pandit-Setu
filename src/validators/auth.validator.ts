import { z } from "zod";

const phoneSchema = z
  .string()
  .trim()
  .regex(/^(\+91)?[6-9]\d{9}$/, "Phone must be a valid 10-digit Indian mobile number");

export const sendOtpSchema = z.object({
  phone: phoneSchema,
}).strict();

export const verifyOtpSchema = z.object({
  phone: phoneSchema,
  otp: z
    .string()
    .trim()
    .regex(/^\d{6}$/, "OTP must be a 6-digit code"),
  name: z.string().trim().min(2).max(255).optional(),
}).strict();

export type SendOtpInput = z.infer<typeof sendOtpSchema>;
export type VerifyOtpInput = z.infer<typeof verifyOtpSchema>;
