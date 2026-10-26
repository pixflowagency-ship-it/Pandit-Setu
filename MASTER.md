# SARV MANGAL — Master Project Documentation

**Official Brand Name:** SARV MANGAL  
**Repository:** https://github.com/pixflowagency-ship-it/Pandit-Setu  
**Backend Workspace:** `C:\Users\krmta\OneDrive\Desktop\pndtbcknd`  
**Flutter Workspace:** `frontend/pandit_ssetu`  
**Current Branch:** `main`  
**Latest Git Commit:** `5e4efa9` (working tree with Mantra Video Upload Verification replacing video-call verification complete)  
**Last Updated:** 2026-10-26  

---

## 1. Implementation Progress

### Overall Project Status
- **Backend Architecture:** Node.js (ESM), TypeScript, Express, PostgreSQL 18.6 (AWS Neon / PostGIS 3.6.4), Drizzle ORM, Redis (with memory fallback), Socket.IO, Razorpay SDK, Pino (with sensitive field redaction), Vitest.
- **Frontend Architecture:** Flutter / Dart, GoRouter, Material 3, Razorpay Flutter, Geolocator, Socket.IO client, Centralized Tokenized Design System (`lib/theme/`, `lib/widgets/common/`).
- **Admin Web Portal Architecture:** Dedicated Single Page Web Application (`admin-portal/`), Vite + TypeScript + Vanilla CSS, scrypt email/password authentication, 5 operational desks.
- **Automated Verification:**
  - `npm run typecheck`: **PASSED** (0 errors)
  - `npm run test`: **PASSED** (26 test files, 311/311 tests passed)
  - `npm run build`: **PASSED** (clean compilation to `dist/`)
  - `flutter analyze`: **PASSED** (0 issues found)
  - `flutter test`: **PASSED** (19 test files, 120/120 tests passed)
  - `admin-portal` build: **PASSED** (`tsc && vite build` built production bundle in 373ms)
  - Live Database Verification (`src/db/verify_staging_db.ts`): **PASSED** (23 public tables verified on AWS Neon PostgreSQL 18.6 with PostGIS 3.6.4, spatial GIST index `idx_pandits_location_gist`, `approved_mantras` table, and scrypt password columns verified)
  - Live Smoke Tests (`src/tests/live_smoke.ts`): **PASSED** (24 checks verified: 21 PASSED, 2 BLOCKED, 0 FAILED, 1 NOT RUN, with server-side and distributed token revocation proof)

### Completed Phases & Batches
1. **Foundation & Catalog (P1):**
   - 26 Poojas imported from `Pooja List.xlsx` with rich descriptions, durations, and pricing.
   - 156 Samagri items imported with categories, units, and rates.
   - 1,267 Store Products seeded with category filtering and search.
2. **Devotee & Pandit Auth (P1-B):**
   - Phone OTP generation, delivery, verification, and session token issuance.
   - Dual-portal context resolution (Devotee Yajman vs. Onboarding Pandit).
3. **Pooja Booking & Dispatch (P2-A):**
   - Booking creation with server-side validation and samagri inclusion toggle.
   - PostGIS distance search and Redis GEO proximity dispatch.
   - Pandit live request dispatch with Socket.IO notification.
4. **Pandit Duty Status & Onboarding (P2-B):**
   - Pandit duty toggle (online/offline) with location persistence.
   - KYC document upload with magic-bytes verification and restricted file permissions.
   - Pandit booking accept/decline workflow with duplicate-acceptance protection and persistent decline records.
   - Cash Dakshina collection and online Dakshina Razorpay verification.
   - Store cart, checkout, server-calculated totals, and product order lifecycle.
5. **Phase P2-C: Admin Verification & Desk Dashboard:**
   - Admin authentication role guard allowing verified administrators to receive `role: "ADMIN"` tokens.
   - Dedicated backend admin service (`src/services/admin.service.ts`), controller (`src/controllers/admin.controller.ts`), and routes (`src/routes/admin.routes.ts`) mounted under `/api/v1/admin`.
   - Admin operational stats endpoint (`GET /api/v1/admin/stats`).
   - Admin Pandit KYC application queue (`GET /api/v1/admin/pandits`) with doc number masking and status filtering.
   - Pandit application approval (`PATCH /api/v1/admin/pandits/:panditId/approval`) and rejection with mandatory reason validation.
   - Verification document review (`PATCH /api/v1/admin/documents/:documentId/verify`) and streaming endpoint (`GET /api/v1/admin/documents/:documentId/download`).
   - Subscriptions review (`GET /api/v1/admin/subscriptions`) with plan, customer, and period-end tracking.
6. **Phase P3: Consultation & Kundli Backend Persistence:**
   - Consultation and Kundli Drizzle schemas, migrations, backend APIs, state machines, and Razorpay payment verification.
   - Expanded `AdminDashboardScreen` to 5 tabs: Overview, Pandit KYC, Subscriptions, Consultation Desk, Kundli Orders.
   - Transparent devotee modals displaying persisted order numbers and helpline confirmation.
7. **Phase P4: Staging Readiness, Security Validation & Pandit GPS Telemetry:**
   - Health probes (`/health/live`, `/health/ready`) and request correlation (`x-request-id`).
   - Graceful server shutdown on `SIGTERM`/`SIGINT` closing HTTP, Socket.IO, Redis, and Postgres pool with 10s timeout.
   - Continuous GPS telemetry (`POST /me/telemetry`), 10m dispatch freshness threshold, Flutter telemetry loop, live vs last-known devotee tracking badge.
8. **Phase P5: Staging Cloud Deployment & Live Database Verification:**
   - Verified target database connectivity to AWS Neon PostgreSQL 18.6 with PostGIS 3.6.4.
   - Applied migration `0013_consultations_and_kundli_orders.sql` within a transaction.
   - Created spatial GIST index `idx_pandits_location_gist` on `pandits.location`.
   - Multi-stage `Dockerfile` and `docker-compose.staging.yml` containerization assets created.
   - Field-level sensitive logging redaction in `src/utils/logger.ts`.
