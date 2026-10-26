import type { UserRole } from "../db/schema/enums.js";

export interface JwtPayload {
  id: string;
  phone: string;
  role: UserRole;
  email?: string;
  jti?: string;
  exp?: number;
  iat?: number;
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
    fullName?: string;
    role: UserRole;
    dob?: string | null;
    tob?: string | null;
    pob?: string | null;
    gotra?: string | null;
    zodiac?: string | null;
    city?: string | null;
    email?: string | null;
  };
  isPandit?: boolean;
  requiresApplication?: boolean;
  hasPanditProfile?: boolean;
  pandit?: {
    id: string;
    verificationStatus: string;
    verificationStage: string;
    isVerified: boolean;
  };
}
