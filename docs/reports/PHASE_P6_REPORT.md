# SARV MANGAL — Phase P6 Implementation Report: Real-Device Validation & Release Readiness

**Date:** 2026-10-20  
**Brand:** SARV MANGAL  
**Repository:** https://github.com/pixflowagency-ship-it/Pandit-Setu  
**Backend Workspace:** `C:\Users\krmta\OneDrive\Desktop\pndtbcknd`  
**Flutter Workspace:** `frontend/pandit_ssetu`  
**Git Branch:** `main`  
**Commit Reference:** `5e4efa9`  

---

## 1. Executive Summary & Release Decision

### Release Decision: **STAGING READY (BLOCKED FOR PRODUCTION & PHYSICAL BETA)**

- **Staging Readiness:** **VERIFIED**. The core backend compiles cleanly, passes 260 automated unit and integration tests across 23 test suites, connects securely to live AWS Neon PostgreSQL 18.6 with PostGIS 3.6.4, has all 22 database tables and the spatial GIST index active, and has multi-stage containerization assets (`Dockerfile`, `docker-compose.staging.yml`) configured.
- **Frontend Quality:** **VERIFIED**. The Flutter application reports 0 analyzer issues (`flutter analyze` clean) and 98/98 unit and widget tests passing across 16 test files.
- **Production & Controlled Beta Deployment:** **BLOCKED**. External cloud deployment cannot proceed without remote cloud hosting infrastructure access and account credentials (AWS / Render / Railway).
- **External Providers:** **CODE-ONLY / BLOCKED**. Zero live sandbox credentials exist in `.env` for Razorpay, Fast2SMS, Firebase FCM, Google Places, or Agora RTC. All integrations operate under safe mock, fallback, or rejection modes.
- **Physical Android Telemetry:** **BLOCKED**. No physical Android hardware or running Android emulator was detected (`flutter devices` reported web browsers only). A comprehensive 12-point manual verification protocol is documented herein.

---

## 2. Phase 0: Baseline & Operational Safety Audit

1. **Git State & Working Tree:**
   - Active branch: `main`.
   - Commit baseline: `5e4efa9`.
   - Uncommitted modifications: Preserved and consolidated (including migration scripts, container assets, and test enhancements).
2. **Target Database Confirmation:**
   - Active instance: AWS Neon PostgreSQL 18.6 (`PostgreSQL 18.6 (653b019)`) with PostGIS 3.6.4 (`POSTGIS="3.6.4"`).
   - Connection verified via `src/db/verify_staging_db.ts` without credential exposure.
   - All 22 public tables confirmed present.
   - Spatial GIST index `idx_pandits_location_gist` on `pandits.location` confirmed present.
   - Absolute data safety observed: zero tables dropped, zero tables truncated, zero destructive commands executed.
3. **Secret Redaction Audit:**
   - Sensitive environment variables (`DATABASE_URL`, `JWT_SECRET`, `RAZORPAY_KEY_SECRET`, `FAST2SMS_API_KEY`) were never printed or exposed in logs or console output.
   - Pino field-level redaction rules verified for `otp`, `token`, `password`, `jwt`, `authorization`, `razorpay_signature`, `dob`, `tob`, `pob`.

---

## 3. Phase 1: Resolution of P5 Verification Gaps

### 1. Payment Webhook HTTP 500 Investigation & Rectification (BUG-16)
- **Root Cause Analysis:**
  In Phase P5, the live smoke test runner executed:
  `POST /api/v1/payments/webhook` with an `x-razorpay-signature` header and expected status `[401, 500]`.
  The endpoint returned `HTTP 500` with error code `CONFIGURATION_ERROR` because `RAZORPAY_WEBHOOK_SECRET` was unconfigured in the staging environment.
  The smoke runner marked this as a `PASS` because `500` was listed in its expected array, conflating "missing server configuration" with "signature security validation".