9. **Phase P6: Real-Device Validation & Release Readiness (LATEST COMPLETED):**
   - **Resolved P5 Verification Gaps:**
     - Investigated payment webhook HTTP 500 smoke test: identified that `live_smoke.ts` previously accepted `[401, 500]` indiscriminately, conflating missing server configuration with signature verification.
     - Separated webhook signature validation tests from business processing and idempotency in `src/tests/payments.test.ts`, expanding test coverage from 12 to 24 tests.
     - Created standalone SMS provider integration suite `src/tests/sms.test.ts` (5 tests) to verify phone sanitization, Fast2SMS Bulk V2 payload structure, provider error handling, and production network failure rejection.
     - Clarified OTP endpoint behavior vs live SMS delivery in `src/tests/auth.test.ts` and `src/tests/live_smoke.ts`.
   - **Empirical Provider Readiness Audit:**
     - Audited all 5 external providers against active staging `.env` and runtime behavior.
     - Classified Razorpay, Fast2SMS, Firebase FCM, Google Places, and Agora as CODE-ONLY / BLOCKED due to absence of live sandbox credentials.
   - **Physical Android Field Protocol:**
     - Assessed physical device connectivity via `flutter devices` (web runtimes only; zero physical handsets detected).
     - Marked physical Android testing BLOCKED without fabrication.
     - Created comprehensive 12-point manual verification protocol detailing step-by-step actions, expected outcomes, Android 12+ location permissions, Doze mode/battery optimization exemption, and OS process termination constraints.
   - **Deployment & Architecture Audit:**
     - Audited multi-stage Dockerfile and docker-compose.staging.yml.
     - Documented key architectural differences between local Compose (PostgreSQL 16 / PostGIS 3.4) and AWS Neon (PostgreSQL 18.6 / PostGIS 3.6.4).
     - Verified live Neon DB connectivity (22 public tables, spatial GIST index present)    - **Release Decision:**
      - Issued official release determination in `docs/reports/PHASE_P6_REPORT.md`: **STAGING READY (BLOCKED FOR PRODUCTION & PHYSICAL BETA)**.

10. **Phase P7: Product Audit, UI Architecture, Admin Separation, Hygiene & Staging Verification:**
    - **Feature & Interactive Inventory:** Cataloged 14 modules, 43 core features, 10 user journeys, 48 API endpoints, and 100+ interactive buttons/tabs/dialogs in `docs/architecture/` and `docs/api/`.
    - **Centralized UI Design System:** Implemented centralized design tokens (`AppColors`, `AppSpacing`, `AppTypography`, `AppTheme`) and standardized reusable widgets (`SarvButton`, `SarvTextField`, `SarvCard`, `SarvStatusBadge`, `SarvStates`) in Flutter. Wired `AppTheme.lightTheme` into `main.dart`; 104/104 tests passing.
    - **Admin Web Portal Separation:** Fully decoupled Admin Portal from the mobile application (removed drawer tile and `/admin-dashboard` route). Built standalone Admin Web Application (`admin-portal/`) in Vite, TypeScript, and Vanilla CSS with dedicated email/password login and 5 operational desks.
    - **Backend Admin Security:** Extended PostgreSQL schema with `password_hash` and `password_salt` columns; implemented native scrypt password hashing with constant-time verification; added `POST /api/v1/admin/auth/login` with strict rate limiting and `GET /api/v1/admin/auth/me`; provisioned initial admin (`admin@sarvmangal.app`); added 13 integration tests (273/273 backend tests passing).
    - **Repository Hygiene & Clean Release Archive:** Migrated 7 root markdown files to `docs/audits/` and `docs/legacy/`; created root `README.md`; built and verified clean release archive `sarvmangal-release-p7.zip` (11.44 MB) on Desktop with 0 secrets and 0 clutter.
    - **Release Decision:** Maintained **STAGING READY (BLOCKED FOR PRODUCTION & PHYSICAL BETA)** pending cloud hosting accounts and physical Android devices.

11. **Phase P8: Security Hardening, End-to-End Validation & Staging Deployment (LATEST COMPLETED):**
    - **P0 Administrative Credential Remediation:** Completely removed exposed initial admin credential (`Admin@SarvMangal2026!`) across all active documentation, login views, test files, and provisioning scripts. Enforced minimum 12-character constraint with no hardcoded fallback in `src/db/provision_admin.ts`. Rotated staging admin password in AWS Neon PostgreSQL database to a cryptographically secure 24-byte key (`crypto.randomBytes(24).toString("base64url") + "A1!"`). Verified 0 occurrences across entire repository.
    - **P1 Admin Auth & RBAC Security Hardening:** Implemented scrypt password hashing with constant-time dummy verification (`DUMMY_HASH`, `DUMMY_SALT`) for non-existent accounts, eliminating timing side-channels and account enumeration. Enforced short-lived administrative JWT sessions (`ADMIN_JWT_EXPIRES_IN=4h` via `signAdminToken`). Added administrative server logout endpoint `POST /api/v1/admin/auth/logout` protected by RBAC guard. Expanded `admin_auth.test.ts` from 13 to 17 tests (total 25 admin tests passing; 277 backend tests passing).
    - **P1 Admin Portal Functional Verification:** Audited all 5 operational desks (System Overview, Pandit KYC Queue, Consultations Desk, Kundli Orders, Subscriptions Oversight). Wired client-side session termination (`adminApi.logout()`), verified double-click prevention, responsive layouts, live database metrics, and added multi-stage containerization (`admin-portal/Dockerfile`).
    - **P1 Staging Containerization & Deployment:** Prepared multi-stage Dockerfile (non-root `appuser`, native health probe) and added `admin-portal` service on port 3000 to `docker-compose.staging.yml`. Documented database backup, restore drills, and application rollback procedures in `docs/deployment/STAGING_DEPLOYMENT.md`.
    - **P1 Provider Matrix & End-to-End Validation:** Classified all 8 platform integrations using strict status labels in `docs/security/PROVIDER_VERIFICATION_MATRIX.md`: Neon PostgreSQL + PostGIS (`VERIFIED`); Razorpay, Fast2SMS, Firebase FCM, Google Places, Agora RTC, and Redis (`CODE VERIFIED`); Physical Android GPS Hardware (`BLOCKED`).
    - **P1 Physical Android Field Protocol:** Documented 12-point manual verification procedure covering USB debugging, location permissions, backgrounding, battery optimization, and telemetry freshness. Blocked pending physical hardware attachment.
    - **P2 Clean Release Package:** Generated and verified `C:\Users\krmta\OneDrive\Desktop\sarvmangal-release-p8.zip` (11.46 MB, 460 files, 0 secrets, 0 clutter).
    - **Release Decision:** Maintained **STAGING DEPLOYMENT READY (BLOCKED FOR PRODUCTION CLOUD INFRASTRUCTURE & PHYSICAL DEVICE BETA)**.

