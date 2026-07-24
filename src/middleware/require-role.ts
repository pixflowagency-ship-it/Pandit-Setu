import type { RequestHandler } from "express";
import type { UserRole } from "../db/schema/enums.js";
import { AppError } from "../utils/api-error.js";

export function requireRole(allowedRoles: UserRole[]): RequestHandler {
  return (req, _res, next) => {
    if (!req.user) {
      next(
        new AppError(
          401,
          "UNAUTHORIZED",
          "Authentication is required to access this resource",
        ),
      );
      return;
    }

    if (!allowedRoles.includes(req.user.role)) {
      next(
        new AppError(
          403,
          "FORBIDDEN",
          "You do not have permission to access this resource",
          { requiredRoles: allowedRoles, currentRole: req.user.role },
        ),
      );
      return;
    }

    next();
  };
}
