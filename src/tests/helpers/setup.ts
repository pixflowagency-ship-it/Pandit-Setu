import { vi } from "vitest";
import jwt from "jsonwebtoken";
import type { JwtPayload } from "../../types/auth.js";

/**
 * Shared test secret — matches the mock in the env stub below.
 * NEVER used outside tests.
 */
const TEST_JWT_SECRET = "test-secret-for-vitest";

/** Stub environment variables before any module reads them. */
vi.stubEnv("DATABASE_URL", "postgresql://test:test@localhost:5432/test_db");
vi.stubEnv("JWT_SECRET", TEST_JWT_SECRET);
vi.stubEnv("JWT_EXPIRES_IN", "1h");
vi.stubEnv("NODE_ENV", "test");
vi.stubEnv("PORT", "0");
vi.stubEnv("OTP_EXPIRY_SECONDS", "300");
vi.stubEnv("GOOGLE_PLACES_API_KEY", "test-places-api-key");

/** Generate a signed JWT for test requests. */
export function signTestToken(payload: JwtPayload): string {
  return jwt.sign(payload, TEST_JWT_SECRET, { expiresIn: "1h" });
}

/** A reusable Yajman (normal user) token. */
export const yajmanToken = signTestToken({
  id: "00000000-0000-0000-0000-000000000001",
  phone: "+919876543210",
  role: "YAJMAN",
});

/** A reusable Admin token. */
export const adminToken = signTestToken({
  id: "00000000-0000-0000-0000-000000000099",
  phone: "+919999999999",
  role: "ADMIN",
});