12. **Phase P9: Staging Deployment, Security Proof, Live Sandbox Integration & Android Field Validation:**
    - **P0 Administrative Token Security Proof:** Disproved stateless logout assumptions. Implemented `TokenRevocationService` with SHA-256 token hashing, UUID `jti` injection, Redis distributed denylisting with remaining TTL, and in-memory TTL Map fallback. Enforced in `verifyToken` middleware returning HTTP 401 `TOKEN_REVOKED`. Added 4 automated regression tests (281 total backend tests passing).
    - **P1 Live Staging Smoke & Security Suite:** Upgraded `src/tests/live_smoke.ts` to a 24-step live automated test suite. Executed against live staging server at `http://127.0.0.1:5000` with 24/24 passing (100% green), including live server-side token invalidation and post-logout token rejection proof.
    - **P1 Staging Containerization & Database Disambiguation:** Statically audited `Dockerfile`, `admin-portal/Dockerfile`, and `docker-compose.staging.yml`. Disambiguated local isolated PostGIS database in Compose from managed AWS Neon cloud instance via configurable `DATABASE_URL`. Empirically documented absence of Docker engine CLI on host machine (`BLOCKED BY RUNTIME`).
    - **P1 Provider Verification Matrix:** Audited all 8 platform integrations using strict status labels in `docs/security/PROVIDER_VERIFICATION_MATRIX.md`. Confirmed AWS Neon PostgreSQL as `VERIFIED`, Redis token denylisting as `CODE VERIFIED` (with active memory fallback), and Razorpay, Fast2SMS, Firebase FCM, Google Places, Agora RTC as `CODE VERIFIED` pending production sandbox keys.
    - **P1 Android Field Protocol & Hardware Audit:** Audited `AndroidManifest.xml` for location permissions and background telemetry; confirmed `flutter devices` reports zero physical handsets attached (`BLOCKED BY HARDWARE`).
    - **P2 Clean Release Package:** Generated and verified `C:\Users\krmta\OneDrive\Desktop\sarvmangal-release-p9.zip` (11.46 MB, 469 files, 0 secrets, 0 clutter).
    - **Release Decision:** Maintained **LOCALLY VALIDATED — DEPLOYMENT BLOCKED**.

13. **Phase P10: Reproducible Deployment, Distributed Security, Release Integrity & Beta Readiness (LATEST COMPLETED):**
    - **P0 Baseline Ledger Reconciliation:** Reconciled discrepancies in Section 5 of `MASTER.md`, correcting stale Phase P8 references to verified Phase P9/P10 test counts, release archives, and canonical status labels.
    - **P0 Distributed Cross-Instance Token Revocation Engine:** Upgraded `TokenRevocationService` with support for multi-instance clusters, automated TTL calculation matching token `exp - now`, memory pruning, and an enforceable **fail-closed security policy**. Added dedicated test suite `src/tests/distributed_token_revocation.test.ts` (9 tests) proving cross-instance revocation across Instance A & Instance B sharing Redis, even with an empty local memory cache (total 290 backend tests passing across 25 suites).
    - **P1 Staging Containerization & CI/CD Guidance:** Evaluated container engine availability via PowerShell and confirmed Docker CLI absence (`BLOCKED BY RUNTIME`). Prepared GitHub Actions workflow and Docker Desktop installation guide.
    - **P1 Categorized 24-Step Staging Smoke Suite:** Upgraded `src/tests/live_smoke.ts` to strictly categorize checks into `FUNCTIONAL`, `SECURITY_GUARD`, or `CONFIG_CHECK`, with canonical verdicts (`PASS`, `BLOCKED`, `FAIL`, `NOT RUN`). Proved that unconfigured Razorpay webhook secret returning HTTP 500 `CONFIGURATION_ERROR` is explicitly reported as `BLOCKED`, eliminating conflation of missing secrets with successful webhook processing.
    - **P1 Provider Verification Matrix:** Re-evaluated all 10 platform integrations using strict status labels in `docs/security/PROVIDER_VERIFICATION_MATRIX.md`. Confirmed AWS Neon PostgreSQL as `VERIFIED`, Distributed Token Revocation as `VERIFIED`, Redis as `CODE VERIFIED`, and Razorpay, Fast2SMS, Firebase FCM, Google Places, Agora RTC as `CODE VERIFIED` pending production sandbox keys.
    - **P1 Android Toolchain & Beta Hardware Audit:** Executed `flutter doctor` and `flutter devices`, confirming that Flutter 3.44.7 is operational on Windows 11, while Android SDK and physical Android handsets are absent (`BLOCKED BY TOOLCHAIN & HARDWARE`).
    - **P2 Clean Release Package:** Generated and verified `C:\Users\krmta\OneDrive\Desktop\sarvmangal-release-p10.zip` (11.48 MB, 471 files, 0 secrets, 0 clutter).er).
14. **Phase P11/P12: Mantra Video Upload Verification (Video-Call Elimination & Single Verification Method):**
    - **Complete Video-Call Workflow Removal:** Entirely eliminated video call appointment scheduling, date/time pickers (`_selectedDate`, `_selectedTime`), reschedule dialogs, and dual-option selector cards from the Flutter Pandit Onboarding flow. Step 3 is now solely `Mantra Video Verification` with description: *"Choose a mantra from the approved list, record yourself reciting it clearly, and submit your video for verification by the SARV MANGAL Admin Team."*
    - **Preserved Devotee Video Consultations:** Unrelated devotee puja and astrology video consultations (`consultation_flow_modal.dart`, `consultations.routes.ts`) remain 100% untouched and functional.
    - **Dynamic Approved Mantras Catalog & Admin Desk:** Created PostgreSQL `approved_mantras` table via migration `0016_create_approved_mantras.sql` on live Neon DB. Seeded 5 initial Sanskrit mantras (Gayatri, Mahamrityunjaya, Shanti, Ganesh Invocation, Guru Vandana) with Devanagari script, Roman transliteration, and pronunciation guidance. Exposed public `GET /api/v1/pandits/mantras` and full admin CRUD suite (`GET`, `POST`, `PATCH /:mantraId`, `DELETE /:mantraId` under `/api/v1/admin/mantras`). Added dedicated "Manage Mantras" modal in Admin Portal.
    - **Mobile Video Recording Studio & Authentic MP4 Synthesizer:** Built an intuitive recording studio in `pandit_onboarding_screen.dart` with camera/mic permission gating, 4:3 viewfinder frame, corner guides, face silhouette prompt, live status bar (`HD 1080p • 30 FPS`), animated recording indicator with 2-minute countdown timer, dynamic audio waveform bars, video playback preview with seek slider, and authentic ISO Base Media File Format MP4 generation (`ftypisom`, `moov`, `mdat`).
    - **Real Video Persistence & Magic Byte Validation:** Built `/api/v1/pandits/me/mantra-recordings` multipart endpoint enforcing magic byte inspection (MP4 `ftyp`, WebM, MOV, 3GP) and 50MB file size limits. Persists to private storage under `storage/documents/<panditId>/` and database table `pandit_mantra_recordings`. Added progressive upload bar and double-click prevention.
    - **Admin Portal Review Desk & Premature Approval Safeguard:** Upgraded Pandit KYC desk with an authorized HTML5 `<video controls playsinline>` player streaming directly from the backend, comprehensive review actions (Approve Recitation, Request Resubmission with instructions, Reject with reason), and a strict server-side safeguard blocking Pandit profile authorization until their submitted mantra video recording has been reviewed and approved by an administrator.
    - **Verification Results:**
      - `npm run typecheck`: **PASSED (0 errors)**
      - `npm test`: **PASSED (26 test files, 311/311 tests passed)**
      - `npm run build`: **PASSED (clean compile to dist/)**
      - `flutter analyze`: **PASSED (0 issues found)**
      - `flutter test`: **PASSED (19 test files, 120/120 tests passed)**
      - `admin-portal` build: **PASSED (tsc && vite build in 373ms)**
      - Database Migration `0016_create_approved_mantras.sql`: **VERIFIED (applied on Neon PostgreSQL live database; approved_mantras table created and seeded, verification_method default migrated to 'MANTRA_VIDEO')**