- **Rectification Applied:**
  1. Updated `src/tests/live_smoke.ts` to inspect the response body: if status is 500, it strictly verifies that `error.code === "CONFIGURATION_ERROR"`, diagnosing that webhook processing is disabled until credentials are provided. If status is 401, it verifies `UNAUTHORIZED` signature rejection.
  2. In `src/tests/payments.test.ts`, dismantled the monolithic webhook test into three distinct, dedicated test suites:
     - **Signature & Configuration Security Validation:** Tests missing signature (401), forged signature (401), mismatched payload body (401), unconfigured webhook secret (500 CONFIGURATION_ERROR), and valid HMAC-SHA256 signature acceptance (200).
     - **Business Event Processing:** Tests successful booking confirmation on `payment.captured` and `order.paid`, product order transition to PROCESSING and PAID on `order.paid`, dakshina collection transition to PAID on `payment.captured`, subscription transition to ACTIVE on `subscription.charged`, and graceful acknowledgment of unhandled event types (200).
     - **Duplicate Event Delivery & Idempotency:** Tests 24-hour Redis event deduplication (`webhook:processed:<eventId>`) dropping duplicate webhook deliveries without DB writes, and database-level idempotency skipping writes if records are already marked `PAID`.
- **Result:** `src/tests/payments.test.ts` expanded from 12 to 24 tests, all passing cleanly.

### 2. Separation of OTP Endpoint Behaviour from Carrier SMS Delivery (BUG-17)
- **Investigation:**
  In Phase P5, `POST /api/v1/auth/send-otp` returning 200 OK could be misinterpreted as carrier SMS delivery. In reality, Fast2SMS was unconfigured, and the application fell back to returning `mockOtp` in development/staging.
- **Rectification Applied:**
  1. Created dedicated unit test suite `src/tests/sms.test.ts` (5 tests) directly testing `sendSmsOtp` in `src/services/sms.service.ts`:
     - Verifies that when `FAST2SMS_API_KEY` is absent, local fallback logging is used and zero network requests are dispatched.
     - Verifies Indian phone number sanitization (stripping `+91`, spaces, hyphens to 10 digits) when communicating with `https://www.fast2sms.com/dev/bulkV2`.
     - Verifies handling of provider rejection (`return: false` or HTTP error status).
     - Verifies that in production mode (`process.env.NODE_ENV === "production"`), network failures throw an explicit error to prevent silent delivery failures.
  2. Updated `src/tests/auth.test.ts` with explicit test verifying that `send-otp` endpoint contract returns `mockOtp` in non-production environments independently of carrier gateway confirmation.
  3. Updated `src/tests/live_smoke.ts` to explicitly log: `Endpoint generated OTP. Actual external SMS delivery is UNVERIFIED (mock fallback active).`

---

## 4. Phase 2: Physical Android Verification & Field Protocol

### Physical Device Connectivity Status: **BLOCKED**
- `flutter devices` output:
  - `Chrome (web)`
  - `Edge (web)`
- No physical Android handset or emulator is attached to the workstation.
- In accordance with instructions, zero synthetic GPS movement was simulated, and no claims of background tracking are fabricated.

### Concise Physical Android Manual Verification Checklist

