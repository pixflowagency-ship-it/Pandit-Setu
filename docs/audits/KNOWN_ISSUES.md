# Sarvmangal / Pandit Setu — Known Issues & Technical Debt Registry

This document tracks known bugs, architectural discrepancies, false success fallbacks, and technical debt awaiting resolution across phases.

---

## 1. Client-Server Contract Mismatches

### 1.1 User Profile Route Mismatch [RESOLVED IN PHASE 1]
- **Status:** FIXED
- **Resolution:** Mounted `/profile` in `users.routes.ts` supporting `GET`, `PUT`, and `PATCH`. Added `/profile` alias to `auth.routes.ts` for backward compatibility. All 5 tests in `users.test.ts` now pass 100%.

### 1.2 Booking Payload Schema Mismatch & Silent Fallback [RESOLVED IN PHASE 1]
- **Status:** FIXED
- **Resolution:** Flutter `ApiService.createBooking()` now constructs strict Zod-compatible payloads (`poojaId`, `bookingTime` ISO 8601, `mode`, `venueAddress`, `lat`, `lng`, `samagriIncluded`). Removed silent `SharedPreferences` mock booking generation on API failure, replacing it with transparent user-facing error reporting and retry preservation.

### 1.3 Hardcoded Localhost Base URL [RESOLVED IN PHASE 1]
- **Status:** FIXED
- **Resolution:** Created `frontend/pandit_ssetu/lib/config/api_config.dart`. Supports Android Emulator loopback (`10.0.2.2:5000`), Web/Desktop (`localhost:5000`), and production/LAN via `--dart-define=API_BASE_URL=...`.

### 1.4 Hardcoded Puja Catalog & Fake IDs in BookScreen [RESOLVED IN PHASE 2]
- **Status:** FIXED
- **Resolution:** Removed ~700 lines of hardcoded static data from `book_screen.dart`. Connected `BookScreen` directly to `ApiService.getPoojas()`. Added `PoojaDetail.fromJson` which binds the real PostgreSQL UUID, real price, real duration, and real category. Booking flow now submits genuine database UUIDs to `POST /api/v1/bookings`.

### 1.5 Socket.IO Redis Unhandled Crash Without Redis [RESOLVED IN PHASE 2]
- **Status:** FIXED
- **Resolution:** Updated `src/services/realtime.service.ts` to attach non-fatal error listeners to `pubClient` and `subClient`, and gracefully fallback to Socket.IO's in-memory adapter when Redis is offline in local development.

### 1.6 Nearby Pandits Coordinates
- **Severity:** High
- **Issue:** Flutter called `GET /pandits/nearby` without `lat` and `lng` query parameters.
- **Impact:** Backend returned 400 Bad Request. Flutter fell back to a hardcoded list of 3 static pandits.
- **Resolution Plan:** Pass device location coordinates (or selected city coordinates) to `/pandits/nearby?lat=...&lng=...&radiusKm=...`.