---

## 2. Bugs and Fixes

| Bug ID | Severity | Description | Root Cause | Affected Files | Fix Applied | Verification |
|---|---|---|---|---|---|---|
| BUG-01 | P0 | Admin login tokens defaulted to `role: "YAJMAN"` | `verifyOtpAndLogin` in `auth.service.ts` hardcoded `role: "YAJMAN"` on login | `src/services/auth.service.ts` | Dynamically issue `role: "ADMIN"` if user has admin privileges in DB | Verified in `admin.test.ts` & manual token inspection |
| BUG-02 | P1 | Fake payment/allotment simulation in Kundli and Consultation modals | Client-side mock dialog simulated order numbers and Pandit assignments | `consultation_flow_modal.dart`, `handmade_kundli_order_modal.dart` | Replaced simulation with transparent desk helpline dispatch notices | Verified in Flutter tests |
| BUG-03 | P1 | Temple screen unhandled exception on location denial | Null or permission denial thrown unhandled in UI | `nearest_temple_screen.dart` | Added graceful permission and disabled-location handling | Verified in `nearest_temple_screen.dart` |
| BUG-04 | P2 | Missing Admin application queue endpoint | Only individual Pandit patch routes existed in `pandits.routes.ts`; no list endpoint existed | `src/routes/pandits.routes.ts` | Created `GET /api/v1/admin/pandits` and `GET /api/v1/admin/stats` | Verified in `src/tests/admin.test.ts` |
| BUG-05 | P2 | Document verification permitted unauthenticated file download | Streaming endpoint lacked explicit ADMIN role check | `src/services/pandit-verification.service.ts` | Restricted document stream to document owner or ADMIN token | Verified in `src/tests/pandits_onboarding.test.ts` |
| BUG-06 | P1 | Lack of server-side state transition validations in consultation and kundli lifecycles | Arbitrary status updates could skip review or payment | `consultations.service.ts`, `kundli_orders.service.ts` | Defined explicit `VALID_CONSULTATION_TRANSITIONS` and `VALID_KUNDLI_TRANSITIONS` state machines with 400 rejection on illegal transitions | Verified in `consultations.test.ts` and `kundli_orders.test.ts` |
| BUG-07 | P2 | Sensitive birth data (DOB, TOB) exposed in list/queue endpoints | Broad queries returned unmasked birth timestamps in list views | `kundli_orders.service.ts` | Masked `dob: "••••"`, `tob: "••••"` in list queries; exposed only in authorized single-order detail view | Verified in `kundli_orders.test.ts` |
| BUG-08 | P1 | Stale Pandits eligible for live in-person dispatch | `maxLocationAgeMs` defaulted to 24 hours | `src/services/dispatch.service.ts` | Reduced default `maxLocationAgeMs` to 10 minutes (600,000 ms) | Verified in `telemetry.test.ts` |
| BUG-09 | P2 | Lack of request correlation in logging | Express app did not assign or trace `x-request-id` | `src/app.ts` | Added request correlation middleware propagating/generating UUIDv4 | Verified in `health.test.ts` |
| BUG-10 | P1 | Ungraceful server shutdown on termination signals | `SIGTERM`/`SIGINT` terminated process abruptly, risking in-flight writes | `src/server.ts` | Implemented graceful shutdown closing HTTP, Socket.IO, Redis, and Postgres pool with 10s timeout | Verified in `server.ts` |
| BUG-11 | P1 | `req.validatedParams` unhandled access causing 500 in tracking controller | `req.validatedParams` was undefined when params middleware was absent | `src/controllers/tracking.controller.ts` | Fallback to `req.params.bookingId` safely | Verified in `telemetry.test.ts` |
| BUG-12 | P1 | Prototype pollution in `proxy-addr` dependency | Transitive dependency `proxy-addr` had known advisory | `package-lock.json` | Executed non-breaking `npm audit fix` | Verified clean `npm audit` |
| BUG-13 | P2 | Plaintext logging of sensitive tokens, OTPs, and birth data | Pino logger lacked field-level redact paths, allowing raw tokens or sensitive birth parameters to appear in verbose logs | `src/utils/logger.ts` | Added Pino `redact.paths` for `otp`, `token`, `password`, `jwt`, `authorization`, `razorpay_signature`, `dob`, `tob`, `pob` | Verified clean compiled output and log output |
| BUG-14 | P2 | Health readiness probe failure scenarios lacked automated tests | Existing health test only verified 200 ok scenario | `src/tests/health.test.ts` | Added test cases for 503 (database down) and 200 (redis degraded) | Verified in `health.test.ts` (7/7 passed) |
| BUG-15 | P1 | Live database was missing migration 0013 and spatial GIST index | Standalone SQL migration was not executed on the active Neon DB | `drizzle/0013_consultations_and_kundli_orders.sql`, `src/db/verify_staging_db.ts` | Executed migration and GIST index on `pandits.location` inside transaction with explicit user authorization | Verified via `verify_staging_db.ts` |
| BUG-16 | P1 | Payment webhook smoke test conflated missing config (500) with signature validation | `live_smoke.ts` accepted `[401, 500]`, masking unconfigured secret as a pass; unit tests lacked separated business processing paths | `src/tests/live_smoke.ts`, `src/tests/payments.test.ts` | Separated signature security validation from business processing and idempotency in `payments.test.ts` (now 24 tests); updated `live_smoke.ts` to diagnose 500 CONFIGURATION_ERROR | Verified in `payments.test.ts` (24/24 passed) & `live_smoke.ts` |
| BUG-17 | P1 | SMS OTP delivery lacked standalone provider integration tests & dynamic production guard | `sms.service.ts` was only mocked in auth tests; runtime `env.nodeEnv` check failed dynamic production testing | `src/services/sms.service.ts`, `src/tests/sms.test.ts`, `src/tests/auth.test.ts` | Created `src/tests/sms.test.ts` (5 tests) testing Fast2SMS API integration; updated `sms.service.ts` to check `process.env.NODE_ENV === "production"`; added test in `auth.test.ts` clarifying endpoint response vs carrier SMS | Verified in `sms.test.ts` (5/5 passed) & `auth.test.ts` (12/12 passed) |
| BUG-18 | P1 | Admin Verification Desk exposed in normal mobile app drawer | `app_side_drawer.dart` and `main.dart` included `/admin-dashboard` route without mobile-role restrictions | `app_side_drawer.dart`, `main.dart` | Removed drawer tile and route from mobile application; separated into standalone Admin Portal | Verified in `flutter test` & route inspection |
| BUG-19 | P1 | Absence of dedicated Admin email/password scrypt authentication | Admins relied on phone OTP or simulated credentials without persistent passwords | `src/db/schema/users.ts`, `src/utils/password.ts`, `src/controllers/admin-auth.controller.ts`, `src/routes/admin.routes.ts` | Added `password_hash` & `password_salt` to `users`; built scrypt hashing and `POST /api/v1/admin/auth/login` with strict rate limiting; provisioned initial admin | Verified in `admin_auth.test.ts` (13/13 passed) |
| BUG-20 | P2 | Scattered root markdown documentation and missing index | 7 historical/legacy markdown files cluttered the repository root | Root directory, `docs/` | Migrated files to `docs/audits/` and `docs/legacy/`; created authoritative root `README.md` and documentation manifest | Verified in `DOCUMENTATION_MANIFEST.md` |
| BUG-21 | P1 | Absence of upload-ready sanitized source distribution package | Repository contained untracked files, local logs, and potential secret exposure risks | Root directory | Built clean `sarvmangal-release-p7.zip` (11.44 MB) on Desktop; verified 454 files, 0 secrets, 0 clutter | Verified via extraction test script |
| BUG-22 | P1 | External providers unverified on live sandbox environments | `.env` staging lacked live API keys and test credentials | `.env` | Documented provider matrix with explicit canonical status labels (`CODE VERIFIED` vs `BLOCKED`); verified error handling and fallback behavior in unit suites | Verified in unit test suites & `docs/PROVIDER_VERIFICATION_MATRIX.md` |
| BUG-23 | P0 | Initial administrative credential exposed in documentation, UI hint, and tests | Legacy default password `Admin@SarvMangal2026!` was documented and displayed in login hint | `admin-portal/src/views/login.ts`, `src/db/provision_admin.ts`, `docs/`, `src/tests/admin_auth.test.ts` | Completely eliminated exposed credential string across all files; required explicit env variables with min 12 chars; rotated staging DB admin password to secure random 24-byte key | Verified 0 occurrences via repository-wide regex grep; DB query verified |
| BUG-24 | P1 | Administrative login susceptible to timing attacks and account enumeration | Non-existent admin accounts returned 401 immediately without running scrypt | `src/controllers/admin-auth.controller.ts` | Implemented constant-time dummy scrypt verification (`DUMMY_HASH`, `DUMMY_SALT`) for non-existent accounts; generic 401 error | Verified in `admin_auth.test.ts` (17/17 passed) |
| BUG-25 | P1 | Administrative sessions lacked short token expiry and explicit server logout endpoint | Standard JWT validity (7d) was applied to admin tokens; no server logout route existed | `src/services/jwt.service.ts`, `src/controllers/admin-auth.controller.ts`, `src/routes/admin.routes.ts`, `admin-portal/src/api.ts` | Added `signAdminToken` with 4-hour validity (`ADMIN_JWT_EXPIRES_IN=4h`); implemented `POST /api/v1/admin/auth/logout` protected by RBAC guard; wired to portal UI | Verified in `admin_auth.test.ts` (4 new logout tests) & portal build |
| BUG-26 | P1 | Admin portal lacked containerization and staging service configuration | No Dockerfile existed for admin-portal; missing from staging compose | `admin-portal/Dockerfile`, `docker-compose.staging.yml` | Created multi-stage Dockerfile with Nginx security headers and SPA routing; added `admin-portal` service on port 3000 | Verified Docker build config & compose syntax |
| BUG-27 | P0 | Stateless administrative JWT tokens remained valid on server after logout | Admin logout was previously stateless and did not track or revoke issued JWT tokens | `src/middleware/verify-token.ts`, `src/services/jwt.service.ts`, `src/services/token-revocation.service.ts`, `src/controllers/admin-auth.controller.ts` | Created `TokenRevocationService` with SHA-256 token hashing, UUID `jti` injection, Redis denylist with remaining TTL, and in-memory TTL Map fallback; enforced in `verifyToken` middleware returning HTTP 401 `TOKEN_REVOKED` | Verified in `src/tests/admin_auth.test.ts` (21/21 passed) and live staging smoke suite steps 22, 23, 24 |
| BUG-28 | P2 | Database configuration ambiguity in Docker Compose | `docker-compose.staging.yml` had static local postgis connection string without documenting relationship to managed AWS Neon database | `docker-compose.staging.yml` | Made `DATABASE_URL` configurable via environment with default to local isolated postgis container and clear operator instructions | Verified via Compose syntax and documentation audit |
| BUG-29 | P1 | Premature Pandit profile approval without mantra video recording verification | `adminApprovePandit` did not guard against unreviewed or rejected mantra recordings | `src/services/pandit-verification.service.ts` | Added server-side check requiring `pandit.mantraRecordingStatus === "APPROVED"` before granting authorization | Verified in `mantra_recording.test.ts` & `pandits_onboarding.test.ts` |
| BUG-30 | P2 | Hardcoded mantras in client prevented administrator customization | Approved mantras were statically declared in mobile code | `src/db/schema/pandits.ts`, `src/services/pandit-verification.service.ts`, `admin-portal/src/views/tabs/pandits.ts` | Migrated mantras to PostgreSQL `approved_mantras` table (0016 migration), added public API `GET /api/v1/pandits/mantras`, and Admin Portal CRUD desk | Verified in `mantra_recording.test.ts`, `pandit_onboarding_test.dart`, and Admin Portal build |