| Test Item | Prerequisites & Setup | Step-by-Step Actions | Expected Behavior & Verification Criteria | OS Constraints & Defect Traps |
|---|---|---|---|---|
| **1. App Installation & Launch** | Android 10+ handset, USB debugging enabled | Run `flutter run -d <device_id>`. Observe splash sequence. | Splash screen displays official SARV MANGAL branding, saffron theme, transition to Role Selection within 2.5s. | Verify app does not crash on cold start without network. |
| **2. Devotee & Pandit Auth** | Active internet connection, staging server accessible | Select Devotee, enter 10-digit mobile number, request OTP, enter OTP. Repeat with Pandit profile. | Form enforces 10 digits; OTP screen displays 300s countdown timer; successful verification issues JWT and navigates to role home. | Logout clears SharedPreferences tokens and resets GoRouter state to Splash. |
| **3. Pandit Onboarding & KYC** | New Pandit phone number | Enter Vedic qualifications, select Pooja categories, upload Aadhaar / certificate image. | Document upload verifies magic bytes, restricts file to images/PDF, sets Pandit state to `PENDING` (Stage 3). | Unapproved Pandits cannot access Duty toggle or receive bookings. |
| **4. Admin KYC Approval** | Admin JWT session | Open Admin Desk -> Pandit KYC tab. Inspect documents, tap "Approve". | Pandit state updates to `APPROVED` in DB. Pandit app switches to active dashboard on next refresh. | Rejection requires mandatory rejection reason string. |
| **5. Pandit Duty On/Off Toggle** | Approved Pandit | Tap Duty switch in `PanditDashboardScreen`. | Switch turns green; updates `pandits.isOnline = true` in DB; registers coordinates in Redis GEO. | Duty toggle is disabled if location permission is denied. |
| **6. Location Permissions** | Fresh app install | Trigger location request on Duty toggle or Devotee temple screen. | Dialog requests `ACCESS_FINE_LOCATION`. Test "Deny", "Deny & Don't Ask Again", and "Allow". | On permanent denial, app displays clean error card with button directing to Android App Settings. |
| **7. Foreground GPS Telemetry** | Pandit On-Duty, screen on | Walk / drive 100 meters. Monitor backend logs (`POST /me/telemetry`). | Telemetry dispatches every 3-10s with latitude, longitude, accuracy (<20m), speed, heading. | Throttling guard drops telemetry sent more frequently than 1 per 3 seconds. |
| **8. Background GPS & Doze Mode** | Pandit On-Duty, press Home button (app backgrounded) | Leave app in background for 15 minutes. Move to new coordinates. | Background service / location callback continues telemetry updates. Devotee tracking screen reflects new location. | **Android 12+ Limitation:** Requires user consent for `ACCESS_BACKGROUND_LOCATION`. Battery optimization must be disabled for SARV MANGAL in system settings, otherwise OS Doze suspends timers. |
| **9. Process Termination (Force Stop)** | Pandit On-Duty | Swipe app away from Android Recent Tasks menu (kill process). | Telemetry immediately halts. PostGIS records last known location. After 10 minutes, `maxLocationAgeMs` excludes Pandit from in-person dispatch. | **Critical Android Truth:** A killed/force-stopped app CANNOT execute Dart code or send telemetry until reopened by user. |
| **10. Devotee Live Tracking Badge** | Active booking accepted by Pandit | Devotee opens `LivePoojaTrackingScreen`. Observe badge while Pandit is active vs idle. | - Updated < 5m ago: Green **Live GPS (±Xm) • Updated Xs ago**<br>- Updated >= 5m ago: Amber **Last Known Location • Ym ago**<br>- No coordinates: Red **Location Unavailable**. | Zero synthetic path animation; strictly displays actual coordinates. |
| **11. Booking Creation & Pandit Accept/Decline** | Devotee and Pandit accounts | Devotee books Pooja. Socket.IO emits request to nearest on-duty Pandit. | Modal pops up with 60s countdown on Pandit handset. Tap Accept -> updates booking to `CONFIRMED`. Tap Decline -> logs decline reason and re-dispatches. | Duplicate taps on Accept button are disabled; modal dismisses cleanly on expiry. |
| **12. Store Cart, Checkout & Helpline Modals** | Devotee account | Add items to cart in Shop, proceed to Checkout. Open Kundli order modal. | Cart calculates item totals and shipping server-side. Kundli and Consultation modals display persisted order numbers and helpline dispatch notices. | Sandbox Razorpay checkout modal opens if credentials present; fails gracefully with notice if absent. |

---

## 5. Phase 3: External Provider Readiness Matrix

