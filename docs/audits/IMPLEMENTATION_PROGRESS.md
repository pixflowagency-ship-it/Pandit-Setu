# Sarvmangal / Pandit Setu — Implementation Progress

**Project Status:** Active Architecture & Full-Stack Hardening  
**Target Architecture:** Node.js (ESM) + TypeScript + Express + PostgreSQL (PostGIS) + Drizzle ORM + Redis + Socket.io + Razorpay + Flutter (Dart)  
**Methodology:** Phase-by-Phase Verification (Test -> Fix -> Connect -> Verify -> Document)

---

## Master Implementation Matrix (Phase 0 Audit Baseline)

| Feature | UI (Flutter) | Backend API | Database | External Service | Connected | Production Ready |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Yajman Auth (OTP)** | READY | READY | READY (`users`) | PARTIAL (Mock in dev, SMS logger) | PARTIAL | PARTIAL |
| **Yajman Profile** | READY | READY (`/users/me`, `/users/profile`) | READY (`users`) | None | BROKEN (Calls `/auth/profile`) | NO |
| **Puja Catalog** | READY | READY (`/poojas`) | READY (`poojas`, `samagri_items`) | None | CONNECTED | READY |
| **Offline Puja Booking** | READY | READY (`/bookings`) | READY (`bookings`) | Socket.io (server only) | CONNECTED | READY |
| **Online Puja Booking** | READY | PARTIAL (`agora.service.ts`) | READY (`bookings`) | Agora RTC (No Flutter SDK) | BROKEN (Simulated UI) | NO |
| **Nearby Pandits (PostGIS)**| READY | READY (`/pandits/nearby`) | READY (PostGIS `Point`) | None | BROKEN (Missing lat/lng in Flutter call) | NO |
| **Pandit Registration & KYC**| READY | READY (`/pandits/*`) | READY (`pandits`, `pandit_documents`) | Local disk storage | PARTIAL | NO (Needs S3/cloud storage) |
| **Pandit Duty Availability**| READY | READY (`PATCH /duty-status`) | READY (`pandits.isAvailable`) | Redis GEO | BROKEN (Flutter local state boolean only) | NO |
| **Booking Acceptance/Rejection**| READY | READY (`/bookings/:id/status`) | READY (`bookings.status`) | Socket.io / FCM | BROKEN (Flutter simulated 30s timer) | NO |
| **Booking History** | READY | READY (`/bookings/my-bookings`) | READY (`bookings`) | None | BROKEN (Reads SharedPreferences only) | NO |
| **Payment Integration** | READY (Razorpay Flutter) | READY (`/payments/*`) | READY (`bookings.paymentStatus`) | Razorpay Test Mode | CONNECTED | TEST MODE VERIFIED |
| **Push Notifications** | MOCK (Hardcoded cards) | PARTIAL (`notification.service.ts`)| READY (`users.fcmToken`) | Firebase Admin (No client FCM) | BROKEN | NO |
| **Realtime WebSockets** | MOCK | PARTIAL (`server.ts`, `realtime.ts`)| N/A | Socket.io + Redis adapter | BROKEN (No Flutter Socket.io client) | NO |
| **Pooja Samagri Store (Catalog, Cart, Checkout, Orders)** | READY | READY (`/products`, `/product-orders`) | READY (`products`, `product_orders`, `product_order_items`) | Razorpay Test Mode | CONNECTED | READY |
| **Phool Mala Subscriptions**| READY | READY (`/subscriptions`) | READY (`subscriptions`) | Razorpay Subscriptions | BROKEN (Local alert dialog only) | NO |
| **Nearby Temples** | READY | READY (`/temples/nearby`) | Redis Cache | Google Places API | BROKEN (Displays hardcoded Ujjain cards) | PARTIAL |
| **Astrology Consultation** | READY (UI flows) | MISSING | MISSING | None | BROKEN (Local state & dummy meet link) | NO |
| **Handmade Kundli** | READY (Forms) | MISSING | MISSING | None | BROKEN (In-memory canvas only) | NO |
| **AI Spiritual Chat** | READY | MISSING | MISSING | None | MOCK (Local if/else keyword matching) | NO |
| **Admin Portal** | MISSING | PARTIAL (`/admin/health`) | READY (Roles in DB) | None | MISSING | NO |

---

## Phase Execution Roadmap & Status

### Phase 0: Full Project Audit & Verification (COMPLETED)
- **Status:** DONE
- **Actions:**
  - Ran full Vitest backend test suite: 12 test files passed, 61 tests passed, 1 test file failed (`users.test.ts` due to `/profile` route alias mismatch).
  - Ran TypeScript compiler check (`npx tsc --noEmit`): 0 errors.
  - Ran Flutter static analyzer (`flutter analyze`): 0 issues found.
  - Identified all false success fallbacks and client/server contract mismatches.
  - Produced initial matrix, risk list, and dependency registry.

---

### Phase 1: Foundation (COMPLETED)
- **Status:** DONE (100% Passing)
- **Actions Completed:**
  1. **Route Alignment & Test Suite:** Added `/profile` alias and support for `GET`, `PUT`, and `PATCH` in `src/routes/users.routes.ts` and `src/routes/auth.routes.ts`. Fixed `src/tests/users.test.ts` and `src/tests/auth.test.ts`. 
     - **Result:** Vitest suite reached 100% pass rate: **13/13 test files passed, 66/66 tests passed**.
  2. **Environment & CORS Hardening:**
     - Overhauled `.env.example` with comprehensive documentation and all required environment keys (`PORT`, `DATABASE_URL`, `JWT_SECRET`, `REDIS_URL`, `CORS_ORIGIN`, `RAZORPAY_*`, `AGORA_*`, `GOOGLE_PLACES_*`, `FIREBASE_*`).
     - Hardened CORS configuration in `src/app.ts` to dynamically reflect origin with `credentials: true` when wildcard is configured, preventing browser credential blocking.
  3. **Redis-Backed OTP Architecture:**
     - Updated `src/services/otp.service.ts` to persist OTPs in Redis (`otp:<phone>`) with automatic TTL expiration (`env.otpExpirySeconds`), maintaining graceful in-memory Map fallback if Redis is unreachable.
     - Updated `src/services/auth.service.ts` to asynchronously await OTP generation and verification.
  4. **Flutter Client Environment Configuration:**
     - Created `frontend/pandit_ssetu/lib/config/api_config.dart` with platform-aware base URL resolution (`10.0.2.2:5000` for Android emulator, `localhost:5000` for Desktop/Web, and `--dart-define=API_BASE_URL` for production/physical device).
  5. **Flutter ApiService Refactoring & Mock Removal:**
     - Completely overhauled `frontend/pandit_ssetu/lib/services/api_service.dart`.
     - Pointed profile fetch to `GET /users/profile`.
     - Connected profile updates (`ApiService.updateProfile`) to persist devotee records to the backend database from both `profile_screen.dart` and `user_profile_detail_screen.dart`.
     - Connected `getUserBookings()` to real `GET /api/v1/bookings` with token headers.
     - Formatted `createBooking()` to supply strict Zod-compatible payloads (`poojaId`, `bookingTime` ISO 8601, `mode`, `venueAddress`, `lat`, `lng`, `samagriIncluded`).
     - Removed silent `SharedPreferences` mock booking generation on API failure, replacing it with transparent user-facing error reporting.
     - Provided coordinate parameters to `getNearbyPandits(lat, lng, radiusKm)`.
     - Added `getPoojas()` method to fetch live pujas from the database.