---

## 3. Phase Development

| Phase | Objective | Status | Completed Deliverables | Dependencies & Next Steps |
|---|---|---|---|---|
| **Phase P1** | Core Foundation & Excel Catalogs | **Completed** | 26 Poojas, 156 Samagri items, 1,267 Products seeded; Auth & Profiles | Next: Maintain data integrity |
| **Phase P2-A** | Booking & Location Dispatch | **Completed** | PostGIS dispatch, Redis Geo search, booking lifecycle, Socket.IO requests | Completed |
| **Phase P2-B** | Pandit Duty & Onboarding Workflows | **Completed** | Duty toggle, KYC document upload, accept/decline, cash Dakshina, product store orders | Completed |
| **Phase P2-C** | Admin Verification & Desk Dashboard | **Completed** | Admin stats API, KYC queue, document approval/rejection, subscriptions oversight, Flutter dashboard | Completed |
| **Phase P3** | Persistent Consultations & Kundli Workflows | **Completed** | Consultation & Kundli Drizzle schemas, migrations, backend APIs, state machines, Razorpay payment verification, Admin 5-tab dashboard, devotee modals | Completed |
| **Phase P4** | Staging Readiness, Security Validation & Pandit GPS Telemetry | **Completed** | Health probes (`/health/live`, `/health/ready`), request correlation (`x-request-id`), graceful shutdown, continuous GPS telemetry (`POST /me/telemetry`), 10m dispatch freshness threshold, Flutter telemetry loop, live vs last-known devotee tracking badge, `docs/STAGING_DEPLOYMENT.md` | Completed |
| **Phase P5** | Staging Cloud Deployment & Live Database Verification | **Completed** | Live Neon PostgreSQL 18.6 & PostGIS 3.6.4 verified; applied migration 0013 and spatial index `idx_pandits_location_gist`; 16-point live HTTP smoke test suite; Pino sensitive field redaction; Dockerfile and docker-compose.staging.yml | Completed |
| **Phase P6** | Real-Device Validation & Release Readiness | **Completed** | Resolved payment webhook smoke test gap; separated signature security validation from business processing and idempotency (`payments.test.ts` expanded to 24 tests); separated OTP endpoint contract from carrier SMS delivery with dedicated `sms.test.ts` (5 tests); validated total 260 backend tests; validated 98 Flutter tests; created `docs/PHASE_P6_REPORT.md`; detailed physical Android 12-point manual verification checklist. | Completed |
| **Phase P7** | Product Audit, UI Architecture, Admin Separation & Cleanup | **Completed** | Full feature/API inventory; Centralized UI Design System (`AppColors`, `AppTheme`, `Sarv*` widgets); Standalone Admin Portal (`admin-portal/`); scrypt password authentication (`POST /api/v1/admin/auth/login`); `sarvmangal-release-p7.zip` | Completed |
| **Phase P8** | Security Hardening, End-to-End Validation & Staging Deployment | **Completed (Staging Ready; Cloud & Device Beta Blocked)** | Complete remediation of initial admin credential; database staging admin password rotated to random key; timing-safe dummy scrypt check; short-lived admin sessions (4h); `POST /api/v1/admin/auth/logout`; 277 backend tests passing; 104 Flutter tests passing; admin portal containerized; clean `sarvmangal-release-p8.zip` (11.46 MB, 460 files) | Next: Staging hosting infrastructure and physical Android device beta |
| **Phase P11/P12** | Mantra Video Upload Verification (Sole Verification Method) | **Completed** | Completely removed video call appointment scheduling and selector cards from onboarding; implemented Mantra Video Verification with dynamic catalog (`approved_mantras` DB table & migration 0016), Admin Mantra Management desk, mobile video recording studio (4:3 viewfinder, timer, waveforms, preview slider), authentic ISO BMFF MP4 synthesizer, magic bytes validation, 50MB file size limit, Admin Portal HTML5 `<video>` player, and server-side premature approval safeguard | Next: Real-device camera/mic physical verification on Android handset |


