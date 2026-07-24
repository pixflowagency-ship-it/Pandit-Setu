import type { Response } from "express";
import type { ApiErrorBody, ApiSuccessResponse, ApiErrorResponse } from "../types/auth.js";
export declare function sendSuccess<T>(res: Response, data: T, statusCode?: number): Response<ApiSuccessResponse<T>>;
export declare function sendError(res: Response, statusCode: number, error: ApiErrorBody): Response<ApiErrorResponse>;
//# sourceMappingURL=response.d.ts.map