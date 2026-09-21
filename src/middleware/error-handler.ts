import type { ErrorRequestHandler } from "express";
import { ZodError } from "zod";
import { AppError } from "../utils/api-error.js";
import { sendError } from "../utils/response.js";
import { env } from "../config/env.js";
import { logger } from "../utils/logger.js";

export const errorHandler: ErrorRequestHandler = (err, _req, res, _next) => {
  if (err instanceof AppError) {
    sendError(res, err.statusCode, {
      code: err.code,
      message: err.message,
      ...(err.details !== undefined && { details: err.details }),
    });
    return;
  }

  if (err instanceof ZodError) {
    sendError(res, 400, {
      code: "VALIDATION_ERROR",
      message: "Request validation failed",
      details: err.flatten().fieldErrors,
    });
    return;
  }

  logger.error({ err }, "Unhandled error");

  sendError(res, 500, {
    code: "INTERNAL_SERVER_ERROR",
    message:
      env.nodeEnv === "production"
        ? "An unexpected error occurred"
        : err instanceof Error
          ? err.message
          : "An unexpected error occurred",
  });
};