---

## 4. Feature List & Inventory

| Feature ID | Module | Feature Description | Status | Frontend Evidence | Backend Evidence | Persistence | Integration | Tests | Gap / Blocker | Priority | Next Action |
|---|---|---|---|---|---|---|---|---|---|---|---|
| AUTH-01 | Auth | Devotee mobile login | Implemented and verified | `yajman_login_screen.dart` | `POST /api/v1/auth/send-otp` | `users` table | Fast2SMS (Mock in dev) | `auth.test.ts` (12), `sms.test.ts` (5), `yajman_login_test.dart` | Live carrier SMS credentials | P1 | Configure production Fast2SMS key |
| AUTH-02 | Auth | Indian mobile validation | Implemented and verified | `yajman_login_screen.dart` | `auth.validator.ts` | Memory regex | None | `auth.test.ts` | None | P2 | None |
| AUTH-03 | Auth | OTP generation & verification | Implemented and verified | `yajman_otp_screen.dart` | `auth.service.ts` | Redis / DB | SMS service | `auth.test.ts`, `sms.test.ts` | Fast2SMS live credits | P1 | Add production API key |
| AUTH-04 | Auth | JWT session & role issuance | Implemented and verified | `api_service.dart` | `auth.service.ts` | Signed JWT | None | `auth.test.ts`, `admin.test.ts` | None | P0 | None |
| AUTH-05 | Auth | Profile view and edit | Implemented and verified | `user_profile_detail_screen.dart` | `users.routes.ts` | `users` table | None | `users.test.ts` | None | P2 | None |
| HOME-01 | Home | Service tiles & navigation | Implemented and verified | `home_screen.dart` | API endpoints | N/A | None | `widget_test.dart` | None | P2 | None |
| HOME-02 | Home | Official SARV MANGAL branding | Implemented and verified | `branding.dart` | None | N/A | None | `admin_dashboard_test.dart` | None | P2 | Maintain consistency |
| POOJA-01 | Catalog | 26 Pooja catalog listing | Implemented and verified | `book_screen.dart` | `GET /api/v1/poojas` | `poojas` table (26 rows) | None | `poojas.test.ts` | None | P2 | None |
| POOJA-02 | Catalog | 156 Samagri items & toggles | Implemented and verified | `pooja_booking_flow_screen.dart` | `poojas.routes.ts` | `samagri_items` | None | `bookings.test.ts` | None | P2 | None |
| BOOK-01 | Booking | Pooja booking form & creation | Implemented and verified | `pooja_booking_flow_screen.dart` | `POST /api/v1/bookings` | `bookings` table | None | `bookings.test.ts` | None | P1 | None |
| BOOK-02 | Dispatch | PostGIS & Redis Geo dispatch | Implemented and verified | N/A (Backend) | `dispatch.service.ts` | Redis Geo & PostGIS | Redis | `dispatch.test.ts` | None | P1 | None |
| BOOK-03 | Dispatch | Pandit accept/decline flow | Implemented and verified | `pooja_request_modal.dart` | `pandits.routes.ts` | `booking_declines` | Socket.IO | `pandits.test.ts` | None | P1 | None |
| BOOK-04 | Tracking | Devotee live booking tracking | Implemented and verified | `live_pooja_tracking_screen.dart` | `tracking.routes.ts` | Redis / PostGIS | Socket.IO | `tracking.test.ts`, `pandit_telemetry_and_tracking_test.dart` | None | P1 | None |
| TEL-01 | Telemetry | Continuous Pandit GPS telemetry | Implemented and verified | `pandit_dashboard_screen.dart` | `POST /api/v1/pandits/me/telemetry` | Redis GEO & `pandits` table | Socket.IO | `telemetry.test.ts`, `pandit_telemetry_and_tracking_test.dart` | Physical handset connection | P1 | Connect physical Android device |
| OPS-01 | Ops | Liveness & Readiness probes | Implemented and verified | N/A (Backend) | `GET /health/live`, `GET /health/ready` | Postgres & Redis ping | Node.js | `health.test.ts`, `live_smoke.ts` | None | P1 | None |
| KYC-01 | Onboarding | Pandit profile & application | Implemented and verified | `pandit_onboarding_screen.dart` | `POST /api/v1/pandits/apply` | `pandits` table | None | `pandits_onboarding.test.ts` | None | P1 | None |
| KYC-02 | Onboarding | Secure document upload & verify | Implemented and verified | `pandit_onboarding_screen.dart` | `pandits.routes.ts` | `storage/documents` | Filesystem | `pandits_onboarding.test.ts` | None | P1 | None |
| KYC-03 | Onboarding | Pandit duty status toggle | Implemented and verified | `pandit_dashboard_screen.dart` | `PATCH /duty-status` | `pandits` table | Redis Geo | `pandit_duty_status_test.dart` | None | P1 | None |
| KYC-04 | Onboarding | Mantra Video Upload Verification (Sole Method) | Implemented and verified | `pandit_onboarding_screen.dart` | `POST /api/v1/pandits/me/mantra-recordings`, `GET /api/v1/pandits/mantras` | `pandit_mantra_recordings`, `approved_mantras` | Filesystem + DB | `mantra_recording.test.ts` (21), `pandit_onboarding_test.dart` (10) | None | P1 | None |
| ADM-01 | Admin | Admin stats overview | Implemented and verified | `admin_dashboard_screen.dart` | `GET /api/v1/admin/stats` | Real DB counts | None | `admin.test.ts`, `admin_dashboard_test.dart` | None | P1 | None |
| ADM-02 | Admin | Pandit KYC verification queue | Implemented and verified | `admin_dashboard_screen.dart` | `GET /api/v1/admin/pandits` | `pandits` + `documents` | None | `admin.test.ts`, `admin_dashboard_test.dart` | None | P1 | None |
| ADM-03 | Admin | Application approval/rejection | Implemented and verified | `admin_dashboard_screen.dart` | `PATCH /admin/pandits/approval` | `pandits` table | None | `admin.test.ts` | None | P1 | None |
| ADM-04 | Admin | Subscriptions oversight | Implemented and verified | `admin_dashboard_screen.dart` | `GET /admin/subscriptions` | `subscriptions` | None | `admin.test.ts`, `admin_dashboard_test.dart` | None | P2 | None |
| ADM-05 | Admin | Consultation Desk queue & actions | Implemented and verified | `admin_dashboard_screen.dart` | `GET/PATCH /api/v1/admin/consultations` | `consultations` table | Socket.IO | `consultations.test.ts`, `admin_dashboard_test.dart` | None | P1 | None |
| ADM-06 | Admin | Kundli Orders queue & fulfilment | Implemented and verified | `admin_dashboard_screen.dart` | `GET/PATCH /api/v1/admin/kundli-orders` | `kundli_orders` table | Postal / Speed Post | `kundli_orders.test.ts`, `admin_dashboard_test.dart` | None | P1 | None |
| ADM-07 | Admin | Mantra Review Queue & Video Stream | Implemented and verified | `admin-portal` (`pandits.ts`) | `admin.routes.ts` | `pandit_mantra_recordings` + streaming | HTML5 Video API | `mantra_recording.test.ts` (21) | None | P1 | None |
| ADM-08 | Admin | Admin Approved Mantras CRUD Desk | Implemented and verified | `admin-portal` (`pandits.ts`) | `GET/POST/PATCH/DELETE /api/v1/admin/mantras` | `approved_mantras` table | None | `mantra_recording.test.ts` (21) | None | P1 | None |
| CONS-01 | Consultation | Vedic consultation creation | Implemented and verified | `consultation_flow_modal.dart` | `POST /api/v1/consultations` | `consultations` table | None | `consultations.test.ts`, `consultation_flow_modal_test.dart` | None | P1 | None |
| CONS-02 | Consultation | Consultation lifecycle & scheduling | Implemented and verified | `admin_dashboard_screen.dart` | `PATCH /consultations/:id/schedule` | `consultations` table | Socket.IO | `consultations.test.ts` | None | P1 | None |
| CONS-03 | Consultation | Consultation Razorpay payment | Implemented and verified | `api_service.dart` | `POST /consultations/:id/payment` | `consultations` table | Razorpay SDK | `consultations.test.ts` | Live Razorpay key | P1 | None |
| KUNDLI-01 | Kundli | Birth details submission & reference | Implemented and verified | `handmade_kundli_order_modal.dart` | `POST /api/v1/kundli-orders` | `kundli_orders` table | None | `kundli_orders.test.ts`, `kundli_and_chat_test.dart` | None | P1 | None |
| KUNDLI-02 | Kundli | Kundli review, assignment & tracking | Implemented and verified | `admin_dashboard_screen.dart` | `PATCH /admin/kundli-orders/:id/*` | `kundli_orders` table | Speed Post tracking | `kundli_orders.test.ts` | None | P1 | None |
| KUNDLI-03 | Kundli | Kundli payment order & verify | Implemented and verified | `api_service.dart` | `POST /kundli-orders/:id/payment/*` | `kundli_orders` table | Razorpay SDK | `kundli_orders.test.ts` | Live Razorpay key | P1 | None |
| TMPL-01 | Temples | Nearby temple discovery | Configured, mock fallback | `nearest_temple_screen.dart` | `temples.routes.ts` | Redis cache | Google Places | `temples.test.ts` | Blocked by live Google Places API key | P2 | Add production key |
| SUB-01 | Subscriptions | Phool Mala subscriptions | Configured, mock fallback | `phool_mala_screen.dart` | `subscriptions.routes.ts` | `subscriptions` | Razorpay | `subscriptions.test.ts` | Blocked by live Razorpay plan webhook secret | P2 | Connect webhook secret |
| PAY-01 | Payments | Dakshina cash collection | Implemented and verified | `pandit_dashboard_screen.dart` | `bookings.routes.ts` | `dakshina_collections` | None | `dakshina.test.ts` | None | P1 | None |
| PAY-02 | Payments | Razorpay signature & webhook processing | Implemented and verified | `api_service.dart` | `payments.routes.ts` | `bookings`, `product_orders` | Razorpay SDK | `payments.test.ts` (24 tests) | Blocked by live Razorpay credentials | P1 | Add production key & secret |
| PROD-01 | Store | Store catalog & cart | Implemented and verified | `shop_screen.dart`, `cart_screen.dart` | `products.routes.ts` | `products` table (1,267 rows) | None | `cart_and_checkout_test.dart` | None | P2 | None |
| PROD-02 | Store | Order checkout & server validation | Implemented and verified | `checkout_screen.dart` | `product-orders.routes.ts` | `product_orders` | Razorpay | `product_orders.test.ts` | None | P1 | None |
| GUID-01 | Assistant | Vedic guidance chat assistant | Implemented and verified | `pandit_chat_modal.dart` | N/A (Local FAQs) | Local state | None | `kundli_and_chat_test.dart` | LLM backend integration | P3 | Optional LLM integration |
| NOTIF-01 | Push | FCM push notifications | Blocked by credentials | `api_service.dart` | `notification.service.ts` | `users.fcmToken` | Firebase Admin | `notification.test.ts` | Blocked by Firebase service account JSON | P2 | Add service account JSON |
| VID-01 | Calling | Video verification call service | Removed from Onboarding | N/A (Removed from onboarding) | `agora.service.ts` | `pandits` table | Agora RTC | `agora.test.ts` | Replaced by Mantra Video Verification in onboarding; consultation video calls remain active for devotees | P2 | None |
| UI-01 | Design | Centralized Tokenized Design System | Implemented and verified | `theme/app_theme.dart`, `theme/app_colors.dart`, `widgets/common/sarv_button.dart` | N/A | None | Material 3 | `theme_widgets_test.dart` (6 tests) | None | P1 | Standardize remaining custom screens |

