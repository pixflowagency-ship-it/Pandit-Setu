import pino from "pino";
import { env } from "../config/env.js";

export const logger = pino({
  level: env.nodeEnv === "production" ? "info" : "debug",
  redact: {
    paths: [
      "otp",
      "token",
      "password",
      "jwt",
      "authorization",
      "headers.authorization",
      "req.headers.authorization",
      "razorpay_signature",
      "razorpay_key_secret",
      "dob",
      "tob",
      "pob",
    ],
    censor: "[REDACTED]",
  },
  ...(env.nodeEnv !== "production" && {
    transport: {
      target: "pino-pretty",
      options: {
        colorize: true,
        translateTime: "SYS:HH:MM:ss",
        ignore: "pid,hostname",
      },
    },
  }),
});
