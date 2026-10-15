import { env } from "../config/env.js";
import { getRedis } from "../config/redis.js";

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

export function createOtp(phone: string): string | Promise<string> {
  const normalizedPhone = normalizePhone(phone);
  const otp = generateOtp();
  const expiresAt = Date.now() + env.otpExpirySeconds * 1000;

  try {
    getRedis().then((redis) => {
      if (redis) {
        redis.set(`otp:${normalizedPhone}`, otp, "EX", env.otpExpirySeconds).catch(() => {});
      }
    }).catch(() => {});
  } catch {
    // Redis unavailable, fallback to memory
  }

  otpStore.set(normalizedPhone, { otp, expiresAt });
  return otp;
}

export async function verifyOtp(phone: string, otp: string): Promise<boolean> {
  const normalizedPhone = normalizePhone(phone);

  try {
    const redis = await getRedis();
    if (redis) {
      const storedOtp = await redis.get(`otp:${normalizedPhone}`);
      if (storedOtp) {
        if (storedOtp === otp) {
          await redis.del(`otp:${normalizedPhone}`);
          otpStore.delete(normalizedPhone);
          return true;
        }
        return false;
      }
    }
  } catch {
    // Redis unavailable, fallback to memory
  }

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
