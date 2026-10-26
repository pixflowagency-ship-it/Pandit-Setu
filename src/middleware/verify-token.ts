import type { RequestHandler } from "express";
import { AppError } from "../utils/api-error.js";
import { verifyToken as decodeToken } from "../services/jwt.service.js";
import { isTokenRevoked } from "../services/token-revocation.service.js";

export const verifyToken: RequestHandler = async (req, _res, next) => {
  let token: string | undefined;
  const authHeader = req.headers.authorization;

  if (authHeader?.startsWith("Bearer ")) {
    token = authHeader.slice("Bearer ".length).trim();
  } else if (typeof req.query.token === "string" && req.query.token.trim()) {
    token = req.query.token.trim();
  }

  if (!token) {
    next(
      new AppError(
        401,
        "MISSING_TOKEN",
        "Authorization header with Bearer token or token parameter is required",
      ),
    );
    return;
  }

  try {
    const payload = decodeToken(token);

    // Check if token has been revoked on server / Redis
    const revoked = await isTokenRevoked(token, payload);
    if (revoked) {
      next(
        new AppError(
          401,
          "TOKEN_REVOKED",
          "Authentication token has been revoked. Please log in again.",
        ),
      );
      return;
    }

    req.user = payload;
    req.rawToken = token;
    next();
  } catch (error) {
    next(error);
  }
};

export const requireRole = (roles: string[]): RequestHandler => {
  return (req, _res, next) => {
    if (!req.user) {
      next(new AppError(401, "UNAUTHORIZED", "Authentication required"));
      return;
    }

    if (!roles.includes(req.user.role)) {
      next(new AppError(403, "FORBIDDEN", "You do not have permission to perform this action"));
      return;
    }

    next();
  };
};

export const requireApprovedPandit: RequestHandler = async (req, _res, next) => {
  if (!req.user) {
    next(new AppError(401, "UNAUTHORIZED", "Authentication required"));
    return;
  }

  if (req.user.role !== "PANDIT") {
    next(new AppError(403, "FORBIDDEN", "Pandit role required"));
    return;
  }

  try {
    const { eq } = await import("drizzle-orm");
    const { db } = await import("../db/index.js");
    const { pandits } = await import("../db/schema/pandits.js");

    const pandit = await db.query.pandits.findFirst({
      where: eq(pandits.userId, req.user.id),
    });

    if (!pandit) {
      next(new AppError(404, "NOT_FOUND", "Pandit profile not found"));
      return;
    }

    if (pandit.verificationStatus !== "APPROVED" || !pandit.isVerified) {
      next(
        new AppError(
          403,
          "PANDIT_NOT_APPROVED",
          "Your Pandit profile is not yet approved. Please complete onboarding and verification.",
        ),
      );
      return;
    }

    next();
  } catch (error) {
    next(error);
  }
};