- **Verification:**
  - `npm run test`: **13 passed, 66 passed (100%)**
  - `npx tsc --noEmit`: **0 errors**
  - `flutter analyze`: **0 issues found**

---

### Phase 2: Core Puja Booking & History (IN PROGRESS - MILESTONE 1 VERIFIED)
- **Goals:**
  1. Import real Excel catalog (`Pooja List.xlsx`) into PostgreSQL and synchronize Drizzle schema. (COMPLETED)
  2. Connect Flutter `BookScreen` to live `GET /api/v1/poojas` endpoint, removing hardcoded fallback. (COMPLETED)
  3. Ensure booking flow sends real database UUIDs, prices, and durations to `POST /api/v1/bookings`. (COMPLETED)
  4. Complete end-to-end booking lifecycle (pending -> accepted/declined -> completed) with database persistence.
  5. Hook real nearby Pandits PostGIS query to the selection carousel.
  6. Integrate Razorpay checkout flow on booking creation.
- **Actions Completed:**
  - **Excel Inspection & Data Audit:** Inspected `Pooja List.xlsx` (26 poojas across 6 categories, 156 samagri ritual items across 14 categories; empty `Pandit Ji List`).
  - **Schema & Migration:** Extended `src/db/schema/poojas.ts` (`category`, `duration`, `requiredPandits`), created `src/db/schema/samagri.ts` (`samagri_items` table), and executed migration `0006_poojas_and_samagri_sync.sql`. Kept store catalog `products` separate.
  - **Idempotent Importer:** Created `src/db/import_pooja_excel.ts` with upsert mechanisms by slug and sNo. Successfully imported 26 poojas and 156 samagri items with zero duplicates. Added `npm run import:poojas`.
  - **Flutter BookScreen Integration:** Connected `frontend/pandit_ssetu/lib/screens/book_screen.dart` to `ApiService.getPoojas()`. Added `PoojaDetail.fromJson` with real UUID mapping. Removed ~700 lines of hardcoded static data. Added search filtering and pull-to-retry while preserving exact visual UI and filter tabs.
  - **Booking ID Alignment:** Replaced static slug IDs with real PostgreSQL UUIDs across `BookScreen`, `main.dart`, and `HomeScreen`. Real UUIDs now flow into `ApiService.createBooking()`.
  - **Socket.IO Redis Resilience:** Added graceful connection and error handling in `src/services/realtime.service.ts` to prevent crashes when Redis is absent or local.
  - **Pooja Query Limit 400 Fix:** Resolved client/server contract mismatch where `BookScreen` requested `limit: 100` against backend schema's `MAX_LIMIT = 50`. Updated `BookScreen` to request `limit: 50` and added defensive clamping and URL debug logging in `ApiService.getPoojas()`. All 26 poojas are returned and parsed cleanly.
- **Verification:**
  - `npm run test`: **13 passed, 73 passed (100%)**
  - `npm run typecheck`: **0 errors**
  - `flutter analyze`: **0 issues found**
  - `flutter test`: **19 passed (100%)**
  - `GET /api/v1/poojas`: Verified live HTTP response with 26 database poojas.

---

