import crypto from "node:crypto";
import jwt, { type SignOptions } from "jsonwebtoken";
import { env } from "../config/env.js";
import { AppError } from "../utils/api-error.js";
import type { JwtPayload } from "../types/auth.js";
import type { UserRole } from "../db/schema/enums.js";

export function signToken(payload: JwtPayload): string {
  const options: SignOptions = {
    expiresIn: env.jwtExpiresIn as SignOptions["expiresIn"],
    jwtid: payload.jti || crypto.randomUUID(),
  };

  return jwt.sign(payload, env.jwtSecret, options);
}

export function signAdminToken(payload: JwtPayload): string {
  const expiresIn = (process.env.ADMIN_JWT_EXPIRES_IN || "4h") as SignOptions["expiresIn"];
  const options: SignOptions = {
    expiresIn,
    jwtid: payload.jti || crypto.randomUUID(),
  };

  return jwt.sign(payload, env.jwtSecret, options);
}

export function verifyToken(token: string): JwtPayload {
  try {
    const decoded = jwt.verify(token, env.jwtSecret);

    if (
      typeof decoded !== "object" ||
      decoded === null ||
      !("id" in decoded) ||
      !("phone" in decoded) ||
      !("role" in decoded)
    ) {
      throw new AppError(401, "INVALID_TOKEN", "Token payload is malformed");
    }

    return {
      id: String(decoded.id),
      phone: String(decoded.phone),
      role: decoded.role as UserRole,
      jti: (decoded as any).jti ? String((decoded as any).jti) : undefined,
      exp: typeof (decoded as any).exp === "number" ? (decoded as any).exp : undefined,
      iat: typeof (decoded as any).iat === "number" ? (decoded as any).iat : undefined,
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }

    if (error instanceof jwt.TokenExpiredError) {
      throw new AppError(401, "TOKEN_EXPIRED", "Authentication token has expired");
    }

    if (error instanceof jwt.JsonWebTokenError) {
      throw new AppError(401, "INVALID_TOKEN", "Authentication token is invalid");
    }

    throw new AppError(401, "AUTH_FAILED", "Authentication failed");
  }
}
