import type { Request, Response } from "express";
import { eq } from "drizzle-orm";
import { db } from "../db/index.js";
import { users } from "../db/schema/users.js";
import { AppError } from "../utils/api-error.js";
import { sendSuccess } from "../utils/response.js";
import { verifyPassword } from "../utils/password.js";
import { signAdminToken } from "../services/jwt.service.js";
import { revokeToken } from "../services/token-revocation.service.js";

// Dummy hash and salt to ensure constant-time response and prevent user enumeration
const DUMMY_HASH = "0".repeat(128);
const DUMMY_SALT = "0".repeat(32);

/**
 * Dedicated Admin email & password login.
 * Validates scrypt password hash server-side and checks role === 'ADMIN'.
 * Executes constant-time computation even when user is not found to prevent timing enumeration.
 */
export async function adminLoginHandler(req: Request, res: Response) {
  const { email, password } = req.body;
  const normalizedEmail = String(email).trim().toLowerCase();

  // Find user by email
  const user = await db.query.users.findFirst({
    where: eq(users.email, normalizedEmail),
  });

  if (!user || user.role !== "ADMIN" || !user.passwordHash || !user.passwordSalt) {
    // Constant-time execution to prevent timing attack on non-existent account
    verifyPassword(password, DUMMY_HASH, DUMMY_SALT);
    throw new AppError(401, "INVALID_CREDENTIALS", "Invalid administrator email or password");
  }

  const isValidPassword = verifyPassword(password, user.passwordHash, user.passwordSalt);
  if (!isValidPassword) {
    throw new AppError(401, "INVALID_CREDENTIALS", "Invalid administrator email or password");
  }

  const token = signAdminToken({
    id: user.id,
    phone: user.phone,
    role: "ADMIN",
  });

  return sendSuccess(
    res,
    {
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
      },
    },
    200
  );
}

/**
 * Returns current authenticated admin's identity.
 */
export async function adminMeHandler(req: Request, res: Response) {
  if (!req.user || req.user.role !== "ADMIN") {
    throw new AppError(403, "FORBIDDEN", "Administrator privileges required");
  }

  const user = await db.query.users.findFirst({
    where: eq(users.id, req.user.id),
  });

  if (!user || user.role !== "ADMIN") {
    throw new AppError(404, "NOT_FOUND", "Administrator record not found");
  }

  return sendSuccess(res, {
    user: {
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      phone: user.phone,
    },
  });
}

/**
 * Safely terminates administrative session and revokes the active token.
 */
export async function adminLogoutHandler(req: Request, res: Response) {
  const token = req.rawToken || (req.headers.authorization?.startsWith("Bearer ") ? req.headers.authorization.slice("Bearer ".length).trim() : undefined);
  if (token) {
    await revokeToken(token, req.user);
  }

  return sendSuccess(res, { message: "Administrative session terminated successfully" });
}