| Provider | Purpose | Status | Configuration in Staging | Sandbox Credentials | Request Performed | Verified Status | Remaining Limitations & Next Actions |
|---|---|---|---|---|---|---|---|
| **Razorpay** | Orders, Dakshina, Subscriptions, Webhooks | **CODE-ONLY / BLOCKED** | Absent in `.env` (`RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, `RAZORPAY_WEBHOOK_SECRET` missing) | Blocked | No live HTTP request performed to `api.razorpay.com` | Verified in 24 Vitest unit tests (HMAC SHA256 timing-safe verification, raw buffer webhooks, idempotency) | Live staging server returns 500 CONFIGURATION_ERROR on webhook calls with signatures. Inject test key pair (`rzp_test_...`) and webhook secret. |
| **Fast2SMS** | Transactional SMS OTP | **CODE-ONLY / BLOCKED** | Absent in `.env` (`FAST2SMS_API_KEY` missing) | Blocked | No live request dispatched to `fast2sms.com/dev/bulkV2` | Verified in 5 unit tests (`sms.test.ts`) covering phone sanitization, payload format, return: false handling, and timeout error modes | Staging falls back to logging and returning `mockOtp`. Carrier SMS cannot be delivered until a funded Fast2SMS API key is supplied. |
| **Firebase FCM** | Mobile push notifications | **CODE-ONLY / BLOCKED** | Absent in `.env` (`FIREBASE_SERVICE_ACCOUNT_BASE64` missing) | Blocked | No push request sent to FCM servers | Verified in 4 unit tests (`notification.test.ts`) covering token clearing on `messaging/invalid-registration-token` | Push notifications are silently skipped with log warning. Provide base64 service account JSON to enable live mobile pushes. |
| **Google Places** | Nearby temple discovery | **CODE-ONLY / BLOCKED** | Absent in `.env` (`GOOGLE_PLACES_API_KEY` missing) | Blocked | No request dispatched to Google Places API | Verified in 3 unit tests (`temples.test.ts`) covering Geohash precision-5 caching and fallback | Devotee temple discovery returns empty list `[]`. Supply restricted Google Maps API key to activate live temple search. |
| **Agora RTC** | Video verification calling | **CODE-ONLY / BLOCKED** | Absent in `.env` (`AGORA_APP_ID`, `AGORA_APP_CERTIFICATE` missing) | Blocked | No RTC channel tokens generated | Verified in 2 unit tests (`agora.test.ts`) covering server-side token generation and secret isolation | Admin video verification desk cannot initiate Agora video channels without valid App ID and Certificate. |

---

## 6. Phase 4: Deployment Readiness

### 1. Containerization & Configuration Audit
- **`Dockerfile`:**
  - Multi-stage build (`node:20-alpine AS builder` -> `node:20-alpine AS runner`).
  - Production dependency pruning (`npm ci --omit=dev && npm cache clean --force`).
  - Security hardening: runs as non-root system user `appuser` (UID/GID created in Alpine).
  - Health check: Built-in native Node.js HTTP probe to `http://localhost:5000/health/live` (30s interval, 5s timeout, 3 retries).
  - Storage permissions: `/app/storage/documents` created with ownership assigned to `appuser:appgroup`.
- **`docker-compose.staging.yml`:**
  - Orchestrates API backend, PostgreSQL 16 PostGIS 3.4 Alpine, and Redis 7.2 Alpine.
  - Isolated bridge network with service dependency health checks (`condition: service_healthy`).
  - Persistent named volumes for DB (`staging_db_data`), Redis (`staging_redis_data`), and file storage (`staging_storage`).
  - Strict staging CORS origin whitelist (`https://staging.sarvmangal.app,http://localhost:3000`).

### 2. Live Neon Database vs Local Compose Comparison

| Architectural Aspect | Local Compose Environment | Configured Staging Neon Environment | Operational Impact & Guidelines |
|---|---|---|---|
| **PostgreSQL Version** | PostgreSQL 16 Alpine | PostgreSQL 18.6 (`653b019`) | Fully SQL compatible; Neon runs newer preview engine. |
| **PostGIS Version** | PostGIS 3.4 Alpine | PostGIS 3.6.4 | Both support SRID 4326 Point geometry and GIST spatial indexing. |
| **SSL / TLS Encryption** | Plaintext (`sslmode=disable`) | Mandatory TLS (`sslmode=require` / `verify-full`) | Neon requires encrypted transport; local container runs within internal Docker network. |
| **Connection Pooling** | Direct PostgreSQL port 5432 | PgBouncer / Neon Serverless Proxy (`-pooler` host) | Direct connection URL must be used for DDL migrations; pooled URL for application traffic. |
| **Compute Suspension** | Always on (local container) | Auto-suspend on idle (scale-to-zero) | Neon compute suspends after 5m of inactivity; fresh connection incurs 1-2s cold-start wakeup. |
| **Spatial Indexing** | Applied via migration script | Applied and verified (`idx_pandits_location_gist`) | Accelerated KNN queries for Pandit dispatch functional in both environments. |

### 3. External Cloud Deployment Commands & Prerequisites
- **Deployment Status:** **BLOCKED** pending cloud account selection and CLI credentials.
- **Recommended Targets:** AWS ECS (Fargate), Render, or Railway.
- **Deployment Runbook (Render / Railway):**
  ```bash
  # 1. Connect Git repository to staging environment
  # 2. Set Build Command: Dockerfile
  # 3. Inject Environment Secrets:
  #    DATABASE_URL=<neon_connection_string>
  #    REDIS_URL=<upstash_or_managed_redis_url>
  #    JWT_SECRET=<secure_random_key_min_32_chars>
  #    CORS_ORIGIN=https://staging.sarvmangal.app
  # 4. Verify deployment via liveness probe:
  curl -i https://<staging-app-url>/health/live
  ```

---

## 7. Phase 5: Comprehensive Release Assessment

### Feature Classification Matrix

| Feature / Subsystem | Implementation Status | Evidence Reference | Phase P6 Classification |
|---|---|---|---|
| 26 Pooja Catalog & Pricing | Full DB persistence & API endpoints | `src/tests/poojas.test.ts`, Neon DB (26 rows) | **VERIFIED** |
| 1,267 Samagri & Store Products | Full DB persistence & Search/Filter API | `src/tests/products.test.ts`, Neon DB (1267 rows) | **VERIFIED** |
| Devotee Phone OTP & Session Auth | SMS service with development mock fallback | `src/tests/auth.test.ts`, `src/tests/sms.test.ts` | **VERIFIED** (Code & Mock) |
| Live Carrier SMS Dispatch | Fast2SMS Bulk V2 provider client | `src/services/sms.service.ts` | **CODE-ONLY / BLOCKED** (No API Key) |
| Pandit Onboarding & Document Upload | Magic-bytes validation, restricted permissions | `src/tests/pandits_onboarding.test.ts` | **VERIFIED** |
| Admin Desk & Approval Workflow | 5-tab dashboard, KYC approvals, role guards | `src/tests/admin.test.ts`, `admin_dashboard_test.dart` | **VERIFIED** |
| Pandit Duty Toggle & Geo Registration | Redis GEO and PostgreSQL location updates | `src/tests/pandits.test.ts`, `telemetry.test.ts` | **VERIFIED** |
| In-Person Booking Proximity Dispatch | PostGIS distance & 10m freshness threshold | `src/tests/dispatch.test.ts`, `telemetry.test.ts` | **VERIFIED** |
| Pandit Real-Time GPS Telemetry | `POST /me/telemetry`, Socket.IO broadcast | `src/tests/telemetry.test.ts`, `pandit_telemetry_and_tracking_test.dart` | **VERIFIED** (Logic & Engine) |
| Physical Handset Background GPS | Android background location isolate | Manual protocol documented | **BLOCKED** (No Physical Handset) |
| Devotee Live GPS vs Last Known UI | Real-time badge distinction (<5m vs >=5m) | `live_pooja_tracking_screen.dart` | **VERIFIED** |
| Cash Dakshina Collection | Closure workflow & cash receipt recording | `src/tests/dakshina.test.ts` | **VERIFIED** |
| Razorpay Payment Verification | Constant-time HMAC SHA256 verification | `src/tests/payments.test.ts` (24 tests) | **VERIFIED** (Engine) |
| Live Razorpay Gateway Transactions | Payment intent, checkout modal, live capture | Razorpay API SDK | **CODE-ONLY / BLOCKED** (No Key ID) |
| Payment Webhook Ingestion & Deduplication | Raw buffer parsing, HMAC check, Redis 24h dedupe | `src/tests/payments.test.ts` | **VERIFIED** |
| Vedic Consultation Desk & Lifecycle | Drizzle schema, state machine, Admin desk | `src/tests/consultations.test.ts` (20 tests) | **VERIFIED** |
| Handmade Kundli Orders & Fulfilment | Drizzle schema, Speed Post tracking, Admin desk | `src/tests/kundli_orders.test.ts` (19 tests) | **VERIFIED** |
| Phool Mala Subscriptions | Drizzle schema, lifecycle updates, webhook sync | `src/tests/subscriptions.test.ts` | **VERIFIED** (Engine) |
| Nearby Temple Discovery | Geohash cache & Google Places client | `src/tests/temples.test.ts` | **CODE-ONLY / BLOCKED** (No Places Key) |
| Firebase Mobile Push Notifications | Token registration, FCM client | `src/tests/notification.test.ts` | **CODE-ONLY / BLOCKED** (No Service Acct) |
| Agora Video Verification Calling | RTC token generation & certificate isolation | `src/tests/agora.test.ts` | **CODE-ONLY / BLOCKED** (No Agora App ID) |
| Health Probes & Observability | `/health/live`, `/health/ready`, `x-request-id` | `src/tests/health.test.ts`, `src/tests/live_smoke.ts` | **VERIFIED** |
| Graceful Server Shutdown | SIGTERM/SIGINT closing HTTP, Socket, Redis, DB | `src/server.ts` | **VERIFIED** |

---

## 8. Summary of Automated Test Verification Runs

| Test Suite | Command | Test Files | Total Tests | Passed | Failed | Status |
|---|---|---|---|---|---|---|
| **Backend TypeScript Check** | `npm run typecheck` | N/A | Full AST | 0 errors | 0 | **PASSED** |
| **Backend Unit & Integration** | `npm run test` | 23 | 260 | 260 | 0 | **PASSED** |
| **Backend Build** | `npm run build` | N/A | Full `dist/` | 0 errors | 0 | **PASSED** |
| **Flutter Static Analysis** | `flutter analyze` | N/A | Full project | 0 issues | 0 | **PASSED** |
| **Flutter Widget & Unit Tests** | `flutter test` | 16 | 98 | 98 | 0 | **PASSED** |
| **Live Database Verification** | `npx tsx verify_staging_db.ts` | 1 | 22 tables | 22 tables + GIST index | 0 | **PASSED** |

---

## 9. Next Recommended Phase: Phase P7

### Recommended Scope: **External Cloud Hosting Deployment & Live Sandbox Integration**
1. **Target Cloud Platform Provisioning:**
   - Authorize deployment to AWS ECS (Fargate), Render, or Railway.
   - Inject container assets (`Dockerfile`, `docker-compose.staging.yml`) into the remote environment.
2. **Provider Sandbox Key Provisioning:**
   - Inject test-mode Razorpay credentials (`RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, `RAZORPAY_WEBHOOK_SECRET`).
   - Inject Fast2SMS API key to execute live carrier SMS delivery verification.
   - Inject Firebase service account credentials to verify physical Android push delivery.
   - Inject Google Places API key to verify nearby temple search.
   - Inject Agora RTC credentials to verify video calling.
3. **Physical Android Handset Execution:**
   - Attach physical Android test handset via ADB to execute the 12-point manual verification protocol documented in Section 4.
