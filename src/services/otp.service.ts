import { env } from "../config/env.js";

interface OtpEntry {
  otp: string;
  expiresAt: number;
}

const otpStore = new Map<string, OtpEntry>();

function normalizePhone(phone: string): string {
  return phone.replace(/\s+/g, "").trim();
}

function generateOtp(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

export function createOtp(phone: string): string {
  const normalizedPhone = normalizePhone(phone);
  const otp = generateOtp();
  const expiresAt = Date.now() + env.otpExpirySeconds * 1000;

  otpStore.set(normalizedPhone, { otp, expiresAt });
  return otp;
}

export function verifyOtp(phone: string, otp: string): boolean {
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

export function getOtpExpirySeconds(): number {
  return env.otpExpirySeconds;
}

export { normalizePhone };
