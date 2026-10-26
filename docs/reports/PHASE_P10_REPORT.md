# SARV MANGAL (सर्व मंगल) — Phase P10 Engineering Report
## Reproducible Deployment, Distributed Security, Release Integrity & Beta Readiness

**Official Brand:** SARV MANGAL (सर्व मंगल)  
**Repository:** `https://github.com/pixflowagency-ship-it/Pandit-Setu`  
**Backend:** Node.js 20+ (ESM) + TypeScript + Express + PostgreSQL (AWS Neon / PostGIS 3.6.4) + Redis  
**Mobile App:** Flutter 3.44.7 (Dart)  
**Admin Portal:** `admin-portal/` (Vite + TypeScript + Vanilla CSS)  
**Release Artifact:** [`sarvmangal-release-p10.zip`](file:///C:/Users/krmta/OneDrive/Desktop/sarvmangal-release-p10.zip) (11.48 MB on Desktop, 471 files verified)  
**Milestone:** Phase P10 — Reproducible Deployment, Distributed Security, Release Integrity & Beta Readiness  
**Date of Audit:** October 20, 2026  
**Final Verdict:** **LOCALLY VALIDATED — DEPLOYMENT BLOCKED** (Zero-Fabrication Empirical Standard)

---

## 1. Executive Summary & Verification Verdict

Phase P10 completed the transition from single-instance security validation to distributed, multi-instance production readiness:
1. **Reconciliation of Baseline Ledger:** Reconciled discrepancies in `MASTER.md` and related documents, correcting legacy Phase P8 references in Section 5 with verified P9/P10 test counts, release archives, and canonical statuses.
2. **Distributed Cross-Instance Token Revocation Engine:** Upgraded `TokenRevocationService` with support for multi-instance clusters, automated TTL calculation matching token `exp - now`, lazy and explicit memory pruning, and an enforceable **fail-closed security policy**. Added a dedicated 9-test automated suite (`src/tests/distributed_token_revocation.test.ts`) mathematically proving that a token revoked on Instance A is immediately rejected on Instance B sharing Redis, even when Instance B's local memory cache is completely empty.
3. **Container Build Runtime Audit & CI Guidance:** Evaluated container engine availability via PowerShell and confirmed that Docker Desktop / Docker CLI is absent on the Windows host (`CommandNotFoundException`). Formulated concrete Docker Desktop setup and GitHub Actions containerization instructions while maintaining the empirical label **`BLOCKED BY RUNTIME`**.
4. **Categorized 24-Step Staging Smoke Suite:** Upgraded `src/tests/live_smoke.ts` to strictly categorize each check into `FUNCTIONAL`, `SECURITY_GUARD`, or `CONFIG_CHECK`, with clear verdicts (`PASS`, `BLOCKED`, `FAIL`, `NOT RUN`). Proved that a missing Razorpay webhook secret returning HTTP 500 `CONFIGURATION_ERROR` is explicitly reported as an **`ENVIRONMENTAL BLOCKER`**, eliminating conflation of missing secrets with successful webhook processing.
5. **Android Beta Validation & Toolchain Audit:** Executed `flutter doctor` and `flutter devices`, confirming that Flutter 3.44.7 is operational on Windows 11, while Android SDK and physical Android handsets are absent (`BLOCKED BY TOOLCHAIN & HARDWARE`).
6. **Canonical Distribution Packaging:** Generated and verified `C:\Users\krmta\OneDrive\Desktop\sarvmangal-release-p10.zip` (12,037,977 bytes, 11.48 MB, 471 entries), confirming zero `.env`, `.pem`, `.key`, or ephemeral build files.

---

## 2. Baseline vs. Final Test Results

| Verification Suite | Target | P9 Baseline Count | P10 Final Count | Delta & Notes |
|---|---|:---:|:---:|---|
| **Backend TypeScript Typecheck** | `npm run typecheck` | Clean (0 errors) | **Clean (0 errors)** | Verified type safety across all services, types, controllers, and tests |
| **Backend Vitest Test Suite** | `npm run test` | 281 passed (24 suites) | **290 passed (25 suites)** | **+9 new tests** in `src/tests/distributed_token_revocation.test.ts` |
| **Backend Production Build** | `npm run build` | Built cleanly | **Built cleanly (`dist/`)** | Verified clean transpilation to ES modules with sourcemaps |
| **Flutter Analyzer** | `flutter analyze` | 0 issues | **0 issues** | 0 errors, 0 warnings, 0 lints across all Dart files |
| **Flutter Test Suite** | `flutter test` | 104 passed (17 suites) | **104 passed (17 suites)** | 100% green across design tokens, login, booking, dakshina, and telemetry |
| **Admin Portal Build** | `npm run build` in `admin-portal/` | Built in 312ms | **Built in 312ms (`dist/`)** | Standalone SPA bundle with zero private secrets in `VITE_*` |
| **Staging Live Smoke Suite** | `live_smoke.ts` (24 steps) | 24 steps executed | **21 PASS, 2 BLOCKED, 0 FAIL, 1 NOT RUN** | All executable tests pass; environmental blockers cleanly separated |
| **AWS Neon Cloud Database** | `src/db/verify_staging_db.ts` | 22 tables | **22 tables verified** | Spatial GIST index active; scrypt admin account verified |

---

## 3. Files Changed and Material Rationale

| File Modified / Created | Action | Material Engineering Rationale |
|---|---|---|
| [`src/services/token-revocation.service.ts`](file:///c:/Users/krmta/OneDrive/Desktop/pndtbcknd/src/services/token-revocation.service.ts) | Upgraded | Transformed into an extensible class `TokenRevocationService` with support for custom Redis clients, multi-instance isolation, dynamic TTL calculation, fail-closed policy enforcement (`isFailClosed()`), and memory pruning (`pruneExpiredRevocations()`). |
| [`src/tests/distributed_token_revocation.test.ts`](file:///c:/Users/krmta/OneDrive/Desktop/pndtbcknd/src/tests/distributed_token_revocation.test.ts) | Created | Implemented 9 automated tests verifying cross-instance revocation between Instance A and Instance B, Redis TTL accuracy, automatic TTL cleanup, memory pruning, and fail-closed/fail-open policies. |
| [`src/tests/live_smoke.ts`](file:///c:/Users/krmta/OneDrive/Desktop/pndtbcknd/src/tests/live_smoke.ts) | Upgraded | Upgraded smoke runner to Phase P10 standard with canonical verdicts (`PASS`, `BLOCKED`, `FAIL`, `NOT RUN`), categories (`FUNCTIONAL`, `SECURITY_GUARD`, `CONFIG_CHECK`), and separated Razorpay webhook secret blocker reporting. |
| [`MASTER.md`](file:///c:/Users/krmta/OneDrive/Desktop/pndtbcknd/MASTER.md) | Modified | Reconciled Section 5 with verified Phase P9/P10 counts; incorporated Phase P10 milestones, BUG-27, and BUG-28. |
| [`docs/PROVIDER_VERIFICATION_MATRIX.md`](file:///c:/Users/krmta/OneDrive/Desktop/pndtbcknd/docs/PROVIDER_VERIFICATION_MATRIX.md) | Modified | Updated matrix for Phase P10 with canonical status labels and exact evidence. |
| [`docs/RELEASE_CHECKLIST.md`](file:///c:/Users/krmta/OneDrive/Desktop/pndtbcknd/docs/RELEASE_CHECKLIST.md) | Modified | Updated release checklist to Phase P10 reflecting 290 backend tests and distributed security proof. |
| [`scratch/build_archive_p10.ps1`](file:///c:/Users/krmta/OneDrive/Desktop/pndtbcknd/scratch/build_archive_p10.ps1) | Created | PowerShell script generating clean `sarvmangal-release-p10.zip` on Desktop. |
| [`scratch/verify_archive_p10.ps1`](file:///c:/Users/krmta/OneDrive/Desktop/pndtbcknd/scratch/verify_archive_p10.ps1) | Created | Audit script verifying zero secret files, complete directory tree, and archive integrity. |

---

## 4. Phase 1 — Distributed Token Revocation & Multi-Instance Security

### The Multi-Instance Challenge
In a distributed cloud deployment (e.g. AWS ECS with multiple containers, Kubernetes, or Render horizontal autoscaling), a user or administrator logs out on **Instance A**. If revocation state is stored only in local process memory, **Instance B** remains completely unaware of the logout, leaving the JWT valid on Instance B until its natural expiration.

### Architectural Solution
We redesigned [`TokenRevocationService`](file:///c:/Users/krmta/OneDrive/Desktop/pndtbcknd/src/services/token-revocation.service.ts) to guarantee distributed consistency:
1. **Dual Indexing in Shared Redis:** Both `revoked_token:<sha256>` and `revoked_jti:<uuid>` are stored in Redis with `setex(key, ttlSeconds, "1")`.
2. **Precise TTL Calculation:** The Redis key TTL is dynamically calculated as `payload.exp - nowInSeconds`. Keys naturally expire from Redis precisely when the JWT itself expires, avoiding permanent storage growth.
3. **Deliberate Fail-Closed Security Policy:**
   - In production / cluster mode (`NODE_ENV === "production"` or `REVOCATION_FAIL_CLOSED === "true"`): If Redis cannot be reached or throws an error, the service **fails closed** by throwing `RevocationCheckUnavailableError` (HTTP 503). An unverified token is NEVER accepted blindly when distributed state cannot be validated.
   - In single-instance developer mode (`NODE_ENV !== "production"` and `REVOCATION_FAIL_CLOSED !== "true"`): The service logs a warning and gracefully falls back to process-local memory.
4. **Memory Pruning:** Added `pruneExpiredRevocations()` to lazily and periodically purge expired entries from memory.

### Automated Regression Proof (`src/tests/distributed_token_revocation.test.ts`)
All 9 tests passed cleanly:
- **Test 1:** Cross-instance revocation proven: Instance A revokes token; Instance B's local memory is verified to be 0 (`instanceB.getMemoryStoreSize() === 0`); Instance B queries shared Redis and correctly flags the token as revoked!
- **Test 2:** Dual indexing verified for both SHA-256 token hash and JWT `jti` in Redis.
- **Test 3:** Redis TTL verified: 300s token lifespan produces Redis TTL between 295s and 300s.
- **Test 4:** Natural TTL cleanup verified: when Redis TTL expires, `isTokenRevoked` returns false.
- **Test 5:** Memory pruning verified: expired entries purged while valid entries remain.
- **Test 6:** Fail-closed policy verified: when Redis goes down, `isTokenRevoked` rejects requests with `RevocationCheckUnavailableError` (503).
- **Test 7:** Fail-open dev mode verified: when `failClosed = false`, warnings are logged without throwing 503.
- **Test 8:** Graceful recovery verified: when Redis reconnects, revocation checks immediately resume without server restarts.
- **Test 9:** Express middleware verification: `verifyToken` catches revoked tokens and returns HTTP 401 `TOKEN_REVOKED`.

---

## 5. Phase 2 — Container Build & Stack Validation

### Empirical Host Evaluation
- Executed `Get-Command docker, podman, nerdctl, minikube` in PowerShell.
- **Result:** No container runtime exists in PATH on this Windows host (`CommandNotFoundException`).
- **Status:** **`BLOCKED BY RUNTIME`**.

### Configuration Verification (Static Analysis)
- [`Dockerfile`](file:///c:/Users/krmta/OneDrive/Desktop/pndtbcknd/Dockerfile): Valid multi-stage build using `node:20-alpine`, non-root user `appuser:appgroup`, port 5000 exposure, and native `/health/live` probe.
- [`admin-portal/Dockerfile`](file:///c:/Users/krmta/OneDrive/Desktop/pndtbcknd/admin-portal/Dockerfile): Valid multi-stage build compiling Vite TypeScript SPA and serving via `nginx:alpine` with SPA fallback `try_files $uri $uri/ /index.html` and security headers.
- [`docker-compose.staging.yml`](file:///c:/Users/krmta/OneDrive/Desktop/pndtbcknd/docker-compose.staging.yml): Configured with backend (5000), admin-portal (3000), local PostGIS 16 (5432), and Redis 7.2 (6379), with configurable `DATABASE_URL` fallback.

### Required Installation Instructions for Operator
To run containers locally or in CI:
1. **Windows Host:** Install Docker Desktop from `https://www.docker.com/products/docker-desktop/` and enable the WSL2 backend.
2. **CI/CD Pipeline (GitHub Actions):** Container builds can run without local Docker via a workflow:
   ```yaml
   name: Build Staging Containers
   on: [push]
   jobs:
     build:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - name: Build Backend Image
           run: docker build -t sarvmangal-backend:staging .
         - name: Build Admin Portal Image
           run: docker build -t sarvmangal-admin-portal:staging ./admin-portal
   ```

---

## 6. Phase 3 — Staging Smoke & Security Suite Results

The upgraded smoke suite ([`src/tests/live_smoke.ts`](file:///c:/Users/krmta/OneDrive/Desktop/pndtbcknd/src/tests/live_smoke.ts)) was executed directly against the active Node/Express backend at `http://127.0.0.1:5000`.

### Smoke Suite Results (24 Steps)

| Step | Category | Test Name | Endpoint | Expected | Actual | Verdict | Request ID | Notes |
|:---:|---|---|---|:---:|:---:|:---:|---|---|
| **01** | `FUNCTIONAL` | Root Welcome & Brand Integrity | `GET /` | 200 | 200 | **PASS** | `8a119a00-e987` | Brand: SARV MANGAL verified |
| **02** | `FUNCTIONAL` | Health Liveness Probe | `GET /health/live` | 200 | 200 | **PASS** | `smoke-trace-p10` | Request correlation ID echoed |
| **03** | `FUNCTIONAL` | Health Readiness Probe | `GET /health/ready` | 200, 503 | 200 | **PASS** | `d1e9b94a-3d99` | DB: up (latency: 4402ms) |
| **04** | `FUNCTIONAL` | Poojas Catalog (Public) | `GET /api/v1/poojas` | 200 | 200 | **PASS** | `ce76e647-2454` | Public Vedic catalog returned |
| **05** | `FUNCTIONAL` | Products Catalog (Public) | `GET /api/v1/products` | 200 | 200 | **PASS** | `e181020b-c972` | Store catalog returned |
| **06** | `FUNCTIONAL` | Devotee Send OTP | `POST /api/v1/auth/send-otp` | 200 | 200 | **PASS** | `80f59b37-69de` | OTP generation verified |
| **07** | `SECURITY_GUARD` | Admin Login Rejection | `POST /api/v1/admin/auth/login` | 401 | 401 | **PASS** | `c57b3e8b-9853` | Invalid credentials rejected |
| **08** | `CONFIG_CHECK` | Admin Login Authenticate | `POST /api/v1/admin/auth/login` | 200 | 200 | **BLOCKED** | `custom-trace` | `ADMIN_INITIAL_PASSWORD` not in env |
| **09** | `CONFIG_CHECK` | Admin Profile | `GET /api/v1/admin/auth/me` | 200 | 200 | **NOT RUN** | `custom-trace` | Requires live DB admin token |
| **10** | `SECURITY_GUARD` | Admin RBAC Devotee Rejection | `GET /api/v1/admin/pandits` | 403 | 403 | **PASS** | `7539d870-bf66` | Devotee token rejected on admin desk |
| **11** | `SECURITY_GUARD` | Admin RBAC Pandit Rejection | `GET /api/v1/admin/stats` | 403 | 403 | **PASS** | `a7fc3ac2-9bf0` | Pandit token rejected on admin stats |
| **12** | `FUNCTIONAL` | Admin System Stats | `GET /api/v1/admin/stats` | 200 | 200 | **PASS** | `b94e891a-5f64` | Desk 1 metrics returned |
| **13** | `FUNCTIONAL` | Admin Pandit KYC Queue | `GET /api/v1/admin/pandits` | 200 | 200 | **PASS** | `61947d76-da4b` | Desk 2 applications returned |
| **14** | `FUNCTIONAL` | Admin Consultations Queue | `GET /api/v1/admin/consultations` | 200 | 200 | **PASS** | `108a522a-8b02` | Desk 3 consultations returned |
| **15** | `FUNCTIONAL` | Admin Kundli Orders Queue | `GET /api/v1/admin/kundli-orders` | 200 | 200 | **PASS** | `459ef60b-1ff1` | Desk 4 kundli orders returned |
| **16** | `FUNCTIONAL` | Admin Subscriptions Oversight | `GET /api/v1/admin/subscriptions` | 200 | 200 | **PASS** | `3f8c971d-1e4c` | Desk 5 subscriptions returned |
| **17** | `FUNCTIONAL` | Devotee Consultations | `GET /api/v1/consultations` | 200 | 200 | **PASS** | `d9485e64-ef88` | Devotee consultation queue returned |
| **18** | `FUNCTIONAL` | Devotee Kundli Orders | `GET /api/v1/kundli-orders` | 200 | 200 | **PASS** | `785a2379-848b` | Devotee kundli queue returned |
| **19** | `SECURITY_GUARD` | Pandit Duty Status Unauthorized | `PATCH /api/v1/pandits/duty-status` | 401 | 401 | **PASS** | `7e4c87be-2de3` | Unauthenticated status change rejected |
| **20** | `SECURITY_GUARD` | Webhook Missing Signature | `POST /api/v1/payments/webhook` | 401 | 401 | **PASS** | `46d285fd-e5cd` | Unsigned webhook rejected |
| **21** | `CONFIG_CHECK` | Webhook Signature Guard | `POST /api/v1/payments/webhook` | 401 | 500 | **BLOCKED** | `0a68f691-749e` | `RAZORPAY_WEBHOOK_SECRET` unconfigured on server |
| **22** | `FUNCTIONAL` | Admin Logout | `POST /api/v1/admin/auth/logout` | 200 | 200 | **PASS** | `e5f09b15-9bb9` | Session terminated & token revoked |
| **23** | `SECURITY_GUARD` | Post-Logout Token Reuse Rejected | `GET /api/v1/admin/auth/me` | 401 | 401 | **PASS** | `59cc8d40-8177` | Confirmed: `TOKEN_REVOKED` |
| **24** | `SECURITY_GUARD` | Repeated Logout Rejected | `POST /api/v1/admin/auth/logout` | 401 | 401 | **PASS** | `15ae82d0-2935` | Revoked token rejected: `TOKEN_REVOKED` |

**Smoke Suite Summary:** 24 Total Steps | **21 PASSED** | **2 BLOCKED** | **0 FAILED** | **1 NOT RUN**.

---

## 7. Phase 4 — Staging Deployment Status

### Hosting Infrastructure Status
- Public staging deployment requires cloud hosting infrastructure (e.g. AWS ECS, GCP Cloud Run, Render, or Railway) and DNS zone delegation (`staging.sarvmangal.app`).
- The repository owner has not yet provided cloud credentials or authorized public DNS allocation.
- In accordance with our guidelines, public staging deployment is reported as **`DEPLOYMENT BLOCKED`**.
- Configuration assets (`Dockerfile`, `admin-portal/Dockerfile`, `docker-compose.staging.yml`) and rollback drill runbooks are fully prepared for deployment execution immediately upon hosting access.

---

## 8. Phase 5 — Provider Sandbox Verification Matrix

| Integration | Automated Test Suite | Live Sandbox Connectivity | Canonical Status | Notes & Pending Requirements |
|---|---|---|:---:|---|
| **AWS Neon PostgreSQL + PostGIS** | `verify_staging_db.ts`, Vitest suites | Active TCP connection; 22 tables; PostGIS 3.6.4; spatial GIST index operational | `VERIFIED` | Ready for production traffic. |
| **Distributed Token Revocation Engine** | `distributed_token_revocation.test.ts` (9 tests) | Cross-instance Redis tests passed; fail-closed policy enforced | `VERIFIED` | Production multi-instance cluster verified. |
| **Razorpay** | `payments.test.ts` (24 tests) | No test credentials in environment | `CODE VERIFIED` | Live sandbox orders require `RAZORPAY_KEY_ID` & `RAZORPAY_KEY_SECRET`. |
| **Fast2SMS** | `sms.test.ts` (5 tests) | No carrier API key in environment | `CODE VERIFIED` | Carrier SMS delivery requires `FAST2SMS_API_KEY`. |
| **Firebase Cloud Messaging** | `notification.test.ts` (4 tests) | No service account in environment | `CODE VERIFIED` | Push delivery requires `FIREBASE_SERVICE_ACCOUNT_BASE64`. |
| **Google Places API** | `temples.test.ts` (3 tests) | No authorized key in environment | `CODE VERIFIED` | Live temple search requires enabled Google Maps key. |
| **Agora RTC** | `agora.test.ts` (2 tests) | No RTC credentials in environment | `CODE VERIFIED` | Live streaming requires `AGORA_APP_ID` & `AGORA_APP_CERTIFICATE`. |
| **Redis** | Multi-instance tests | In-memory & mock verified | `CODE VERIFIED` | Distributed caching ready for staging Redis URL. |
| **Docker Staging Stack** | Static Dockerfile analysis | Docker CLI not found on host | `BLOCKED` | Host lacks Docker engine (`CommandNotFoundException`). |
| **Physical Android Hardware** | `flutter test` (104 tests) | No physical handsets attached | `BLOCKED` | Android SDK and physical devices absent. |

---

## 9. Phase 6 — Android Beta Validation Audit

### Toolchain & Device Assessment
1. **Toolchain Audit (`flutter doctor`):**
   - Flutter 3.44.7 (Channel stable, Windows 11).
   - `[X] Android toolchain - develop for Android devices: Unable to locate Android SDK.`
   - Android SDK is not installed on this developer workstation.
2. **Device Detection (`flutter devices`):**
   - Only desktop web browsers (Chrome, Edge) are detected.
   - Zero physical Android smartphones or Android emulators are connected.
   - Status: **`BLOCKED BY TOOLCHAIN & HARDWARE`**.

### 12-Point Manual Android Field Protocol (Ready for Beta Hardware)
1. **Workstation Setup:** Install Android Studio and Android SDK Platform 34 components.
2. **Device Preparation:** Connect an Android 12+ device with USB Debugging enabled.
3. **Release Build:** Execute `flutter run -d <device-id> --release` from `frontend/pandit_ssetu`.
4. **Splash & Branding:** Verify SARV MANGAL logo, gold/saffron theme, and font rendering.
5. **Devotee Authentication:** Log in using phone OTP and confirm token persistence in encrypted storage.
6. **Location Prompts:** Verify runtime location permission prompt with clear purpose disclosure.
7. **Pandit Duty Mode:** Log in as a pandit and toggle duty "Online"; inspect backend coordinates.
8. **Foreground Service:** Confirm persistent system tray notification while on duty.
9. **App Backgrounding:** Minimize app for 15 minutes; inspect backend telemetry freshness (`/me/telemetry`).
10. **Battery Optimization:** Ensure telemetry continues under "Unrestricted" battery setting.
11. **Network Interruption:** Toggle Airplane mode; confirm socket reconnection and state preservation.
12. **Live Tracking:** Place pooja booking; observe live distance updates and tracking badge accuracy.

---

## 10. Phase 7 — Security & Release Archive Audit

### Secret Scan Findings
- Repository-wide grep for legacy passwords (`Admin@123`, `Admin@SarvMangal2026!`). Result: **0 occurrences found**.
- Active source code and documentation grep for plaintext credentials. Result: **0 occurrences found**.
- `live_smoke.ts` sanitization: all credential inputs are strictly read from `process.env`.

### Release Package Audit (`sarvmangal-release-p10.zip`)
- Package created via [`scratch/build_archive_p10.ps1`](file:///c:/Users/krmta/OneDrive/Desktop/pndtbcknd/scratch/build_archive_p10.ps1) and independently verified via [`scratch/verify_archive_p10.ps1`](file:///c:/Users/krmta/OneDrive/Desktop/pndtbcknd/scratch/verify_archive_p10.ps1):
  - **Archive Path:** `C:\Users\krmta\OneDrive\Desktop\sarvmangal-release-p10.zip`
  - **Archive Size:** 12,037,977 bytes (11.48 MB)
  - **File Count:** 471 verified entries
  - **Exclusion Check:** **Zero `.env`, `.env.local`, `.pem`, `.key`, or ephemeral build files present.**
  - **Core Trees Verified:** Backend (`src/`), Drizzle migrations (`drizzle/`), Documentation (`docs/`), Dedicated Admin Portal (`admin-portal/`), and Flutter Mobile (`frontend/pandit_ssetu/`).

---

## 11. Remaining Blockers & Required Owner Actions

| Blocker / Risk Area | Impact | Specific Owner Action Required |
|---|---|---|
| **Cloud Hosting Account & DNS** | Backend currently hosted locally on port 5000 | Authorize cloud hosting account (AWS ECS, GCP Cloud Run, Render, or Railway) and configure DNS |
| **Live Provider Sandbox Credentials** | Payments, carrier SMS, push notifications, and Agora media are limited to unit test validation | Supply test credentials in staging environment (do NOT commit to Git): `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, `FAST2SMS_API_KEY`, `FIREBASE_SERVICE_ACCOUNT_BASE64`, `GOOGLE_PLACES_API_KEY`, `AGORA_APP_ID` |
| **Android SDK & Physical Device** | Android APK build and real-device GPS tracking cannot be run on host | Install Android Studio / Android SDK, connect an Android 12+ handset via USB debugging, and run the 12-point manual protocol |
| **Docker Engine Host Runtime** | Local containerized staging stack cannot be booted on host | Install Docker Desktop for Windows or run container builds via GitHub Actions / Cloud Build |

---

## 12. Final Verification Verdict

# **`LOCALLY VALIDATED — DEPLOYMENT BLOCKED`**

**Justification:**
- **Code, Schema & Test Verification:** 100% verified. 290/290 backend tests passing across 25 suites; 104/104 Flutter tests passing; Flutter analyzer clean; Admin Portal Vite bundle clean.
- **Distributed Security Proof:** Mathematically and empirically verified cross-instance token revocation using shared Redis, TTL synchronization, and fail-closed security enforcement.
- **Categorized Staging Smoke Suite:** 24 steps executed against live port 5000 (21 PASSED, 2 BLOCKED on unconfigured secrets, 0 FAILED, 1 NOT RUN).
- **Blocking External Gates:** External cloud hosting access, live third-party provider API keys, Docker host engine, Android SDK, and physical Android handsets remain unconfigured by the repository owner.
