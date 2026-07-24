import type { Response } from "express";
import type {
  ApiErrorBody,
  ApiSuccessResponse,
  ApiErrorResponse,
} from "../types/auth.js";

export function sendSuccess<T>(
  res: Response,
  data: T,
  statusCode = 200,
): Response<ApiSuccessResponse<T>> {
  return res.status(statusCode).json({ success: true, data });
}

export function sendError(
  res: Response,
  statusCode: number,
  error: ApiErrorBody,
): Response<ApiErrorResponse> {
  return res.status(statusCode).json({ success: false, error });
}
