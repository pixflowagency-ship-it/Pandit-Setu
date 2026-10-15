function requireEnv(key: string): string {
  const value = process.env[key];
  if (!value) {
    throw new Error(`${key} environment variable is not set`);
  }
  return value;
}

export const env = {
  nodeEnv: process.env.NODE_ENV ?? "development",
  port: Number(process.env.PORT ?? 3000),
  databaseUrl: requireEnv("DATABASE_URL"),
  jwtSecret: requireEnv("JWT_SECRET"),
  jwtExpiresIn: process.env.JWT_EXPIRES_IN ?? "7d",
  otpExpirySeconds: Number(process.env.OTP_EXPIRY_SECONDS ?? 300),
  otpLength: 6,
  redisUrl: process.env.REDIS_URL ?? "redis://localhost:6379",
  razorpayKeyId: process.env.RAZORPAY_KEY_ID ?? "",
  razorpayKeySecret: process.env.RAZORPAY_KEY_SECRET ?? "",
  razorpayWebhookSecret: process.env.RAZORPAY_WEBHOOK_SECRET ?? "",
} as const;

export function validateProductionConfig(): void {
  if (env.nodeEnv === "production") {
    const missing: string[] = [];
    if (!process.env.RAZORPAY_KEY_ID) missing.push("RAZORPAY_KEY_ID");
    if (!process.env.RAZORPAY_KEY_SECRET) missing.push("RAZORPAY_KEY_SECRET");
    if (!process.env.RAZORPAY_WEBHOOK_SECRET) missing.push("RAZORPAY_WEBHOOK_SECRET");
    if (missing.length > 0) {
      throw new Error(`Production payment configuration error: Missing required environment variables [${missing.join(", ")}]`);
    }
  }
}

// Automatically validate on startup
validateProductionConfig();

