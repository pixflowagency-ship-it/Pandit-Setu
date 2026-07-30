import type { UserRole } from "../db/schema/enums.js";

export interface JwtPayload {
  id: string;
  phone: string;
  role: UserRole;
}

export interface ApiErrorBody {
  code: string;
  message: string;
  details?: unknown;
}

export interface ApiSuccessResponse<T> {
  success: true;
  data: T;
}

export interface ApiErrorResponse {
  success: false;
  error: ApiErrorBody;
}

export type ApiResponse<T> = ApiSuccessResponse<T> | ApiErrorResponse;

export interface SendOtpResponse {
  message: string;
  expiresInSeconds: number;

  mockOtp?: string;
}

export interface VerifyOtpResponse {
  token: string;
  user: {
    id: string;
    phone: string;
    name: string;
    role: UserRole;
  };
}