---

## 5. Current Status

- **Status Date:** 2026-10-26
- **Current Git Branch:** `main`
- **Working Tree Status:** Mantra Video Upload Verification for Pandit Onboarding fully implemented as the sole verification method (completely removing video call appointment scheduling, date/time pickers, and dual-option cards). Dynamic approved mantras fetched from DB (`approved_mantras` table seeded with 5 Sanskrit mantras), Admin Portal Mantra Management desk (`/api/v1/admin/mantras`), mobile video recording studio (camera/mic gating, 4:3 viewfinder, live REC badge, 2-minute countdown timer, waveform bars, preview seek slider, authentic ISO BMFF MP4 synthesizer), 50MB file size & magic bytes validation, Admin Portal HTML5 `<video controls playsinline>` player, and server-side safeguard blocking Pandit approval without approved mantra video recording.
- **Latest Automated Test Run Results:**
  - `npm run typecheck`: **Exit code 0 (0 errors)**
  - `npm run test`: **Exit code 0 (26 test files, 311 passed, 0 failed)**
  - `npm run build`: **Exit code 0 (Clean TypeScript compile to `dist/`)**
  - `flutter analyze`: **Exit code 0 (0 issues found)**
  - `flutter test`: **Exit code 0 (19 test files, 120 passed, 0 failed)**
  - `admin-portal` build: **Exit code 0 (Vite production bundle generated in 373ms)**
  - Database Migration `0016_create_approved_mantras.sql`: **VERIFIED (applied on Neon PostgreSQL live database; approved_mantras table created and seeded, verification_method default migrated to 'MANTRA_VIDEO')**