### 1.7 Pooja Catalog Pagination Limit Mismatch (400 Bad Request) [RESOLVED]
- **Status:** FIXED
- **Root Cause:** Backend schema `paginationQuerySchema` strictly caps `limit <= 50` (`MAX_LIMIT = 50`), backed by unit test assertion `it("400 – rejects limit > 50")`. Flutter `BookScreen` invoked `ApiService.getPoojas(page: 1, limit: 100)`. Because `limit=100 > 50`, backend returned HTTP 400 `VALIDATION_ERROR: Number must be less than or equal to 50`.
- **Resolution:**
  1. Updated `BookScreen._fetchPoojas` in [book_screen.dart](file:///frontend/pandit_ssetu/lib/screens/book_screen.dart) to request `limit: 50` (matching the total 26 real poojas in the database).
  2. Updated `ApiService.getPoojas` in [api_service.dart](file:///frontend/pandit_ssetu/lib/services/api_service.dart) to clamp `limit` defensively to a maximum of 50 and print/log the exact request URL before executing the HTTP call.
- **Verification:** Live `GET /api/v1/poojas?page=1&limit=50` returns HTTP 200 OK with all 26 real poojas; tests and analyzer pass 100%.

### 1.8 Booking Date and Time Silently Overwritten by Tomorrow Fallback [RESOLVED IN BATCH P1]
- **Status:** FIXED
- **Resolution:** Created `BookingDateTimeHelper` to parse 12-hour AM/PM slots, preserve local wall-clock time, and convert to UTC ISO 8601 string. Removed silent fallback in `api_service.dart`. Verified with 19/19 passing Flutter unit tests.

### 1.9 Home Hero Carousel Slug Mismatch & Silent Fallback [RESOLVED IN BATCH P1]
- **Status:** FIXED
- **Resolution:** Replaced legacy slugs in `_heroSlides` with genuine PostgreSQL UUIDs (`67e77a47-8ffb-403a-bc64-c948ab5e2abc`, `92086a65-41a9-4545-9588-6f35c8bb8b6b`, `9ae802b2-95f9-4461-af5a-e7c32d6fb1af`, `9484cd34-05de-4b00-9621-b190d075be33`). Created `CarouselPoojaMapper` for stable environment-wide mapping. Safe feedback shown when an entry cannot be mapped.

---

## 2. False Success & Mock Fallbacks in Flutter

### 2.1 E-Commerce Samagri Store [RESOLVED IN PHASE 5]
- **Status:** FIXED
- **Resolution:** Replaced local bundled `assets/data/products.json` in `ShopScreen` with live `ApiService.getProducts()` calling `GET /api/v1/products`. Added loading, empty, and retry error states. Backend schema and migration `0007_products_catalog_sync.sql` now store full 1,267 store catalog products from `Pooja_Store_App_Product_Master_500Plus.xlsx` with complete search and category filtering. Cart order creation API remains scheduled for checkout hardening.

### 2.2 Pandit Login & Duty Dashboard [RESOLVED IN PHASE P2-B TASK 1]
- **Status:** FIXED
- **Resolution:** Replaced in-memory boolean toggle in `pandit_dashboard_screen.dart` with authoritative server-state integration. Initial duty status is loaded from `GET /api/v1/pandits/dashboard` (`isAvailable`). Toggling online queries device GPS via `geolocator` (requesting permissions and handling denial/disabled GPS defensively without fabricating coordinates) and calls `ApiService.updateDutyStatus(isAvailable, lat: lat, lng: lng)`. Backend schema validates optional `lat`/`lng` pairs, updates PostGIS geometry and Redis GEO `pandits:live`. Switch is guarded with loading state and rolls back state on network or validation errors. Verified with 18/18 backend tests and 6/6 Flutter duty status tests.

### 2.3 Video Puja & Agora Integration
- **Issue:** Flutter displays a simulated video call UI with timers. Agora SDK is not installed in `pubspec.yaml`.
- **Resolution Phase:** Phase 4.

### 2.4 AI Jyotish Chat
- **Issue:** Uses client-side `if/else` keyword matching in Dart. No backend LLM service is connected.
- **Resolution Phase:** Phase 7.

### 2.5 Consultations & Kundli
- **Issue:** Forms collect user details and open dummy Google Meet links or save in-memory objects. No backend endpoints or database tables exist for consultations or Kundli orders.
- **Resolution Phase:** Phase 5.

### 2.6 Razorpay Payment Checkout Bypassed [RESOLVED IN BATCH P1]
- **Status:** FIXED
- **Resolution:** Added `razorpay_flutter: ^1.3.7`. Implemented `ApiService.createPaymentOrder()` and `ApiService.verifyPaymentSignature()`. Integrated Razorpay test mode checkout in `PoojaBookingFlowScreen`. Booking confirmation is strictly gated on backend signature verification (`paymentStatus == 'PAID'`).

### 2.7 Pandit Verification & Protected Dashboard Access [RESOLVED IN PHASE P2-A]
- **Status:** FIXED
- **Resolution:** Resolved the root cause where newly logged-in Pandits bypassed onboarding and accessed the Pandit Dashboard immediately upon OTP entry. Implemented:
  1. Backend middleware `requireApprovedPandit` guarding `/api/v1/pandits/dashboard`, `/duty-status`, and `/accept-booking`.
  2. Authoritative 5-step onboarding workflow (`STAGE_1_PHONE_VERIFIED` -> `STAGE_2_PROFILE_COMPLETE` -> `STAGE_3_DOCS_SUBMITTED` -> `STAGE_4_VIDEO_COMPLETED` -> `APPROVED`).
  3. Secure document upload endpoint with MIME & magic-byte signature validation for PDF, PNG, and JPEG, private directory isolation (`storage/documents/<panditId>/`), and ownership-checked streaming endpoint.
  4. Video verification scheduling API (`POST /api/v1/pandits/onboarding/video-verification/schedule`) returning instructions and appointment room UUID.
  5. Administrative reviewer endpoints (`POST /documents/:id/verify`, `POST /video-verification/verify`, `POST /approve`) to record verifier identity and audit trail.
  6. Flutter navigation guard (`PanditDashboardScreen._verifyAccess()`) checking authoritative backend status and redirecting unapproved Pandits to `/pandit-onboarding`.
  7. Multi-role single phone identity support (`POST /api/v1/pandits/apply`) allowing Yajman to apply for Pandit without duplicate phone accounts.

### 2.8 Real Pooja Request Dispatch Engine [RESOLVED IN PHASE P2-B TASK 2]
- **Status:** FIXED
- **Resolution:** Replaced mock incoming booking request simulation (`Future.delayed` and fake UI test button) in Flutter `PanditDashboardScreen` with an authoritative, backend-driven dispatch engine and targeted Socket.IO event system.
  1. Implemented `dispatchBooking(bookingId)` in `src/services/dispatch.service.ts` with Redis GEO candidate discovery (`GEORADIUS` on `pandits:live`), automatic fallback to PostGIS `ST_DWithin` spatial query, and strict PostgreSQL eligibility validation (`isVerified`, `verificationStatus == 'APPROVED'`, `isAvailable`, non-stale coordinates <= 24h, Haversine distance <= `serviceRadiusKm`, identity isolation excluding Yajman, and schedule conflict validation).
  2. Integrated concurrency locking (`dispatch:lock:${bookingId}`) and notification deduplication (`dispatch:notified:${bookingId}:${panditId}`) using Redis.
  3. Structured safe, private Socket.IO payload `booking:new-request` emitted exclusively to authenticated Pandit private rooms (`pandit:user:${userId}` and `user:${userId}`), shielding sensitive Yajman details (phone number, full flat address, payment secrets).
  4. Added background trigger on `createBookingHandler` and fallback endpoint `POST /api/v1/bookings/:id/dispatch`.
  5. Connected Flutter `PanditDashboardScreen` to live WebSocket via `socket_io_client`, binding real event payloads to the notification banner with a 60-second real-time countdown timer.
  6. Verified with 15 backend tests in `src/tests/dispatch.test.ts` and 6 Flutter tests in `frontend/pandit_ssetu/test/dispatch_test.dart`.

### 2.9 Real-Time Pooja Request Modal for Pandits [RESOLVED IN PHASE P2-B TASK 3]
- **Status:** FIXED
- **Resolution:** Implemented `IncomingPoojaRequestModal` in `frontend/pandit_ssetu/lib/widgets/incoming_pooja_request_modal.dart` and integrated it into `PanditDashboardScreen`.
  1. The modal opens strictly upon receipt of genuine Socket.IO `booking:new-request` events, displaying official SARV MANGAL branding, Pooja title, mode badge (In-Person / Virtual), Dakshina earnings, Samagri kit badge, formatted date/time via `BookingDateTimeHelper.formatForDisplay()`, and approximate distance.
  2. Implemented reliable 60-second radial countdown timer anchored to event `expiresAt`, transitioning to an expired state with action lockout upon reaching 0s.
  3. Connected Accept action to `ApiService.acceptBooking(bookingId)` communicating with backend `POST /api/v1/pandits/accept-booking`, handling 200 OK, 409 Conflict (`BOOKING_ALREADY_TAKEN`), and 403 Forbidden (`PANDIT_NOT_APPROVED`), with double-tap prevention.
  4. Connected Decline action to dismiss modal and record bookingId in `_dismissedBookingIds` set to eliminate duplicate presentations across retries.
  5. Privacy-shielded venue locality removes private unit/flat numbers and omits Yajman contact numbers.
  6. Verified with 10 passing widget and unit tests in `frontend/pandit_ssetu/test/pooja_request_modal_test.dart`.

### 2.10 Atomic Booking Acceptance & Persistent Decline [RESOLVED IN PHASE P2-B TASK 4]
- **Status:** FIXED
- **Resolution:**
  1. Hardened backend `POST /api/v1/pandits/accept-booking` with explicit booking existence validation (404), approval checks (403), idempotency check for existing assignment, and PostgreSQL row-level atomic conditional update (`WHERE id = bookingId AND status = 'PENDING' AND pandit_id IS NULL RETURNING *`), ensuring exactly one Pandit wins concurrent acceptance attempts while losing requests receive HTTP 409 `BOOKING_ALREADY_TAKEN` without partial modifications.
  2. Created `booking_declines` table with unique constraint on `(booking_id, pandit_id)` and executed migration `drizzle/0009_booking_declines.sql`.
  3. Implemented `POST /api/v1/pandits/decline-booking` guarded by `requireApprovedPandit` and Zod validation supporting reasons (`TOO_FAR`, `BUSY`, `SCHEDULE_CONFLICT`, `OTHER`). Decline is recorded idempotently without modifying the booking's global status (`PENDING`).
  4. Updated `dispatch.service.ts` to authoritative query `booking_declines` and exclude previously declined Pandits from retry dispatch alerts while still notifying other eligible candidates.
  5. Updated Flutter `ApiService.declineBooking()`, integrated branded decline reason dialog in `IncomingPoojaRequestModal`, prevented double-taps with `_isSubmitting` guards disabling action buttons with loading spinners, and handled network errors truthfully without false persistence toasts.
  6. Verified with 13 new backend Vitest tests (129/129 passing) and 5 new Flutter tests (51/51 passing).

### 2.11 Booking Lifecycle State Machine & Real-Time Status Synchronization [RESOLVED IN PHASE P2-B TASK 5]
- **Status:** FIXED
- **Resolution:**
  1. Updated database schema enum `booking_status` with `HEADING_TO_VENUE`, `ARRIVED`, and `PUJA_STARTED` via migration `drizzle/0010_booking_lifecycle_statuses.sql` executed against Neon PostgreSQL.
  2. Implemented strict server-side state machine in `src/services/bookings.service.ts` enforcing the valid lifecycle:
     `CONFIRMED -> HEADING_TO_VENUE -> ARRIVED -> PUJA_STARTED -> COMPLETED`.
     - Validated caller identity: only the assigned, approved Pandit (`isVerified === true` and `verificationStatus === 'APPROVED'`) may transition lifecycle states.
     - Yajmans, unassigned Pandits, and competing Pandits are rejected with HTTP 403 `FORBIDDEN` or `PANDIT_NOT_APPROVED`.
     - Cancelled or unassigned bookings are blocked with HTTP 400.
     - Invalid, skipped, or reversed transitions are rejected with HTTP 400 `INVALID_STATUS_TRANSITION`.
     - Idempotent repeats return the existing booking with HTTP 200 without duplicate mutations.
     - Concurrency-safe atomic conditional database update (`WHERE id = bookingId AND status = expectedStatus AND pandit_id = userId RETURNING *`) under Read Committed row-level locks guarantees exactly one transition wins, rejecting concurrent races with HTTP 409 `STATUS_CONFLICT`.
  3. Real-time Socket.IO synchronization: Emits sanitized `booking:status-change` (`{ bookingId, status, timestamp }`) to authorized rooms (`booking:${id}`, `user:${yajmanId}`, `user:${panditId}`) strictly after PostgreSQL transactions commit successfully. Exposes no private phone numbers, flat numbers, auth tokens, or payment secrets. Added `booking:subscribe` event handler in `realtime.service.ts` with authorized participant checks.
  4. Flutter client integration:
     - `pandit_dashboard_screen.dart`: Connected all lifecycle buttons (`_startJourney`, `_markArrived`, `_startSankalpa`, `_completePooja`) to `ApiService.updateBookingStatus()`. Added `_isUpdatingStatus` double-tap prevention with spinner, authentic SnackBar error handling on failure, and authoritative state restoration on launch/reconnect via `_fetchActiveDuty()` and Socket.IO `booking:status-change` event listener. Removed fake timers and local-only mutations.
     - `live_pooja_tracking_screen.dart`: Connected Yajman tracking screen to authoritative `ApiService.getBookingById()` and Socket.IO real-time updates with dynamic stepper progress.
     - `bookings_screen.dart`: Added "Track Live" navigation linking directly to `/tracking?bookingId=:id`.
  5. Verified with 11 new backend unit/concurrency tests in `src/tests/bookings.test.ts` (140/140 tests pass across 15 files) and 6 new Flutter tests in `frontend/pandit_ssetu/test/booking_lifecycle_state_machine_test.dart` (57/57 tests pass across 9 test suites).

### 2.12 Dakshina Collection & Booking Closure Workflow [RESOLVED IN PHASE P2-B TASK 6]
- **Status:** FIXED
- **Resolution:**
  1. *Explicit Data Model Separation:* Initial booking creation payments and final Dakshina collections are explicitly separated into different transactions and models. Created table `dakshina_collections` (migration `drizzle/0011_dakshina_collections.sql` executed against Neon PostgreSQL) recording `booking_id`, `pandit_id`, `amount`, `currency`, `payment_method` (`CASH` | `ONLINE`), `payment_status` (`PENDING` | `PAID` | `FAILED`), `razorpay_order_id`, `razorpay_payment_id`, `razorpay_signature`, `collected_at`, and `notes`.
  2. *Cash Dakshina Workflow:*
     - Implemented `POST /api/v1/bookings/:id/dakshina/cash` guarded by `strictLimiter`, `verifyToken`, and `requireApprovedPandit`.
     - Validates positive, bounded monetary amounts (`0 < amount <= 500,000 INR`), verifies caller is the assigned, approved Pandit, and checks active lifecycle state (`PUJA_STARTED` or `IN_PROGRESS`).
     - Idempotent: If already collected/paid, returns existing record without duplicate insertions.
     - Inserts confirmed payment audit record with collector identity and timestamp, and optionally marks booking `COMPLETED` atomically.
  3. *Online Dakshina Workflow (Razorpay):*
     - Order creation `POST /api/v1/bookings/:id/dakshina/create-order` creates a Razorpay order with server-controlled amount, returning existing pending order idempotently without duplicate charges.
     - Signature verification `POST /api/v1/bookings/:id/dakshina/verify` validates HMAC-SHA256 signature (`crypto.timingSafeEqual`) using `RAZORPAY_KEY_SECRET`. Upon verification, updates payment status to `PAID`, records payment IDs and timestamps, and optionally completes the booking.
  4. *Authoritative Booking Closure Condition:*
     - Hardened `src/services/bookings.service.ts` (`updateBookingStatus`): Transitioning a booking to `COMPLETED` is strictly gated on checking PostgreSQL for a confirmed, paid Dakshina record (`paymentStatus === 'PAID'`). Direct status modification attempts without paid Dakshina are rejected with HTTP 400 `DAKSHINA_NOT_COLLECTED`.
  5. *Real-time Socket.IO Delivery:*
     - Emits sanitized `dakshina:collected` (`{ bookingId, amount, paymentMethod, paymentStatus, collectedAt, newBookingStatus }`) and `booking:status-change` to authorized rooms (`booking:${id}`, `user:${yajmanId}`, `user:${panditId}`) strictly after PostgreSQL transaction commits.
  6. *Flutter Client Integration:*
     - `pandit_dashboard_screen.dart`: Dedicated **Dakshina Collection & Booking Closure Panel** replaces simple completion buttons during `pooja_in_progress`. Supports Cash vs Online toggle, dynamic amount formatting, double-tap lockout (`_isCollectingDakshina`), loading indicators, Razorpay listener lifecycle management (`_dakshinaRazorpay.clear()` in `dispose`), and state restoration on app launch/reconnect.
     - Verified payment method details are celebrated in the `completed` view.
  7. *Verification & External Configuration:*
     - Backend: 16 Vitest tests in `src/tests/dakshina.test.ts` (157/157 passing across 16 files). `npm run typecheck` clean (0 errors).
     - Frontend: 10 tests in `frontend/pandit_ssetu/test/dakshina_collection_test.dart` (77/77 passing across 10 test files). `flutter analyze` clean (0 issues).
     - Razorpay Test Mode: Tested with cryptographic HMAC-SHA256 algorithm and server-side secret validation. Production activation requires configuring live Razorpay credentials (`RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`) and registering the production webhook endpoint.

---

## 3. Backend Infrastructure & Security Gaps

### 3.1 In-Memory OTP Store
- **Issue:** OTPs are stored in a JavaScript `Map` inside `otp.service.ts`. They do not persist across server reboots and fail across multiple processes.
- **Resolution Phase:** Phase 1.

### 3.2 Hardcoded Fallback Secrets [RESOLVED IN BATCH P1]
- **Status:** FIXED
- **Resolution:** Removed `"test_key_secret"` and `"test_webhook_secret"` fallbacks from `src/services/payments.service.ts`. Enforced strict runtime validation throwing `AppError(500, "CONFIGURATION_ERROR", ...)` if credentials are missing. Added `validateProductionConfig()` in `src/config/env.ts` to abort startup in production if payment secrets are omitted. Added unit tests for missing credentials and idempotency.

### 3.3 Production Cloud Document Storage
- **Status:** Development Integration Active (Local Secure Storage)
- **Details:** Pandit verification documents (Aadhaar, PAN, Vedic certificates) are validated via magic-byte file signatures and stored in isolated local private paths (`storage/documents/<panditId>/`). Access is protected via backend authenticated streaming route (`GET /api/v1/pandits/documents/:id/file`) restricting access strictly to the document owner and `ADMIN`. Cloud object storage (AWS S3 / GCP GCS) pre-signed URLs are architecturally prepared for production deployment.

### 3.4 Live Agora Video Calling Provider
- **Status:** Development Integration Active
- **Details:** Backend video verification endpoints schedule genuine appointments, generate room UUIDs (`videoCallRoomId`), and track verification stages (`SCHEDULED`, `COMPLETED`, `REJECTED`). Real Agora RTC token generation is ready via `agora.service.ts`. Production activation requires configuring `AGORA_APP_ID` and `AGORA_APP_CERTIFICATE` environment variables and integrating the Agora RTC Flutter SDK.

### 3.5 End-to-End Live GPS Fleet Tracking [AUDITED IN PHASE P2-B TASK 5]
- **Status:** Architecture & Backend Sync Active; Client Map & Mobile Hardware GPS Pending
- **Audit Findings:**
  1. *Status Synchronization vs. GPS Telemetry:* Booking lifecycle status synchronization (`CONFIRMED -> HEADING_TO_VENUE -> ARRIVED -> PUJA_STARTED -> COMPLETED`) is completely separated from live GPS tracking.
  2. *Backend Telemetry Ready:* `tracking.service.ts` and `tracking.controller.ts` implement Redis GEO (`GEOADD` on `pandits:live`), PostGIS coordinate persistence in `pandit_profiles`, and socket room emissions.
  3. *Client Gaps:*
     - Flutter `LivePoojaTrackingScreen` currently renders a custom painter canvas (`MapTrackingPainter` on `GridPaper`), not an active Google Maps or Mapbox widget displaying genuine device coordinates.
     - Mobile background GPS telemetry pipeline (streaming genuine device location updates from the Pandit's physical device to `PATCH /api/v1/tracking/location`) requires physical mobile device integration and permissions.
  4. *Commitment:* Real device coordinates and ETAs are not fabricated. Live GPS tracking is tracked as a distinct mobile hardware milestone and not falsely claimed as complete.

