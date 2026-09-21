import type { RequestHandler } from "express";
import type { ZodTypeAny } from "zod";
import { AppError } from "../utils/api-error.js";

export function validateBody(schema: ZodTypeAny): RequestHandler {
  return (req, _res, next) => {
    const result = schema.safeParse(req.body);

    if (!result.success) {
      next(
        new AppError(400, "VALIDATION_ERROR", "Request validation failed", {
          fields: result.error.flatten().fieldErrors,
        }),
      );
      return;
    }

    req.body = result.data;
    next();
  };
}

export function validateQuery(schema: ZodTypeAny): RequestHandler {
  return (req, _res, next) => {
    const result = schema.safeParse(req.query);

    if (!result.success) {
      next(
        new AppError(400, "VALIDATION_ERROR", "Query validation failed", {
          fields: result.error.flatten().fieldErrors,
        }),
      );
      return;
    }

    // Express 5 makes req.query a getter — store parsed data on a custom key.
    req.validatedQuery = result.data;
    next();
  };
}

export function validateParams(schema: ZodTypeAny): RequestHandler {
  return (req, _res, next) => {
    const result = schema.safeParse(req.params);

    if (!result.success) {
      next(
        new AppError(400, "VALIDATION_ERROR", "Path parameter validation failed", {
          fields: result.error.flatten().fieldErrors,
        }),
      );
      return;
    }

    req.validatedParams = result.data;
    next();
  };
}

export function asyncHandler(
  handler: RequestHandler,
): RequestHandler {
  return (req, res, next) => {
    Promise.resolve(handler(req, res, next)).catch(next);
  };
}