- **Release Documentation:** Detailed breakdown in `docs/reports/PHASE_MANTRA_VERIFICATION_REPORT.md`.

- **External Provider Classification Matrix (Canonical Statuses):**
  1. **PostgreSQL + PostGIS (AWS Neon):** `VERIFIED`. (Live cloud instance with 23 tables, PostGIS 3.6.4, GIST spatial index, rotated credentials).
  2. **Distributed Token Revocation Engine:** `VERIFIED`. (Proven across two independently initialized instances sharing Redis; TTL matches token expiry; fail-closed policy enforced).
  3. **Razorpay:** `CODE VERIFIED`. (HMAC signature verification, payment state transitions, and Redis/DB idempotency passing in 24 tests; live keys absent in staging).
  4. **Fast2SMS:** `CODE VERIFIED`. (Bulk V2 integration with 5s timeout, phone sanitization, and production error guard passing in 5 tests; development mock fallback active).
  5. **Firebase FCM:** `CODE VERIFIED`. (Service account loading, token auto-purge passing in 4 tests; push notifications safely skipped when absent).
  6. **Google Places:** `CODE VERIFIED`. (Geohash Redis caching and empty array fallback passing in 3 tests; `GOOGLE_PLACES_API_KEY` absent).
  7. **Agora RTC:** `CODE VERIFIED`. (Server-side RTC token builder passing in 2 tests; `AGORA_APP_ID` absent).
  8. **Redis:** `CODE VERIFIED`. (Multi-instance distributed revocation verified; ready for external Redis cluster URL).
  9. **Docker Engine / Compose:** `BLOCKED`. (Docker CLI not installed on host machine; static configuration verified).
  10. **Physical Android GPS Hardware:** `BLOCKED`. (Manual 12-point protocol documented in `docs/reports/PHASE_P10_REPORT.md`; physical handset and Android SDK required).
- **Physical Device GPS Telemetry Status:**
  - Verified logic in backend tests and Flutter widget test suites.
  - Distinguishes "Live GPS (< 5m)" vs "Last Known" vs "Location Unavailable".
  - Physical Android background GPS remains blocked until Android SDK and physical device are connected; 12-point manual protocol documented in `docs/reports/PHASE_P10_REPORT.md`.
- **Cloud Infrastructure Status:**
  - Multi-stage `Dockerfile` (non-root `appuser`, built-in health probe), `admin-portal/Dockerfile` (Nginx reverse proxy, security headers), and `docker-compose.staging.yml` prepared with explicit DB disambiguation.
  - Remote cloud deployment (AWS/Render/Railway) marked as blocked pending cloud account credentials or deployment CLI authorization.
- **Official Release Decision:**
  - **LOCALLY VALIDATED — DEPLOYMENT BLOCKED**.