### Batch P1: Booking & Payment Integrity (COMPLETED)
- **Status:** DONE (100% Verified)
- **Objectives & Completed Work:**
  1. **TASK 1 — Fix Booking Date and Time:**
     - Created `BookingDateTimeHelper` in `frontend/pandit_ssetu/lib/utils/booking_date_time_helper.dart`.
     - Accurately parses user's selected 12-hour AM/PM time slot (`07:00 AM`, `09:30 AM`, `04:00 PM`, `06:30 PM`, `12:00 PM/AM`).
     - Combines user's intended date and time slot in local wall-clock timezone and converts accurately to UTC ISO 8601 string.
     - Removed the silent fallback in `ApiService.createBooking()` that previously scheduled all bookings for tomorrow at 09:30 UTC.
     - Rejects missing or invalid date/time selections with clear `FormatException` errors.
     - Added comprehensive regression tests in `booking_and_payment_integrity_test.dart` for morning, evening, boundary hours, timezone conversion roundtrip, and invalid input rejection.
  2. **TASK 2 — Fix Home Carousel Pooja Identifiers:**
     - Replaced legacy slug strings in `HomeScreen._heroSlides` (`navratri_pooja`, `satyanarayan_katha`, `griha_pravesh_pooja`, `mahamrityunjaya_jaap`) with verified database UUIDs (`67e77a47-8ffb-403a-bc64-c948ab5e2abc`, `92086a65-41a9-4545-9588-6f35c8bb8b6b`, `9ae802b2-95f9-4461-af5a-e7c32d6fb1af`, `9484cd34-05de-4b00-9621-b190d075be33`).
     - Created `CarouselPoojaMapper` (`frontend/pandit_ssetu/lib/utils/carousel_pooja_mapper.dart`) providing stable environment-wide mapping by UUID, legacy slug, or title keyword.
     - Added verified details for `Navratri Pooja` and `Mahamrityunjaya Jaap` to `_trendingRituals`.
     - Disabled booking action safely with user-facing SnackBar when a slide cannot be mapped, completely eliminating the silent fallback to `_trendingRituals[0]`.
     - Added unit tests for direct UUID mapping, legacy slug resolution, and safe unmapped slide handling.
  3. **TASK 3 — Integrate Razorpay Flutter Test Mode:**
     - Added `razorpay_flutter: ^1.3.7` to `pubspec.yaml` (resolved cleanly with `flutter config --no-enable-windows-desktop` and `flutter pub get`).
     - Implemented `createPaymentOrder(bookingId)` and `verifyPaymentSignature(orderId, paymentId, signature)` in `ApiService`.
     - Connected `PoojaBookingFlowScreen` to Razorpay checkout in Test Mode.
     - Added event listeners for `EVENT_PAYMENT_SUCCESS`, `EVENT_PAYMENT_ERROR`, and `EVENT_EXTERNAL_WALLET`.
     - Gated `_showSuccessDialog()` strictly on backend signature verification returning `paymentStatus == 'PAID'` or `status == 'CONFIRMED'`. Client callbacks are never treated as authoritative proof of payment.
     - Cancelled payments, failed payments, and network timeouts display descriptive error SnackBars and leave bookings in `PENDING` state without false confirmation.
     - Added `_isSubmitting` guard preventing duplicate order submissions.
     - Disposed Razorpay listeners cleanly in `dispose()` via `_razorpay.clear()`.
  4. **TASK 4 — Remove Unsafe Payment Secret Fallbacks:**
     - Removed hardcoded `"test_key_secret"`, `"test_key_id"`, and `"test_webhook_secret"` strings from `src/services/payments.service.ts`.
     - Enforced strict runtime checks throwing `AppError(500, "CONFIGURATION_ERROR", ...)` if required credentials are not set.
     - Added `validateProductionConfig()` in `src/config/env.ts` to abort server startup in production if `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, or `RAZORPAY_WEBHOOK_SECRET` is missing.
     - Added `/verify-signature` route alias alongside `/verify` in `payments.routes.ts`.
     - Added idempotency guard in `verifyPaymentSignature` returning existing booking without duplicate updates if already `PAID`.
     - Added unit tests in `src/tests/payments.test.ts` asserting safe 500 failure when credentials are missing, signature verification via `/verify-signature`, idempotency, and production configuration validation.
     - Added `pool: "forks"` to `vitest.config.ts` for clean worker teardown on Windows.
  5. **TASK 5 — Testing & Regression Verification:**
     - `npm run test`: **13 passed, 73 passed (100%)**
     - `npm run typecheck`: **0 errors**
     - `flutter analyze`: **0 issues found**
     - `flutter test`: **19 passed (100%)**

---

### Phase 3: Real Pandit Platform
- **Goals:**
  1. Real phone OTP auth for Pandits.
  2. Connect Pandit duty toggle to `PATCH /api/v1/pandits/duty-status`.
  3. Real booking request notification & accept/reject endpoints.
  4. Pandit document upload pipeline.
- **Status:** PENDING

---

### Phase 4: Online Services & Real-time Communications
- **Goals:**
  1. Agora / Google Meet link lifecycle for video pujas.
  2. Add Socket.io client to Flutter for real-time booking alerts.
  3. Firebase Cloud Messaging (FCM) device token registration.
- **Status:** PENDING

---

### Phase 5: Additional Business Services (IN PROGRESS - STORE CATALOG COMPLETED)
- **Goals:**
  1. Connect `ShopScreen` to `GET /api/v1/products` and remove `products.json`. (COMPLETED)
  2. Connect `PhoolMalaScreen` to `POST /api/v1/subscriptions`.
  3. Build consultation & Kundli database schemas and API routes.
  4. Connect Temple Discovery screen to `GET /api/v1/temples/nearby`.
- **Actions Completed (Store Catalog & Products API):**
  - **Excel Analysis & Row Count Audit:** Analyzed `Pooja_Store_App_Product_Master_500Plus.xlsx`. Explained row count difference between `Product_Master` (802 rows, 50 categories) and `App_Import` (1267 rows, 62 categories). `App_Import` expands catalog with 465 products (`PUJ-0803` to `PUJ-1267`) across additional categories. Verified 0 duplicate IDs and 0 missing/blank IDs.
  - **Schema & Migration:** Extended `src/db/schema/products.ts` with `productId` (varchar 50 unique), `subCategory`, `specificationType`, `unit`, `status`, `searchTags`, `updatedAt`. Created and executed migration `drizzle/0007_products_catalog_sync.sql`. Kept completed `poojas` and `samagri_items` tables untouched.
  - **Idempotent Importer:** Created `src/db/import_store_products_excel.ts` with batch upsert on conflict (`product_id`). Cleaned up 156 legacy unkeyed dummy rows. Successfully imported all 1267 real store products from `App_Import` with realistic tiered catalog pricing. Added `npm run import:products`.
  - **API Implementation:**
    - `GET /api/v1/products`: Added filtering by `category`, `subCategory`, `search` (multi-field ILIKE over name, description, tags, product ID), and strict pagination validation.
    - `GET /api/v1/products/:id`: Added lookup by UUID or `Product_ID` (e.g. `PUJ-0001`) with 404 error handling.
  - **Flutter ShopScreen Integration:** Connected `frontend/pandit_ssetu/lib/screens/shop_screen.dart` to `ApiService.getProducts()`. Removed bundled `assets/data/products.json`. Added loading state, empty state ("No Items Found"), and error state with retry button. Retained exact visual UI design, category chips, sort dropdown, search bar, and Add to Cart functionality.
- **Verification:**
  - `npm run test`: **13 passed, 66 passed (100%)**
  - `npm run typecheck`: **0 errors**
  - `flutter analyze`: **0 issues found**
  - Live endpoints verified: `GET /api/v1/products`, category filter, search, `GET /api/v1/products/PUJ-0001`, and 404 handler.
- **Status:** PARTIAL (Store Catalog 100% Verified)

---

### Phase P2-A: Role-Based Authentication, Pandit Onboarding, Document Verification, Video Verification & Protected Dashboard [COMPLETED]
- **Status:** COMPLETED & 100% VERIFIED
- **Core Problem & Root Cause of Dashboard Bypass:**
  - *Frontend:* `pandit_login_screen.dart` unconditionally called `context.go('/pandit-dashboard')` upon OTP verification, irrespective of whether the Pandit was approved, pending, or under review.
  - *Backend:* `/api/v1/pandits/dashboard`, `/duty-status`, and `/accept-booking` only checked JWT role `PANDIT` without checking `verificationStatus === 'APPROVED'` and `isVerified === true`.
- **Database Schema Changes & Migration 0008:**
  - File: `drizzle/0008_pandit_onboarding.sql` and `src/db/migrations/0008_pandit_onboarding.ts`.
  - Added columns to `pandits`:
    - `verification_stage` (`varchar(50) DEFAULT 'STAGE_1_PHONE_VERIFIED' NOT NULL`)
    - `rejection_reason` (`text`)
    - `video_call_status` (`varchar(50) DEFAULT 'NOT_SCHEDULED' NOT NULL`)
    - `video_scheduled_at` (`timestamp with time zone`)
    - `video_call_room_id` (`varchar(100)`)
    - `video_verifier_id` (`uuid`)
    - `video_verifier_notes` (`text`)
    - `approved_at` (`timestamp with time zone`)
    - `approved_by` (`uuid`)
  - Added columns to `pandit_documents`:
    - `doc_number` (`varchar(100)`)
    - `file_name` (`varchar(255)`)
    - `file_size` (`integer`)
    - `mime_type` (`varchar(100)`)
    - `rejection_reason` (`text`)
- **Backend APIs Implemented & Secured:**
  - `POST /api/v1/pandits/apply`: Allows an existing Yajman phone identity to apply for the Pandit role without duplicate accounts.
  - `GET /api/v1/pandits/onboarding/status`: Returns authoritative stage, document list, video verification details, and `canAccessDashboard` boolean.
  - `PUT /api/v1/pandits/onboarding/profile`: Updates Pandit professional details (`fullName`, `bio`, `experienceYears`, `languages`, `specializations`, `city`, `state`, `pincode`, `address`).
  - `POST /api/v1/pandits/onboarding/documents`: Secure document upload with magic-byte file signature validation (`%PDF`, `\x89PNG`, `\xFF\xD8\xFF`), size caps (10MB), and private filesystem isolation under `storage/documents/<panditId>/`.
  - `GET /api/v1/pandits/documents/:id/file`: Authenticated streaming route enforcing ownership or `ADMIN` role.
  - `DELETE /api/v1/pandits/onboarding/documents/:id`: Allows replacement/deletion of pending documents.
  - `POST /api/v1/pandits/onboarding/documents/submit`: Submits all required documents (`AADHAAR`, `PAN`, `VEDIC_CERTIFICATE`) for review, advancing stage to `STAGE_3_DOCS_SUBMITTED`.
  - `POST /api/v1/pandits/onboarding/video-verification/schedule`: Schedules video appointment, generates room UUID, and provides joining instructions.
  - `POST /api/v1/pandits/admin/documents/:id/verify`: Admin reviewer endpoint to approve/reject specific documents.
  - `POST /api/v1/pandits/admin/video-verification/verify`: Admin reviewer endpoint to record video call outcome.
  - `POST /api/v1/pandits/admin/approve`: Admin reviewer endpoint to grant final approval.
- **Role-Based Authentication & Multi-Role Logic:**
  - One mobile number can access both YAJMAN and PANDIT portals without creating duplicate records in `users`.
  - A Yajman attempting Pandit login receives `requiresApplication: true` and is prompted to apply.
  - A Pandit can log in to the Yajman portal using the same mobile number.
  - Backend middleware `requireApprovedPandit` strictly blocks unapproved Pandits with HTTP 403 `PANDIT_NOT_APPROVED` and directs them to complete onboarding.
- **Flutter UI & Navigation:**
  - `pandit_login_screen.dart`: Queries authoritative backend status and redirects unapproved Pandits to `/pandit-onboarding`.
  - `pandit_onboarding_screen.dart`: Full 5-step mobile-first onboarding UI with progress indicator (Profile Details -> Document Uploads -> Video Call Scheduling & Instructions -> Status & Approval Gate).
  - `pandit_dashboard_screen.dart`: Route guard `_verifyAccess()` in `initState` verifies backend approval before rendering metrics.
- **Section 13: Global Branding Consistency ("SARV MANGAL"):**
  - Centralized official application display name in `frontend/pandit_ssetu/lib/constants/branding.dart`: `AppBranding.appDisplayName = 'SARV MANGAL'`.
  - Updated all user-facing screens (Splash, Role Select, Yajman Login/Register/OTP, Pandit Login/Onboarding/Dashboard, Panchang, Live Tracking, Profile).
  - Updated platform display names: Android `android:label="SARV MANGAL"`, iOS `CFBundleDisplayName = "SARV MANGAL"`, Web `<title>SARV MANGAL</title>`.
  - Preserved internal code identifiers (`pandit_ssetu` package, DB tables, API routes).
- **Automated Verification:**
  - Backend Vitest (`npm run test`): **14/14 test files passed, 93/93 unit tests passed (100%)**.
  - TypeScript Compilation (`npm run typecheck`): **0 errors**.
  - Flutter Analysis (`flutter analyze`): **No issues found (0 errors, 0 warnings)**.
  - Flutter Tests (`flutter test`): **24/24 tests passed across 5 test suites (100%)**.

---

### Phase P2-B: Pandit Duty Status, Dispatch Engine & Real-Time Booking Execution

#### Task 1: Pandit Duty Status API Integration + Live Location Toggle [COMPLETE]
- **Objective:** Replace simulated in-memory online/offline duty switch in Flutter `PanditDashboardScreen` with backend `PATCH /api/v1/pandits/duty-status`. Ensure UI reflects authoritative server state and supports optional device coordinates without fabricating location.
- **Root Cause of Previous Implementation:**
  - `_PanditDashboardScreenState._isOnline` was initialized locally to `true`.
  - `_toggleOnlineState()` performed only an in-memory `setState(() => _isOnline = !_isOnline)` without network requests.
  - A mock incoming request was scheduled via `Future.delayed(Duration(seconds: 3))` to simulate dispatch.
- **Files Modified / Added:**
  - `src/validators/pandits.validator.ts`: Updated `dutyStatusSchema` to validate `isAvailable: z.boolean()`, optional `lat` (-90 to 90), optional `lng` (-180 to 180), and refined to enforce both coordinates together or neither.
  - `src/controllers/pandits.controller.ts`: Extracted `lat` and `lng` and passed to `updateDutyStatus`.
  - `src/services/pandits.service.ts`: Updated `updateDutyStatus` to persist coordinates to PostgreSQL (`latitude`, `longitude`, PostGIS `location`), update `isAvailable`, and synchronize with Redis GEO key `pandits:live` (`geoadd` or `zrem`). Updated `getPanditDashboard` to return authoritative `isAvailable: pandit.isAvailable ?? false`.
  - `src/tests/pandits.test.ts`: Added 6 new unit tests for coordinate validation, partial coordinate rejection, valid coordinate Redis GEO updates, unapproved pandit guards, and missing profile 404.
  - `frontend/pandit_ssetu/pubspec.yaml`: Added `geolocator: ^14.1.1`.
  - `frontend/pandit_ssetu/android/app/src/main/AndroidManifest.xml`: Added `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION` permissions.
  - `frontend/pandit_ssetu/ios/Runner/Info.plist`: Added `NSLocationWhenInUseUsageDescription`.
  - `frontend/pandit_ssetu/lib/services/api_service.dart`: Added `ApiService.updateDutyStatus(bool isAvailable, {double? lat, double? lng})`.
  - `frontend/pandit_ssetu/lib/screens/pandit_dashboard_screen.dart`: Connected initial duty status to `ApiService.getPanditDashboard()`, integrated `Geolocator` with permission checks and graceful denial handling (never fabricates coordinates), guarded against duplicate taps with `_isTogglingDuty` loading spinner, and rolls back UI on errors.
  - `frontend/pandit_ssetu/test/pandit_duty_status_test.dart`: Added 6 unit tests verifying payload formatting, authoritative state binding, error rollbacks, loading guards, and zero-fabrication permission denial.
  - `KNOWN_ISSUES.md` & `BUGS.md`: Updated Section 2.2 and BUG-007 to record Task 1 completion.
- **Verification Commands & Actual Results:**
  - `npm run typecheck` in backend: **Exit Code 0** (0 TypeScript errors).
  - `npm run test` in backend: **Exit Code 0** (14/14 test files passed, 99/99 tests passed, 100% pass rate).
  - `flutter analyze` in frontend: **Exit Code 0** (No issues found).
  - `flutter test` in frontend: **Exit Code 0** (30/30 tests passed across 6 test suites, 100% pass rate).
- **Remaining Limitations & Hardware Testing:**
  - Real device physical GPS lock verification requires physical device testing.
- **Tasks 2–6 Status (Prior to Task 2):**
  - Task 2 (Pooja Request Dispatch Engine): PENDING

#### Task 2: Real Pooja Request Dispatch Engine [COMPLETE]
- **Objective:** Replace simulated incoming booking requests with a genuine backend-driven dispatch mechanism that identifies eligible Pandits and emits real targeted Socket.IO notifications (`booking:new-request`).
- **Files Modified / Added:**
  - `src/services/realtime.service.ts`: Updated Socket.IO connection handler to automatically join authenticated users to private rooms `user:${userId}` and `pandit:user:${userId}`.
  - `src/services/dispatch.service.ts`: Implemented comprehensive `dispatchBooking(bookingId, options)` service with candidate discovery (Redis GEO + PostGIS fallback), authoritative PostgreSQL verification/availability checks, concurrency lock (`dispatch:lock:${bookingId}`), notification deduplication (`dispatch:notified:${bookingId}:${panditId}`), haversine distance computation, and private room emission.
  - `src/controllers/bookings.controller.ts`: Triggered non-blocking background dispatch upon booking persistence in `createBookingHandler`; added `dispatchBookingHandler` for manual/retry execution.
  - `src/routes/bookings.routes.ts`: Added `POST /api/v1/bookings/:id/dispatch` endpoint secured by `requireAuth` and role checking.
  - `src/tests/dispatch.test.ts`: Created 15 comprehensive unit tests covering candidate discovery, unapproved/offline/stale/distant/busy pandit exclusion, cancelled/assigned booking exclusion, concurrency locks, deduplication, PostGIS fallback, and Yajman privacy protection.
  - `frontend/pandit_ssetu/pubspec.yaml`: Added `socket_io_client: ^3.1.6`.
  - `frontend/pandit_ssetu/lib/config/api_config.dart`: Added `socketUrl` getter dynamically resolving backend WebSocket URL.
  - `frontend/pandit_ssetu/lib/screens/pandit_dashboard_screen.dart`: Connected to live Socket.IO server when Pandit is online; subscribed to `booking:new-request` with dynamic payload binding (`poojaName`, `totalAmount`, `approximateDistanceKm`, `venueAddress`, countdown); removed simulated mock timers and test buttons.
  - `frontend/pandit_ssetu/test/dispatch_test.dart`: Added 6 unit tests verifying brand identity ("SARV MANGAL"), payload parsing, malformed event rejection, deduplication, disconnect safety, and address anonymization.
- **Dispatch Architecture & Eligibility Rules:**
  1. *Candidate Discovery:* Queries Redis GEO (`GEORADIUS` on `pandits:live` within `serviceRadiusKm`, default 25km). Automatically falls back to PostGIS `ST_DWithin` spatial query on `pandits.location` if Redis is empty or offline.
  2. *Authoritative PostgreSQL Eligibility:*
     - Pandit verification: `pandit.isVerified === true` and `pandit.verificationStatus === 'APPROVED'`.
     - Availability: `pandit.isAvailable === true`.
     - Valid, non-stale coordinates: device location updated within 24 hours.
     - Distance validation: Haversine distance <= `serviceRadiusKm`.
     - Identity safety: Excludes booking's Yajman (cannot dispatch to booking creator).
     - Schedule conflict check: Excludes pandits with overlapping confirmed bookings or active `IN_PROGRESS` assignments.
  3. *Concurrency & Deduplication:* Redis lock `dispatch:lock:${bookingId}` (30s TTL) blocks concurrent duplicate dispatch processes. Redis key `dispatch:notified:${bookingId}:${panditId}` (300s TTL) prevents repeated notifications to the same Pandit across retry attempts.
  4. *Targeted Socket.IO Payload:* Sanitized `booking:new-request` payload emitted only to `pandit:user:${userId}` and `user:${userId}`. Exposes only operational details (`bookingId`, `poojaId`, `poojaName`, `bookingTime`, `mode`, `totalAmount`, `samagriIncluded`, `approximateDistanceKm`, `city`, anonymized `area`, `expiresAt`). Never exposes Yajman's phone number, flat/unit numbers, payment secrets, or internal auth tokens.
- **Verification Commands & Actual Results:**
  - `npm run typecheck` in backend: **Exit Code 0** (0 TypeScript errors).
  - `npm run test` in backend: **Exit Code 0** (15/15 test files passed, 114/114 tests passed, 100% pass rate).
  - `flutter analyze` in frontend: **Exit Code 0** (No issues found).
  - `flutter test` in frontend: **Exit Code 0** (36/36 tests passed across 7 test suites, 100% pass rate).
- **Tasks 3–6 Status (Prior to Task 3):**
  - Task 3 (Real-Time Pooja Request Modal): PENDING

#### Task 3: Real-Time Pooja Request Modal for Pandits [COMPLETE]
- **Objective:** Implement a production-grade incoming Pooja Request modal for Pandits in the existing Pandit dashboard that opens exclusively upon receipt of genuine Socket.IO `booking:new-request` events, displays sanitized booking details with an authoritative 60-second countdown, handles accept/decline actions via real backend integration, and protects Yajman privacy.
- **Files Modified / Added:**
  - `frontend/pandit_ssetu/lib/widgets/incoming_pooja_request_modal.dart`: Created dedicated modal widget featuring official SARV MANGAL branding, animated circular countdown ring, Dakshina earnings display, Samagri kit badge, formatted date/time, sanitized locality (stripping flat/unit numbers), expired state banner, loading state on submit, and double-tap prevention.
  - `frontend/pandit_ssetu/lib/utils/booking_date_time_helper.dart`: Added `formatForDisplay(isoUtcString)` to cleanly convert ISO UTC booking timestamps into localized display strings (e.g., "15 Oct 2026, 09:30 AM").
  - `frontend/pandit_ssetu/lib/services/api_service.dart`: Added `acceptBooking(bookingId)` communicating with backend `POST /api/v1/pandits/accept-booking`, handling 200 OK, 409 Conflict (`BOOKING_ALREADY_TAKEN`), and 403 Forbidden (`PANDIT_NOT_APPROVED`).
  - `frontend/pandit_ssetu/lib/screens/pandit_dashboard_screen.dart`: Integrated `IncomingPoojaRequestModal` in the dashboard Stack. Managed incoming request lifecycle with `_dismissedBookingIds` set to eliminate duplicate presentations across retries. Connected genuine `_handleAcceptBooking` with user feedback and navigation, connected `_handleDeclineBooking`, safely handled request expiry, and ensured clean socket and timer cleanup on duty toggle and widget disposal.
  - `frontend/pandit_ssetu/test/pooja_request_modal_test.dart`: Added 10 comprehensive widget and unit tests covering modal opening on valid event, field rendering, malformed payload safety, expired request lockouts, countdown expiry progression, deduplication, double-tap submission guards, API error feedback, timer/listener cancellation on disposal, and privacy guarantees.
- **Verification Commands & Actual Results:**
  - `npm run typecheck` in backend: **Exit Code 0** (0 TypeScript errors).
  - `npm run test` in backend: **Exit Code 0** (15/15 test files passed, 114/114 tests passed, 100% pass rate).
  - `flutter analyze` in frontend: **Exit Code 0** (No issues found, 0 errors, 0 warnings).
  - `flutter test` in frontend: **Exit Code 0** (46/46 tests passed across 8 test suites, 100% pass rate).
#### Task 4: Atomic Pooja Acceptance, Persistent Decline & Concurrency Safety [COMPLETE]
- **Objective:** Implement reliable, concurrency-safe booking acceptance and persistent Pandit decline handling. Ensure that one booking cannot be assigned to multiple Pandits, duplicate requests do not corrupt state, persistent declines are recorded and respected during dispatch retries without globally declining the booking, and the Flutter frontend receives truthful, non-falsified results.
- **Root Cause & Previous Implementation Gaps:**
  1. *Acceptance Logic:* `acceptBooking` blindly executed an `UPDATE` on `bookings` where `status = 'PENDING'` without verifying booking existence, returning HTTP 409 `BOOKING_ALREADY_TAKEN` instead of 404 `NOT_FOUND` if the booking ID did not exist. It lacked idempotency if the winning Pandit submitted repeated accept requests.
  2. *Decline Logic:* Completely absent on the backend. No database table or endpoint existed. The Flutter client (`PanditDashboardScreen._handleDeclineBooking`) only dismissed the modal locally and recorded the ID in an in-memory Dart `Set`, giving false appearance of backend handling.
  3. *Dispatch Leak:* Because declines were not recorded in the database, retry dispatch engines could not recognize that a candidate had declined and would re-alert the same Pandit.
- **Files Modified / Added:**
  - `src/db/schema/booking_declines.ts`: Created `booking_declines` table schema with UUID primary key, foreign keys to `bookings.id` and `users.id`, `reason` enum (`TOO_FAR`, `BUSY`, `SCHEDULE_CONFLICT`, `OTHER`), optional `notes`, timestamps, and unique composite index on `(booking_id, pandit_id)`.
  - `src/db/schema/index.ts` & `src/db/schema/relations.ts`: Exported `bookingDeclines` and established relational mappings with `bookings` and `users`.
  - `drizzle/0009_booking_declines.sql`: Drizzle SQL migration creating table, unique constraint on `(booking_id, pandit_id)`, and performance indexes.
  - `src/db/migrations/0009_booking_declines.ts`: Migration runner script executed against Neon PostgreSQL.
  - `src/validators/pandits.validator.ts`: Added `declineBookingSchema` validating UUID `bookingId`, optional reason enum, and optional notes max 500 chars.
  - `src/services/pandits.service.ts`: Hardened `acceptBooking` with existence verification (404), approval checks (403), idempotency check for existing assignment, status eligibility guards (400 for cancelled, 409 for confirmed), and atomic conditional update (`WHERE id = bookingId AND status = 'PENDING' AND pandit_id IS NULL RETURNING *`). Added `declineBooking` with existence checks, eligibility guards, idempotent insert (`onConflictDoNothing`), and Redis cache synchronization.
  - `src/controllers/pandits.controller.ts`: Added `declineBookingHandler`.
  - `src/routes/pandits.routes.ts`: Mounted `POST /api/v1/pandits/decline-booking` guarded by `strictLimiter`, `verifyToken`, `requireApprovedPandit`, and `validateBody(declineBookingSchema)`.
  - `src/services/dispatch.service.ts`: Integrated authoritative persistent decline filtering (`bookingDeclines` query) into candidate discovery, excluding Pandits who previously declined the active booking from receiving retry notifications, while ensuring other candidates still receive the request.
  - `src/tests/pandits.test.ts`: Added 13 new unit and concurrency tests covering acceptance existence, idempotency, race conditions (0 rows updated), unapproved pandits, cancelled bookings, valid decline persistence, idempotent duplicates, reason validation, cancelled/ineligible decline guards, and authorization.
  - `src/tests/dispatch.test.ts`: Added tests verifying that declined Pandits are excluded from notifications while other eligible candidates receive them.
  - `frontend/pandit_ssetu/lib/services/api_service.dart`: Added `ApiService.declineBooking(bookingId, {reason, notes})` communicating with backend `POST /api/v1/pandits/decline-booking`, returning structured error messages (404, 409, 403) and re-throwing network exceptions without false success toasts.
  - `frontend/pandit_ssetu/lib/widgets/incoming_pooja_request_modal.dart`: Added clean, branded decline reason selection dialog (`_buildDeclineReasonDialog`) supporting reasons `TOO_FAR`, `BUSY`, `SCHEDULE_CONFLICT`, and `OTHER`. Added `_isSubmitting` guard disabling both Accept and Decline buttons with loading indicators during execution to prevent duplicate taps. Added safe error boundary.
  - `frontend/pandit_ssetu/lib/screens/pandit_dashboard_screen.dart`: Connected `_handleDeclineBooking` to genuine `ApiService.declineBooking`. Surfaced authentic SnackBars for success, conflict, and network errors. If network fails, modal is retained to allow retry; if request was already taken or expired, modal is dismissed.
  - `frontend/pandit_ssetu/test/pooja_request_modal_test.dart`: Added 5 new widget tests for accept callback execution, decline reason dialog selection and submission, cancellation safety, network failure feedback preservation, and duplicate tap prevention.
- **Concurrency & Database Guarantees:**
  - *PostgreSQL Row Locking:* The atomic update `UPDATE bookings SET pandit_id = $1, status = 'CONFIRMED' WHERE id = $2 AND status = 'PENDING' AND pandit_id IS NULL RETURNING *` uses PostgreSQL's row-level lock. Concurrent transactions serialize on the target row under Read Committed isolation. The winning transaction updates the row and commits. The losing transaction re-evaluates the WHERE clause on the newly committed row; because `status` is now `'CONFIRMED'` and `pandit_id` is non-null, the WHERE clause evaluates to false, 0 rows are updated, and the backend raises HTTP 409 `BOOKING_ALREADY_TAKEN`.
  - *Idempotent Declines:* The database unique index on `(booking_id, pandit_id)` in `booking_declines` guarantees that multiple decline calls by the same Pandit cannot corrupt state or create duplicate rows.
  - *Global Booking Status Safety:* Pandit declines only write to `booking_declines`; the booking's global status remains `PENDING` so other candidates can accept it.
- **Verification Commands & Actual Results:**
  - `npm run typecheck` in backend: **Exit Code 0** (0 TypeScript errors).
  - `npm run test` in backend: **Exit Code 0** (15/15 test files passed, 129/129 tests passed, 100% pass rate).
  - `flutter analyze` in frontend: **Exit Code 0** (No issues found, 0 errors, 0 warnings).
  - `flutter test` in frontend: **Exit Code 0** (51/51 tests passed across 8 test suites, 100% pass rate).
#### Task 5: Booking Lifecycle & Real-Time Status Synchronization [COMPLETE]
- **Objective:** Implement a secure, database-backed booking state machine for SARV MANGAL enforcing the valid lifecycle (`CONFIRMED -> HEADING_TO_VENUE -> ARRIVED -> PUJA_STARTED -> COMPLETED`). Connect Pandit actions, backend state transitions, PostgreSQL persistence, Socket.IO events, and Yajman-facing booking status updates.
- **Root Cause & Previous Implementation Gaps:**
  1. *Database Schema Gaps:* The `booking_status` enum in PostgreSQL lacked intermediate transition states (`HEADING_TO_VENUE`, `ARRIVED`, `PUJA_STARTED`), jumping directly from `CONFIRMED` to `IN_PROGRESS` and `COMPLETED`.
  2. *Missing Authorization & Transition Rules:* Status update endpoint `PATCH /api/v1/bookings/:id/status` lacked checks to ensure that only the assigned, approved Pandit can advance lifecycle stages. It permitted arbitrary, out-of-order jumps, lacked idempotency, and did not enforce conditional updates against race conditions.
  3. *Client-Side Mock Simulations & Fake Timers:* Flutter `PanditDashboardScreen` used local-only `setState()` mutations and fake timers (`_poojaTimerMinutes = 45`, `Timer.periodic`) to simulate pooja completion without contacting the server. Yajman `LivePoojaTrackingScreen` read from mock SharedPreferences and did not listen to real Socket.IO events.
- **Files Modified / Added:**
  - `src/db/schema/enums.ts`: Added `"HEADING_TO_VENUE"`, `"ARRIVED"`, `"PUJA_STARTED"` to `bookingStatusEnum`.
  - `drizzle/0010_booking_lifecycle_statuses.sql`: Drizzle migration safely adding new enum values using PostgreSQL `ALTER TYPE ... ADD VALUE IF NOT EXISTS`.
  - `src/db/migrations/0010_booking_lifecycle_statuses.ts`: Migration runner executed against Neon PostgreSQL (Exit Code 0).
  - `src/validators/bookings.validator.ts`: Updated `updateBookingStatusSchema` to validate `newStatus` against all lifecycle statuses and accept optional `expectedStatus` string for optimistic concurrency control.
  - `src/services/bookings.service.ts`: Hardened `updateBookingStatus` with:
    - 404 check if booking does not exist.
    - 400 check if booking is not assigned to a Pandit.
    - 403 `FORBIDDEN` if caller is not the assigned Pandit.
    - 403 `PANDIT_NOT_APPROVED` if assigned Pandit is not verified or approved (`isVerified === true` and `verificationStatus === 'APPROVED'`).
    - 200 Idempotency: Returns current booking immediately if already in `newStatus` without side effects.
    - 400 rejection for terminal/invalid states (`CANCELLED`, `COMPLETED`).
    - 409 `STATUS_CONFLICT` if `expectedStatus` is supplied and does not match `booking.status`.
    - 400 `INVALID_STATUS_TRANSITION` if transition violates permitted state graph (`CONFIRMED -> HEADING_TO_VENUE -> ARRIVED -> PUJA_STARTED -> COMPLETED`).
    - Concurrency-safe atomic conditional database update: `UPDATE bookings SET status = $1, updated_at = NOW() WHERE id = $2 AND status = $3 AND pandit_id = $4 RETURNING *`. Throws 409 `STATUS_CONFLICT` if 0 rows returned due to concurrent update race.
  - `src/controllers/bookings.controller.ts`:
    - Emits sanitized Socket.IO event `booking:status-change` (`{ bookingId, status, timestamp }`) to authorized rooms (`booking:${id}`, `user:${yajmanId}`, `user:${panditId}`) strictly after PostgreSQL transaction commits.
    - Sends targeted FCM push notifications on key transitions (`HEADING_TO_VENUE`, `ARRIVED`, `PUJA_STARTED`, `COMPLETED`).
    - Updated `generateVideoTokenHandler` to allow calls during all active states (`CONFIRMED`, `HEADING_TO_VENUE`, `ARRIVED`, `PUJA_STARTED`, `IN_PROGRESS`).
  - `src/services/realtime.service.ts`: Added `booking:subscribe` event handler with authorization checks ensuring only the assigned Pandit or Yajman can join the booking's private real-time room.
  - `src/services/dispatch.service.ts`: Excluded Pandits currently engaged in any active lifecycle status (`IN_PROGRESS`, `HEADING_TO_VENUE`, `ARRIVED`, `PUJA_STARTED`) from candidate dispatch discovery.
  - `src/services/pandits.service.ts`: Added lifecycle statuses to `acceptBooking` active booking check.
  - `src/tests/bookings.test.ts`: Added 11 comprehensive unit, authorization, concurrency, and validation tests (all 140/140 tests pass across 15 test files).
  - `frontend/pandit_ssetu/lib/services/api_service.dart`: Added `updateBookingStatus(bookingId, expectedStatus, newStatus)` and `getBookingById(bookingId)` with robust error extraction.
  - `frontend/pandit_ssetu/lib/screens/pandit_dashboard_screen.dart`:
    - Connected `_startJourney()`, `_markArrived()`, `_startSankalpa()`, `_completePooja()`, and `_finishDutyAndReset()` to real API calls.
    - Added `_isUpdatingStatus` double-tap prevention with loading spinners.
    - Added authentic error handling that preserves current state on failure.
    - Added authoritative state recovery on launch/reconnect via `_fetchActiveDuty()`.
    - Added Socket.IO `booking:status-change` event listener for instantaneous UI updates.
    - Removed fake timers (`_poojaTimerMinutes`, `_poojaTimer`) and local-only mutations.
  - `frontend/pandit_ssetu/lib/screens/live_pooja_tracking_screen.dart`:
    - Added `bookingId` parameter support.
    - Replaced mock SharedPreferences with authoritative `ApiService.getBookingById()` and `getUserBookings()`.
    - Subscribed to Socket.IO `booking:subscribe` and dynamically updated 4-stage tracking stepper on `booking:status-change`.
  - `frontend/pandit_ssetu/lib/screens/bookings_screen.dart`: Added "Track Live" button for active/confirmed bookings linking directly to `/tracking?bookingId=:id`.
  - `frontend/pandit_ssetu/lib/main.dart`: Passed query parameter `bookingId` from GoRoute state to `LivePoojaTrackingScreen`.
  - `frontend/pandit_ssetu/test/booking_lifecycle_state_machine_test.dart`: Added 6 unit and widget tests covering state machine transitions, invalid jump rejection, idempotency, double-tap guard, network failure recovery, and Socket.IO real-time parsing (57/57 tests pass across 9 test suites).
- **Concurrency & Database Guarantees:**
  - *PostgreSQL Row Locking:* The atomic update `UPDATE bookings SET status = $1, updated_at = NOW() WHERE id = $2 AND status = $3 AND pandit_id = $4 RETURNING *` uses row-level locking under Read Committed isolation. The winning update modifies the row and commits. Concurrent competing requests evaluating the same target row re-evaluate the WHERE clause; because `status` has already transitioned away from `expectedStatus`, 0 rows match, and the backend safely raises HTTP 409 `STATUS_CONFLICT` without dirty writes.
  - *Idempotent Re-execution:* An immediate retry of the same transition by the same Pandit returns HTTP 200 with the already-updated booking object, preventing duplicate side-effects.
- **GPS Tracking Audit Findings:**
  - Status synchronization is strictly separated from GPS tracking.
  - Backend Redis GEO write-through and PostGIS coordinate sync exist in `tracking.service.ts`.
  - Devotee tracking UI currently uses a stylized canvas painter (`MapTrackingPainter` on `GridPaper`), not an active Google Maps or Mapbox map widget displaying genuine device coordinates.
  - Mobile hardware background GPS telemetry pipeline streaming genuine device location from physical devices requires mobile platform integration. Real coordinates, movement, distance, and ETAs are not fabricated.
- **Verification Commands & Actual Results:**
  - `npm run typecheck` in backend: **Exit Code 0** (0 TypeScript errors).
  - `npm run test` in backend: **Exit Code 0** (15/15 test files passed, 140/140 tests passed, 100% pass rate).
  - `flutter analyze` in frontend: **Exit Code 0** (No issues found, 0 errors, 0 warnings).
  - `flutter test` in frontend: **Exit Code 0** (57/57 tests passed across 9 test suites, 100% pass rate).
- **Tasks 5–6 Status:**
  - Task 5 (Booking Lifecycle State Machine): COMPLETE
  - Task 6 (Dakshina Collection & Booking Closure): COMPLETE (100%)

---

### Phase P2-B Task 6: Dakshina Collection & Booking Closure (COMPLETED)
- **Status:** DONE (100% Verified)
- **Objective:** Implement complete production-minded Dakshina collection (Cash & Razorpay Online) and server-enforced booking closure workflow for SARV MANGAL.
- **Database Schema & Migration:**
  - Added `dakshina_collections` table (`src/db/schema/dakshina_collections.ts`, migration `drizzle/0011_dakshina_collections.sql` executed against Neon PostgreSQL).
  - Explicitly separates initial booking payment from final Dakshina collections while preserving existing payment semantics.
  - Fields: `id`, `booking_id`, `pandit_id`, `amount`, `currency`, `payment_method` (`CASH` | `ONLINE`), `payment_status` (`PENDING` | `PAID` | `FAILED`), `razorpay_order_id`, `razorpay_payment_id`, `razorpay_signature`, `collected_at`, `notes`, `created_at`, `updated_at`.
- **Backend API Endpoints & Services:**
  - `POST /api/v1/bookings/:id/dakshina/cash`:
    - Validates positive bounded amount (`0 < amount <= 500,000 INR`), verifies caller is the assigned, approved Pandit (`isVerified === true` and `verificationStatus === 'APPROVED'`), and verifies active lifecycle state (`PUJA_STARTED` or `IN_PROGRESS`).
    - Idempotent: returns existing confirmed collection if already paid.
    - Records collector identity and timestamp, updates booking status to `COMPLETED` when requested, and emits sanitized `dakshina:collected` and `booking:status-change` Socket.IO events.
  - `POST /api/v1/bookings/:id/dakshina/create-order`:
    - Creates Razorpay order using server-controlled amount; returns existing pending order idempotently without duplicate charges.
  - `POST /api/v1/bookings/:id/dakshina/verify`:
    - Verifies cryptographic HMAC-SHA256 signature using `crypto.timingSafeEqual` and `RAZORPAY_KEY_SECRET`.
    - Updates payment status to `PAID`, records payment IDs and timestamps, marks booking `COMPLETED`, and emits post-commit real-time events.
  - `GET /api/v1/bookings/:id/dakshina`:
    - Returns audit trail of Dakshina records for authorized participants.
  - Hardened `updateBookingStatus` in `src/services/bookings.service.ts`:
    - Gated `newStatus === 'COMPLETED'` strictly on checking PostgreSQL for a confirmed, paid Dakshina record (`paymentStatus === 'PAID'`), rejecting unconfirmed completion attempts with HTTP 400 `DAKSHINA_NOT_COLLECTED`.
- **Flutter Client Integration:**
  - `frontend/pandit_ssetu/lib/services/api_service.dart`: Added `collectCashDakshina`, `createDakshinaOrder`, `verifyDakshinaPayment`, and `getDakshinaStatus`.
  - `frontend/pandit_ssetu/lib/screens/pandit_dashboard_screen.dart`:
    - Dedicated **Dakshina Collection & Booking Closure Panel** replaces simple completion buttons during `pooja_in_progress`.
    - Supports Cash vs Online toggle, dynamic amount formatting, double-tap lockout (`_isCollectingDakshina`), and loading indicators.
    - Integrated `razorpay_flutter` with robust event lifecycle handling (`_dakshinaRazorpay.clear()` in `dispose`).
    - Authoritative state restoration on app launch/reconnect via `_fetchActiveDuty()`.
    - Listens to Socket.IO `dakshina:collected` event to instantly synchronize UI.
- **Verification Commands & Actual Results:**
  - `npm run typecheck` in backend: **Exit Code 0** (0 TypeScript errors).
  - `npm run test` in backend: **Exit Code 0** (16/16 test files passed, 157/157 tests passed, 100% pass rate).
  - `flutter analyze` in frontend: **Exit Code 0** (No issues found, 0 errors, 0 warnings).
  - `flutter test` in frontend: **Exit Code 0** (10/10 test files passed, 77/77 tests passed, 100% pass rate).
- **Phase P2-B Summary:**
  - Tasks 1–6 (Duty Status, Real Dispatch, Incoming Request Modal, Atomic Acceptance & Decline, Lifecycle State Machine, Dakshina Collection & Closure): **ALL 6 TASKS COMPLETE (100%)**.

---

### SARV MANGAL — Stage 3: Store Cart, Checkout & Product Orders (COMPLETED)
- **Status:** DONE (100% Verified)
- **Objective:** Implement complete Pooja Samagri Store purchase foundation without breaking existing booking, dispatch, Dakshina, authentication, or payment flows.
- **Task 1: Database & Order Models (Migration 0012):**
  - Added `product_orders` and `product_order_items` tables (`src/db/schema/product_orders.ts`, migration `drizzle/0012_product_orders.sql` applied to Neon PostgreSQL).
  - Schema exports updated in `src/db/schema/index.ts` and relational bindings in `src/db/schema/relations.ts`.
  - Fields in `product_orders`: `id` (UUID pk), `customer_id` (fk users), `status` (PENDING, PROCESSING, SHIPPED, DELIVERED, CANCELLED), `payment_status` (PENDING, PAID, FAILED), `subtotal`, `delivery_charge`, `discount`, `final_amount` (`numeric(10,2)`), `shipping_address` (JSONB snapshot), `notes`, `razorpay_order_id`, `razorpay_payment_id`, `razorpay_signature`, `paid_at`, `created_at`, `updated_at`.
  - Fields in `product_order_items`: `id` (UUID pk), `order_id` (fk product_orders CASCADE), `product_id` (fk products), `product_name_snapshot`, `product_sku_snapshot`, `quantity`, `unit_price_snapshot`, `line_total` (`numeric(10,2)`), `created_at`.
  - Added indexes on `customer_id`, `status`, `payment_status`, `razorpay_order_id`, `order_id`, and `product_id`.
- **Task 2: Backend APIs (`/api/v1/product-orders`):**
  - `POST /api/v1/product-orders`: Validates cart items, queries PostgreSQL `products` table for authoritative prices, rejects missing or inactive items, enforces server-side subtotal and delivery charge rules (free if >= ₹500, else ₹50), and creates order and line items within a PostgreSQL transaction.
  - `GET /api/v1/product-orders`: Paginated list of product orders placed by authenticated user.
  - `GET /api/v1/product-orders/:id`: Returns single order details; strictly enforces customer ownership or ADMIN role.
- **Task 3: Payment Safety & Webhook Handling:**
  - `POST /api/v1/product-orders/:id/payment`: Creates or idempotently reuses Razorpay order using server-calculated amount.
  - `POST /api/v1/product-orders/:id/verify-payment`: Validates HMAC-SHA256 signature using `crypto.timingSafeEqual` and marks order `PAID` / `PROCESSING`.
  - Extended `handleWebhookEvent` in `src/services/payments.service.ts` to asynchronously process `bookings`, `productOrders`, and `dakshinaCollections` on `order.paid` and `payment.captured` without duplicating logic or breaking existing flows.
- **Task 4: Persistent Flutter Cart (`CartService` & `CartScreen`):**
  - Replaced fake `_cartCount++` with reactive, singleton `CartService` (`frontend/pandit_ssetu/lib/services/cart_service.dart`).
  - Persisted locally with `SharedPreferences` under key `sarvmangal_cart_items_v1`.
  - Quantity bounds enforced (1–99, remove when 0). Provisional subtotal and delivery charge calculated for UI display.
  - `CartScreen`: Displays items with images, steppers (+/-), line totals, free delivery progress banner, summary card, clear cart option, and checkout button.
- **Task 5: Checkout & Trusted Payment Verification (`CheckoutScreen`):**
  - Form validation for full name, mobile number, address lines, city, state, and 6-digit PIN code.
  - Submits order to backend, initializes Razorpay order, launches SDK, and calls `/verify-payment` on backend upon client callback.
  - Clears cart strictly upon server confirmation of `PAID`. Preserves cart on cancellation or error to permit retry.
- **Task 6: Remote Search & Infinite Scroll Pagination (`ShopScreen`):**
  - Debounced (350ms) search queries backend `search` parameter.
  - Category row queries backend `category` parameter.
  - `ScrollController` listener triggers next page loads on scroll near bottom, deduplicating IDs across pages.
  - Full loading, empty state with filter reset, error retry, and pull-to-refresh (`RefreshIndicator`) support.
- **Task 7: Tests & Verification:**
  - Backend: Added `src/tests/product_orders.test.ts` with 18 comprehensive tests covering validation, server pricing, ownership, transactions, idempotency, and signature verification.
  - Frontend: Added `frontend/pandit_ssetu/test/cart_and_checkout_test.dart` with 15 unit and widget tests covering CartService, persistence, CartScreen, CheckoutScreen validation, and pagination deduplication.
  - `npm run typecheck`: **Exit Code 0** (0 errors).
  - `npm run test`: **Exit Code 0** (17/17 test files passed, 175/175 tests passed, 100% pass rate).
  - `flutter analyze`: **Exit Code 0** (No issues found, 0 errors, 0 warnings).
  - `flutter test`: **Exit Code 0** (11/11 test files passed, 82/82 tests passed, 100% pass rate).

---

### Phase 6: Admin Portal
- **Goals:**
  1. Build Admin API endpoints for Pandits, Bookings, Poojas, Products, and Analytics.
  2. Secure with RBAC (`requireRole(['ADMIN'])`).
- **Status:** PENDING

---

### Phase 7: AI Spiritual Chat
- **Goals:**
  1. Implement backend AI service proxy with rate limiting and secure key management.
  2. Connect Flutter chat UI to backend AI endpoint.
- **Status:** PENDING

---

### Phase 8: Production Hardening
- **Goals:**
  1. Security audit: Helmet, rate limiting, S3 file storage, Redis OTP TTL.
  2. Migration verification and seed scripts.
  3. End-to-end regression testing.
- **Status:** PENDING
