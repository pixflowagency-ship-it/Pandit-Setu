# SARV MANGAL — Comprehensive Security and Vulnerability Audit

**Official Brand:** SARV MANGAL  
**Repository:** https://github.com/pixflowagency-ship-it/Pandit-Setu  
**Audit Date:** 2026-10-20  
**Phase:** P7 Architecture & Separation  

---

## 1. Authentication & Role Authorization Security

1. **Role Enforcement on Privileged Routes:**
   - All admin endpoints under `/api/v1/admin/*` are strictly guarded by `verifyToken` and `requireRole(["ADMIN"])`.
   - Rejection is enforced at the server-side router layer: unauthorized tokens receive `401 UNAUTHORIZED`, while non-admin tokens (e.g. `YAJMAN` or `PANDIT`) receive `403 FORBIDDEN`.
2. **Dedicated Admin Password Hashing:**
   - Admin credentials are authenticated via `POST /api/v1/admin/auth/login`.
   - Passwords are never stored or transmitted in plaintext.
   - Hashing algorithm: Node.js native `crypto.scryptSync` with 16-byte cryptographically secure random salt (`crypto.randomBytes(16)`) and 64-byte key length.
   - Password verification executes via constant-time comparison (`crypto.timingSafeEqual`) to prevent timing side-channel attacks.
3. **Prevention of Client-Side Role Promotion:**
   - Mobile and web clients cannot elevate privileges by passing `role: "ADMIN"` during registration or OTP verification.
   - `auth.service.ts` strictly validates database records: a token with `role: "ADMIN"` is issued ONLY if the database user record already possesses `role = 'ADMIN'`.

---

## 2. Rate Limiting & Brute-Force Defenses

| Endpoint Group | Applied Rate Limiter | Threshold | Store | Effect on Breach |
|---|---|---|---|---|
| General API Endpoints | `apiLimiter` | 100 req / 15m | Memory / Redis | HTTP 429 Too Many Requests |
| Sensitive Mutating Endpoints | `strictLimiter` | 20 req / 15m | Memory / Redis | HTTP 429 Too Many Requests |
| Phone OTP Generation | `otpSendLimiter` | 5 req / 10m | Memory / Redis | HTTP 429 (prevents SMS spam) |
| Phone OTP Verification | `otpVerifyLimiter` | 10 req / 10m | Memory / Redis | HTTP 429 (prevents OTP brute-force) |
| Admin Password Login | `strictLimiter` | 5 req / 15m | Memory / Redis | HTTP 429 (prevents credential stuffing) |

---

## 3. Data Protection, Privacy & Log Redaction

1. **Field-Level Pino Redaction:**
   - Configured in `src/utils/logger.ts` with explicit `redact.paths`:
     - Tokens & Secrets: `otp`, `token`, `password`, `jwt`, `authorization`, `headers.authorization`, `req.headers.authorization`.
     - Payment Credentials: `razorpay_signature`, `razorpay_key_secret`.
     - Devotee Sensitive Astrological Data: `dob`, `tob`, `pob`.
2. **Birth Detail Masking in Queue Views:**
   - List endpoints for Kundli orders (`GET /api/v1/admin/kundli-orders`) automatically mask birth details: `dob: "••••"`, `tob: "••••"`.
   - Unmasked details are restricted to single-record detail view (`GET /api/v1/admin/kundli-orders/:id`) accessed by authorized reviewers.
3. **KYC Document Upload Security:**
   - File uploads in `src/services/pandit-verification.service.ts` enforce magic-bytes inspection to prevent executable file uploads (permits JPEG, PNG, and PDF only).
   - Upload directory permissions are restricted, and document streaming (`GET /api/v1/admin/documents/:id/download`) requires an active `ADMIN` token or ownership token.

---

## 4. Payment & Webhook Security

1. **Raw-Buffer Webhook Signature Enforcement:**
   - Razorpay webhooks (`POST /api/v1/payments/webhook`) are parsed as raw `Buffer` before JSON middleware parses the body.
   - Signatures are verified using HMAC SHA256 against `RAZORPAY_WEBHOOK_SECRET` with constant-time equality check (`crypto.timingSafeEqual`).
2. **Idempotency & Replay Attack Defense:**
   - When a valid webhook event is received, its unique event ID (`event.id`) is cached in Redis with a 24-hour TTL (`webhook:processed:<eventId>`).
   - Duplicate deliveries are acknowledged with HTTP 200 without executing duplicate database mutations.
   - Database entities (Bookings, Product Orders, Dakshina) verify `paymentStatus !== "PAID"` before updating, ensuring double-fulfillment protection even upon Redis cache misses.

---

## 5. Transport Security & CORS Whitelist

1. **CORS Allowlist:**
   - Configured in `src/app.ts` to reject unauthorized cross-origin requests.
   - Staging configuration explicitly restricts origins to `https://staging.sarvmangal.app` and `https://admin-staging.sarvmangal.app` (or designated staging origins) instead of wildcard `*`.
2. **Database TLS / SSL Enforced:**
   - AWS Neon connection enforces TLS encryption (`sslmode=require` / `verify-full`). Plaintext database traffic is strictly forbidden.
