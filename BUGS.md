# Pandit Setu (Sarvmangal) — Comprehensive Bug Audit

**Audit Timestamp:** 2026-10-14 15:25:00 IST  
**Audit Lead:** Senior QA Engineer, Full-Stack Developer & Technical Auditor  
**Workspace:** `c:\Users\krmta\OneDrive\Desktop\pndtbcknd`  
**Application Components:** Flutter Mobile Application (`frontend/pandit_ssetu`) & Node.js + TypeScript + Express Backend + AWS Neon PostgreSQL  

---

## 1. Audit Summary

### 1.1 Scope of Inspection
A complete, end-to-end repository investigation was executed across all tiers of the Pandit Setu (Sarvmangal) architecture:
1. **Frontend (Flutter / Dart):** All 19 screens, modals, state managers, API client services (`api_service.dart`), configuration (`api_config.dart`), platform manifests (`AndroidManifest.xml`), and unit/widget test suites.
2. **Backend (Node.js / TypeScript / Express):** Entry points, route controllers, middleware, Zod validators, service layers, Socket.IO realtime server, Redis adapters, and rate limiters.
3. **Database (PostgreSQL / PostGIS / Drizzle ORM):** Active cloud instance (`neondb` on AWS Neon), schemas (`users`, `poojas`, `samagri_items`, `products`, `bookings`), migrations `0000` through `0007`, and database import scripts.
4. **Data Assets (Excel Workbooks):** `Pooja List.xlsx` (26 poojas, 156 samagri ritual items) and `Pooja_Store_App_Product_Master_500Plus.xlsx` (1,267 imported catalog products).

### 1.2 Tests & Automated Checks Executed
- **Backend Test Suite (`npm run test`):** **PASS** — 14/14 test files passed, 93/93 unit tests passed in 10.33s (100% pass rate).
- **Backend TypeScript Compilation (`npm run typecheck`):** **PASS** — 0 errors (`tsc --noEmit`).
- **Flutter Static Analysis (`flutter analyze`):** **PASS** — No issues found in `frontend/pandit_ssetu` (0 errors, 0 warnings).
- **Flutter Widget/Unit Tests (`flutter test`):** **PASS** — 24/24 tests passed across 5 test suites (100% pass rate).
- **Direct Live Endpoint & Database Verification:**
  - `GET /api/v1/poojas?page=1&limit=50`: **HTTP 200 OK** (Returns all 26 database poojas).
  - Database queries: Verified users in `users`, 26 poojas in `poojas`, 156 ritual items in `samagri_items`, 1,267 items in `products`, and verified `pandits` & `pandit_documents` onboarding columns.

### 1.3 Findings Breakdown by Severity & Verification Status

| Severity | Confirmed | Code-Confirmed | Suspected | Not Verified | Resolved | Total Active |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Critical** | 0 | 0 | 0 | 0 | 4 | **0** |
| **High** | 5 | 0 | 0 | 0 | 3 | **5** |
| **Medium** | 6 | 0 | 0 | 0 | 5 | **6** |
| **Low** | 2 | 0 | 0 | 0 | 0 | **2** |
| **TOTAL** | **13** | **0** | **0** | **0** | **12** | **13** |

### 1.4 Systems Not Accessible During Audit
- **Physical Device Live USB Tether:** Inspected via source code, Android security policy analysis, and network packet flow analysis (physical device unavailable for interactive touch events during this turn).
- **Production SMS Gateway (Twilio / MSG91):** Backend currently logs OTPs to console / returns `mockOtp` in non-production mode; no active third-party SMS aggregator API keys were tested.
- **Razorpay Live Merchant Gateway:** Flutter client lacks the `razorpay_flutter` package; client payment handling is currently bypassed.

### 1.5 Overall Assessment of Application Readiness
**Status: NOT PRODUCTION READY.**  
The backend architecture is clean, strongly typed, modular, and backed by a comprehensive unit test suite (66/66 tests passing) and genuine PostgreSQL tables. However, the Flutter client contains critical architectural disconnects: user profile data is wiped on load due to a JSON parsing bug; physical Android devices cannot reach the local backend due to Android 9+ cleartext restrictions and emulator loopback defaults; 1,217 out of 1,267 store products are inaccessible due to lack of pagination; and several major modules (Pandit Duty, Video Puja, Astrological Consultations, and Live GPS Tracking) are purely client-side simulations.

---

## 2. Critical and High-Priority Bugs

### BUG-001: User Profile Overwritten with Empty Values on Load / Defaults Reappear After Relogin

- **Status:** Resolved
- **Severity:** Critical
- **Verification:** Verified (Unit tests + Live API end-to-end + Database verification)
- **Affected component:** Flutter / State Persistence
- **Affected files:** 
  - `frontend/pandit_ssetu/lib/screens/profile_screen.dart` (Lines 68–110, 1680–1730)
  - `frontend/pandit_ssetu/lib/user_data.dart` (Lines 1–65)
  - `frontend/pandit_ssetu/lib/user_profile_detail_screen.dart` (Lines 38–125)
  - `frontend/pandit_ssetu/lib/main.dart` (Lines 20–25, 160–165)
  - `frontend/pandit_ssetu/lib/services/api_service.dart` (Lines 75–118)
  - `frontend/pandit_ssetu/test/profile_and_auth_test.dart` (Regression suite)
- **Resolution Summary:**
  1. Corrected `_loadUserProfile()` in `profile_screen.dart` to read `response['data']` directly. If returned values are null or empty, existing `UserData` fields are preserved instead of being overwritten with empty strings.
  2. Implemented local persistence in `UserData` (`user_data.dart`) backed by `SharedPreferences`. Added `UserData.loadFromPrefs()`, called at application launch in `main.dart`.
  3. Added `_fetchProfileFromServer()` to `initState()` in `user_profile_detail_screen.dart` so opening details fetches live server data.
  4. Corrected `_saveChanges()` in `user_profile_detail_screen.dart` and `profile_screen.dart` to only display success SnackBar if `ApiService.updateProfile` succeeds; on failure, user-facing error SnackBar is displayed instead of swallowing the error.
  5. Synchronized database schema for `users` table to ensure `fcm_token` column exists without touching any existing user records.
- **Verification Evidence:**
  - `frontend/pandit_ssetu/test/profile_and_auth_test.dart`: 4/4 tests passed (in-memory save, SharedPreferences restore, non-destructive merge, clear).
  - Live API end-to-end: `PUT /api/v1/users/profile` succeeded and subsequent `GET /api/v1/users/profile` verified `fullName="Acharya Raman Sharma"`, `gotra="Kashyap"`, `email="raman@kashi.org"`, `city="Varanasi"`.
  - Limitation: Live physical-device touch testing depends on physical device tethering.

---

### BUG-002: Physical Android Device Fails to Connect to Local Backend (Cleartext HTTP & Loopback IP)

- **Status:** Resolved (Code & Manifest) / Physical Testing Ready
- **Severity:** Critical
- **Verification:** Verified (Manifest audit + Flutter analyze + ApiConfig verification)
- **Affected component:** Flutter / Configuration / Android Manifest
- **Affected files:**
  - `frontend/pandit_ssetu/lib/config/api_config.dart` (Lines 1–35)
  - `frontend/pandit_ssetu/android/app/src/main/AndroidManifest.xml` (Lines 1–10)
  - `frontend/pandit_ssetu/lib/user_profile_detail_screen.dart` (Lines 95–130)
- **Resolution Summary:**
  1. Added `<uses-permission android:name="android.permission.INTERNET"/>` to main `AndroidManifest.xml` so internet access is available across both debug and normal/release builds.
  2. Added `android:usesCleartextTraffic="true"` to `<application>` in main `AndroidManifest.xml` to allow standard HTTP local development communication without Android 9+ security blocks.
  3. Documented and preserved the `--dart-define=API_BASE_URL` mechanism in `api_config.dart` along with explicit USB `adb reverse` instructions (`adb reverse tcp:5000 tcp:5000`) and Wi-Fi LAN IP instructions.
  4. Fixed profile screen error handling so network errors are cleanly surfaced in a floating red error SnackBar instead of false-positive success toasts.
- **Verification Evidence:**
  - `flutter analyze` passed with 0 issues.
  - Manifest XML parsed cleanly and verified.
  - Limitation: Actual on-device execution requires physical USB tethering or shared LAN Wi-Fi connection with the testing phone.

---

### BUG-004: Incomplete Store Catalog — Only 50 of 1,267 Database Products Accessible

- **Status:** Open
- **Severity:** High
- **Verification:** Confirmed
- **Affected component:** Flutter / Store Catalog
- **Affected files:**
  - `frontend/pandit_ssetu/lib/screens/shop_screen.dart` (Lines 46, 96–115, 280–320)
  - `frontend/pandit_ssetu/lib/services/api_service.dart` (Lines 130–156)
- **User-visible symptom:** The Store screen only displays 50 products. More than 1,200 products in the database cannot be viewed, searched, or browsed. Horizontal category chips only list 4–5 categories instead of the 62 available categories.
- **Expected behavior:** The user should be able to scroll through the full catalog via infinite scroll or pagination controls. Searching should query the backend to find items across all 1,267 products. Category chips should allow browsing all categories.
- **Actual behavior:**
  1. `shop_screen.dart:46` executes a single, one-off fetch: `ApiService.getProducts(page: 1, limit: 50)`. It never requests subsequent pages (`page: 2`, `page: 3`, etc.).
  2. Category chips are derived strictly client-side from the initial 50 items (`_allProducts`). Categories present in items 51 to 1,267 never appear.
  3. Searching is executed client-side on the 50 in-memory products (`_filteredProducts`), returning "No Items Found" for any product that resides beyond the first 50 rows in the database.
- **Reproduction steps:**
  1. Open Pooja Store (`/shop`).
  2. Scroll to the bottom of the list. Observe that scrolling stops after 50 items.
  3. Search for "Bhoomi Pujan" or "Navgraha" (which exist in database rows 500+). Observe 0 results returned.
- **Evidence:**
  - Database count check: `SELECT count(*) FROM products` returns `1267`.
  - Database categories check: `SELECT count(DISTINCT category) FROM products` returns `62`.
  - `shop_screen.dart:46`: `final rawItems = await ApiService.getProducts(page: 1, limit: 50);`. No scroll listener or pagination state exists.
- **Root cause:** Absence of infinite scroll pagination and reliance on client-side filtering on a partial initial dataset.
- **Impact:** 96% of the imported e-commerce product catalog is unreachable by devotees.
- **Recommended fix:**
  1. Implement infinite scrolling via `ScrollController` in `ShopScreen` to fetch subsequent pages as the user scrolls.
  2. Connect search input to backend `ApiService.getProducts(search: query)` with debounce.
  3. Connect category chip selection to backend `ApiService.getProducts(category: selectedCategory)`.
- **Regression test:** Search for items at the end of the database catalog and verify they render correctly.
- **Dependencies:** None.

---

### BUG-005: Store Shopping Cart and Checkout Disconnected / Dead Action Buttons

- **Status:** Open
- **Severity:** High
- **Verification:** Confirmed
- **Affected component:** Flutter / E-Commerce
- **Affected files:**
  - `frontend/pandit_ssetu/lib/screens/shop_screen.dart` (Lines 220–222, 538–555)
- **User-visible symptom:** Tapping the cart icon in the top app bar does nothing. Tapping "Add to Cart" on a product increments a number and shows a toast, but there is no cart screen, no order summary, and no way to purchase products.
- **Expected behavior:** Tapping "Add to Cart" should add the product to a persistent shopping cart. Tapping the cart icon should navigate to a Cart / Checkout screen where the user can enter an address, pay, and place an order.
- **Actual behavior:** In `shop_screen.dart:221`, the cart icon has `onPressed: () {}` (empty closure). In `_ProductCard:538`, "Add to Cart" only runs `setState(() => _cartCount++)` with no cart model or persistence. No store order placement API or table exists.
- **Reproduction steps:**
  1. Open Pooja Store.
  2. Tap the shopping cart icon at the top right. Nothing happens.
  3. Tap "Add to Cart" on any product. Observe badge count increases to 1.
  4. Navigate to another screen and return. Cart count resets to 0.
- **Evidence:** `shop_screen.dart:221`: `IconButton(icon: Icon(Icons.shopping_cart_outlined), onPressed: () {})`.
- **Root cause:** Incomplete implementation. The store UI was built for catalog browsing, but cart state management and checkout flows were never developed.
- **Impact:** Users cannot complete purchases in the Pooja Store.
- **Recommended fix:** Implement a Cart state provider / SharedPreferences cart service, a dedicated Cart & Checkout screen, and backend `POST /api/v1/orders` endpoint.
- **Dependencies:** None.

---

### BUG-006: Pandit Login and Authentication Completely Mocked (No Backend Verification)

- **Status:** Resolved
- **Severity:** Critical
- **Verification:** Verified (Backend unit tests + Flutter analyze + Live endpoint verification)
- **Affected component:** Flutter / Security
- **Affected files:**
  - `frontend/pandit_ssetu/lib/screens/pandit_login_screen.dart` (Lines 50–165, 450–510)
  - `frontend/pandit_ssetu/lib/services/api_service.dart` (Lines 40–74)
  - `src/validators/auth.validator.ts` (Lines 10–18)
  - `src/controllers/auth.controller.ts` (Lines 35–45)
  - `src/services/auth.service.ts` (Lines 60–95)
  - `src/types/auth.ts` (Lines 35–50)
  - `src/tests/auth.test.ts` (Lines 80–115)
- **Resolution Summary:**
  1. Removed fake `Future.delayed()` simulation timer and removed prototype "OR DEMO ACCESS" instant-entry button.
  2. Connected `pandit_login_screen.dart` to live `ApiService.sendOtp()` and `ApiService.verifyOtp(phone, otp, 'Vedic Acharya', role: 'PANDIT')`.
  3. Added optional `role` parameter to backend `verifyOtpSchema` (`z.enum(["YAJMAN", "PANDIT"])`) and `verifyOtpAndLogin` service.
  4. On registration of a user with role `PANDIT`, backend automatically inserts a corresponding entry in the `pandits` table with default specialization.
  5. Implemented strict role check in `pandit_login_screen.dart`: if the user's role is not `PANDIT`, access is denied and an explicit error SnackBar is displayed.
  6. Returned JWT token is securely saved in `SharedPreferences` via `ApiService.setToken()`.
  7. Handled invalid OTPs, network errors, and session expiry with descriptive error SnackBars.
- **Verification Evidence:**
  - `src/tests/auth.test.ts`: Added tests for role rejection (`role: 'ADMIN'`) and successful PANDIT OTP verification (6/6 tests passing).
  - Live API testing: Tested `POST /api/v1/auth/verify-otp` with `role: "PANDIT"`, verified `role=PANDIT`, verified 401 on bad OTP.
  - SMS Limitation: As in development, OTP is verified via the backend OTP service / console log. Real SMS delivery requires configuring a third-party SMS gateway (e.g. Twilio / MSG91).

---

### BUG-007: Pandit Dashboard Duty Status, Requests, and Earnings Purely Simulated

- **Status:** Partially Resolved (Phase P2-B Task 1: Duty Status & GPS Location Toggle Complete; Tasks 2–6 Pending)
- **Severity:** High
- **Verification:** Verified (Backend tests 18/18 passing, Flutter tests 6/6 passing)
- **Affected component:** Flutter / Pandit Platform
- **Affected files:**
  - `frontend/pandit_ssetu/lib/screens/pandit_dashboard_screen.dart`
  - `frontend/pandit_ssetu/lib/services/api_service.dart`
  - `frontend/pandit_ssetu/test/pandit_duty_status_test.dart`
  - `src/validators/pandits.validator.ts`
  - `src/controllers/pandits.controller.ts`
  - `src/services/pandits.service.ts`
  - `src/tests/pandits.test.ts`
- **User-visible symptom:** The Pandit Dashboard toggle ("You are now ONLINE") only flipped a local in-memory UI switch.
- **Expected behavior:** Toggling duty sends `PATCH /api/v1/pandits/duty-status`. Initial duty status is loaded from authoritative backend dashboard endpoint. Toggling online requests device GPS coordinates via geolocator without fabrication.
- **Actual behavior (Prior to Task 1):** `_toggleOnlineState()` changed `_isOnline = !_isOnline` purely in-memory. Initial `_isOnline` was hardcoded to `true`.
- **Resolution Implemented (Task 1):**
  1. Updated `dutyStatusSchema` in `pandits.validator.ts` to accept optional `lat` (-90 to 90) and `lng` (-180 to 180), requiring both coordinates together when provided.
  2. Updated `updateDutyStatus` in `pandits.service.ts` to store `latitude`, `longitude`, and PostGIS `location` point, updating `isAvailable` in PostgreSQL and synchronizing Redis GEO key `pandits:live`.
  3. Added `isAvailable: pandit.isAvailable ?? false` to `getPanditDashboard` response.
  4. Implemented `ApiService.updateDutyStatus(isAvailable, {lat, lng})` in Flutter client.
  5. Connected `PanditDashboardScreen` to fetch authoritative initial availability from `getPanditDashboard()` and request real GPS coordinates via `Geolocator`. Added loading spinner and error recovery preserving previous server state on error.
  6. Added 100% passing test coverage in `src/tests/pandits.test.ts` (18/18 tests) and `pandit_duty_status_test.dart` (6/6 tests).
- **Completed in Phase P2-B:**
  - Task 1: Pandit Duty Status API Integration + Live Location Toggle.
  - Task 2: Real Pooja Request Dispatch Engine (Redis GEO candidate discovery, PostGIS fallback, PostgreSQL eligibility enforcement, concurrency locking, deduplication, targeted Socket.IO `booking:new-request` emission, and Flutter dashboard WebSocket integration).
  - Task 3: Real-Time Pooja Request Modal for Pandits (Production-grade `IncomingPoojaRequestModal` with 60s countdown, Dakshina & Samagri display, sanitized venue locality, authoritative `ApiService.acceptBooking()` integration, duplicate presentation guards, and 10 widget tests).
  - Task 4: Atomic Pooja Acceptance, Persistent Decline & Concurrency Safety (Hardened backend acceptance with atomic conditional update under Read Committed row locking, `booking_declines` table with unique composite constraint, idempotent decline endpoint, dispatch exclusion, and Flutter decline dialog with loading state and double-tap prevention).
  - Task 5: Booking Lifecycle & Real-Time Status Synchronization (PostgreSQL migration adding `HEADING_TO_VENUE`, `ARRIVED`, `PUJA_STARTED`, server-enforced state machine in `bookings.service.ts` with caller authorization, idempotency, atomic conditional update, Post-Commit Socket.IO `booking:status-change` emission to authorized rooms, and Flutter dashboard/tracking synchronization with fake timer removal and reconnect recovery).
- **Remaining Scope for Phase P2-B:** Task 6 (Cash / Online Dakshina Collection & Booking Closure).


---

### BUG-008: Booking Selected Date and Time Overwritten by Hardcoded Fallback

- **Status:** Resolved
- **Severity:** High
- **Verification:** Verified (Flutter unit tests + UTC ISO roundtrip verification)
- **Affected component:** Flutter / Booking Flow
- **Affected files:**
  - `frontend/pandit_ssetu/lib/screens/pooja_booking_flow_screen.dart`
  - `frontend/pandit_ssetu/lib/services/api_service.dart`
  - `frontend/pandit_ssetu/lib/utils/booking_date_time_helper.dart` (Created)
  - `frontend/pandit_ssetu/test/booking_and_payment_integrity_test.dart` (Created)
- **Actual Root Cause:** `pooja_booking_flow_screen.dart` sent `'date': 'DD/MM/YYYY'` and `'timeSlot': '09:30 AM'`, but omitted `bookingTime`. In `api_service.dart`, an `if (!bookingTime.contains('T'))` check failed, silently falling back to `DateTime.utc(tomorrow.year, tomorrow.month, tomorrow.day, 9, 30).toIso8601String()`.
- **Fix Implemented:** Created `BookingDateTimeHelper` that accurately parses 12-hour AM/PM time slots, constructs local DateTime, converts to UTC ISO 8601 string, and validates payloads. Removed the silent fallback in `api_service.dart`; invalid or missing date/time selections now throw an explicit `FormatException`.
- **Tests Run & Actual Results:** `flutter test` passed 19/19 tests (including morning slots, evening slots, boundary 12:00 PM/AM, timezone conversion roundtrips, and invalid format rejections).
- **Remaining Manual Verification:** Interactive tap test on real physical device to verify stored timestamp in PostgreSQL.

---

### BUG-009: Booking Payment Flow Completely Bypassed / False Confirmation Dialog

- **Status:** Resolved
- **Severity:** High
- **Verification:** Verified (Razorpay order creation + backend signature verification + Flutter test mode integration)
- **Affected component:** Flutter / Payments
- **Affected files:**
  - `frontend/pandit_ssetu/pubspec.yaml`
  - `frontend/pandit_ssetu/lib/screens/pooja_booking_flow_screen.dart`
  - `frontend/pandit_ssetu/lib/services/api_service.dart`
  - `src/routes/payments.routes.ts`
  - `src/services/payments.service.ts`
  - `src/tests/payments.test.ts`
- **Actual Root Cause:** `razorpay_flutter` was missing from `pubspec.yaml`. `_handleConfirmAndPay()` directly invoked `_showSuccessDialog()` immediately after `createBooking()` without creating a Razorpay order, presenting checkout, or verifying payment.
- **Fix Implemented:** Added `razorpay_flutter: ^1.3.7`. Implemented `ApiService.createPaymentOrder()` (`POST /api/v1/payments/create-order`) and `ApiService.verifyPaymentSignature()` (`POST /api/v1/payments/verify-signature`). Integrated Razorpay test mode checkout into `PoojaBookingFlowScreen`. Confirmation dialog is now gated strictly on backend signature verification (`paymentStatus == 'PAID'`). Client callbacks are never treated as authoritative proof of payment. Payment cancellations and errors show descriptive failure SnackBars and leave bookings in pending state.
- **Tests Run & Actual Results:** Backend vitest suite passed 12/12 payment tests. Flutter test suite passed 19/19 tests.
- **Remaining Manual Verification:** Interactive test-mode card/UPI checkout on physical Android device with Razorpay Test Mode credentials.

---

### BUG-011: Live Pooja Tracking Decoupled from Backend and Database [RESOLVED - STATUS SYNCHRONIZATION]

- **Status:** Resolved (Status Synchronization) / Partial (Continuous GPS Telemetry Separated)
- **Severity:** High
- **Verification:** Verified
- **Affected component:** Flutter / Realtime Tracking
- **Affected files:**
  - `frontend/pandit_ssetu/lib/screens/live_pooja_tracking_screen.dart`
  - `frontend/pandit_ssetu/lib/services/api_service.dart`
  - `frontend/pandit_ssetu/lib/screens/bookings_screen.dart`
- **Resolution:**
  1. Updated `LivePoojaTrackingScreen` to accept optional `bookingId` parameter and fetch authoritative booking details from `ApiService.getBookingById()` or active list via `ApiService.getUserBookings()`.
  2. Connected authenticated `socket_io_client` to `ApiConfig.socketUrl`, joining `booking:subscribe` and synchronizing stepper progress truthfully on `booking:status-change`.
  3. Added "Track Live" button in `BookingsScreen` on upcoming/active bookings linking directly to `/tracking?bookingId=:id`.
  4. Note: Continuous mobile GPS background telemetry and native Google Maps / Mapbox display audited separately as non-blocking for status lifecycle.

---

### BUG-018: Missing Essential Hardware & Platform SDKs in Flutter pubspec.yaml

- **Status:** Open
- **Severity:** High
- **Verification:** Confirmed
- **Affected component:** Flutter / Platform Integrations
- **Affected files:**
  - `frontend/pandit_ssetu/pubspec.yaml` (Lines 30–42)
  - `frontend/pandit_ssetu/android/app/src/main/AndroidManifest.xml`
- **User-visible symptom:** Features relying on GPS location (nearby temples, nearby pandits), video calling (online video puja), push notifications, and payment checkout cannot function natively on mobile hardware.
- **Expected behavior:** Required hardware plugins and permissions should be declared and configured.
- **Actual behavior:** `pubspec.yaml` only contains 6 basic packages: `cupertino_icons`, `google_fonts`, `go_router`, `cached_network_image`, `http`, and `shared_preferences`. Missing:
  - `geolocator` or `location` (for PostGIS nearby queries)
  - `razorpay_flutter` (for payments)
  - `agora_rtc_engine` (for live video puja)
  - `socket_io_client` (for realtime tracking and chat)
  - `firebase_messaging` (for push alerts)
- **Reproduction steps:** Inspect `pubspec.yaml` dependencies list.
- **Evidence:** `frontend/pandit_ssetu/pubspec.yaml:30-42`.
- **Root cause:** Prototype project setup deferred hardware SDK installations.
- **Impact:** Core production features cannot interact with device sensors, camera, microphone, or push services.
- **Recommended fix:** Add missing dependencies to `pubspec.yaml` and configure required Android permissions in `AndroidManifest.xml`.
- **Dependencies:** None.

---

## 3. User Authentication and Profile

### BUG-020: SMS OTP Service Only Logs to Console with No SMS Gateway Provider

- **Status:** Open
- **Severity:** Medium
- **Verification:** Confirmed
- **Affected component:** Backend / SMS Integration
- **Affected files:**
  - `src/services/sms.service.ts` (Lines 4–9)
  - `src/services/auth.service.ts` (Lines 29–31)
- **User-visible symptom:** On a physical phone in production mode, users never receive an SMS on their phone carrier network.
- **Expected behavior:** `sendOtp()` should dispatch a real SMS via a transactional SMS gateway (Twilio, MSG91, or Fast2SMS) containing the 6-digit code.
- **Actual behavior:** `src/services/sms.service.ts` contains only a stub logging `"SMS OTP generated (mock)"` via Pino.
- **Evidence:** `src/services/sms.service.ts:4-9`.
- **Root cause:** SMS service is a development stub with no external SMS provider SDK or HTTP API integrated.
- **Impact:** Real users cannot log in outside of development mode where `mockOtp` is exposed in API responses.
- **Recommended fix:** Integrate an SMS aggregator provider in `sms.service.ts` enabled via `SMS_PROVIDER_API_KEY`.
- **Dependencies:** None.

---

### BUG-021: Backend verify-otp Returns Incomplete User Object

- **Status:** Open
- **Severity:** Medium
- **Verification:** Confirmed
- **Affected component:** Backend / Auth API
- **Affected files:**
  - `src/services/auth.service.ts` (Lines 87–93)
- **User-visible symptom:** Immediately after OTP login, astrological attributes (Gotra, Zodiac, DOB, City) are missing from client state until an explicit profile fetch occurs.
- **Expected behavior:** `verifyOtpAndLogin` should return the full user record including all profile and astrological columns.
- **Actual behavior:** Returns only `{ id, phone, name, role }`.
- **Evidence:** `src/services/auth.service.ts:87-93`.
- **Root cause:** Minimal response object construction in auth service.
- **Impact:** Frontend must make a redundant HTTP request immediately after login to acquire user profile data.
- **Recommended fix:** Return complete user object in `verifyOtpAndLogin` response payload.
- **Dependencies:** None.

---

## 4. Pooja Catalog and Booking

### BUG-003: Pooja Catalog Returned HTTP 400 Bad Request on BookScreen

- **Status:** Resolved
- **Severity:** High
- **Verification:** Resolved
- **Affected files:**
  - `frontend/pandit_ssetu/lib/screens/book_screen.dart` (Line 60)
  - `frontend/pandit_ssetu/lib/services/api_service.dart` (Lines 114–122)
  - `src/validators/poojas.validator.ts`
- **User-visible symptom:** BookScreen displayed `"Failed to fetch Pooja's catalog (400)"` with a Retry button.
- **Root cause:** `book_screen.dart:60` requested `limit: 100`. Backend schema `paginationQuerySchema` strictly caps `limit <= 50`. Zod validation threw `VALIDATION_ERROR`.
- **Resolution verified:** Fixed `book_screen.dart` to request `limit: 50` and clamped `limit` defensively in `api_service.dart`. Live endpoint `GET /api/v1/poojas?page=1&limit=50` now returns HTTP 200 with all 26 database poojas.

---

### BUG-010: Home Screen Hero Carousel Taps Always Open Same Default Pooja

- **Status:** Resolved
- **Severity:** Medium
- **Verification:** Verified (Flutter unit tests + UUID database matching)
- **Affected component:** Flutter / Home Screen
- **Affected files:**
  - `frontend/pandit_ssetu/lib/screens/home_screen.dart`
  - `frontend/pandit_ssetu/lib/utils/carousel_pooja_mapper.dart` (Created)
  - `frontend/pandit_ssetu/test/booking_and_payment_integrity_test.dart` (Created)
- **Actual Root Cause:** Carousel `_heroSlides` contained legacy string slugs (`navratri_pooja`, `satyanarayan_katha`, `griha_pravesh_pooja`, `mahamrityunjaya_jaap`) instead of PostgreSQL UUIDs. Because `_trendingRituals` only contained UUIDs, `firstWhere` failed and defaulted unconditionally to `_trendingRituals[0]` (Griha Pravesh).
- **Fix Implemented:** Replaced legacy slugs with verified PostgreSQL database UUIDs (`67e77a47-8ffb-403a-bc64-c948ab5e2abc`, `92086a65-41a9-4545-9588-6f35c8bb8b6b`, `9ae802b2-95f9-4461-af5a-e7c32d6fb1af`, `9484cd34-05de-4b00-9621-b190d075be33`). Created `CarouselPoojaMapper` to resolve slides by UUID or legacy slug across environments. Added `Navratri Pooja` and `Mahamrityunjaya Jaap` to `_trendingRituals`. Replaced fallback to `_trendingRituals[0]` with safe disabled action and user feedback SnackBar when unmapped.
- **Tests Run & Actual Results:** `flutter test` passed 19/19 tests (including UUID lookup, legacy slug mapping, and unmapped safe null return).
- **Remaining Manual Verification:** Tap each hero banner in mobile UI and verify opened modal matches the banner ritual.

---

## 5. Store and Product Catalog

### BUG-024: Product Images Rely on Unsplash Keyword Heuristics (No CDN Image Assets)

- **Status:** Open
- **Severity:** Low
- **Verification:** Confirmed
- **Affected component:** Backend Importer / Flutter Store
- **Affected files:**
  - `src/db/import_store_products_excel.ts` (Lines 22–54)
  - `frontend/pandit_ssetu/lib/screens/shop_screen.dart` (Lines 571–592)
- **User-visible symptom:** Different products in the same category (e.g. 10 different types of deepaks) display the exact same generic stock photograph.
- **Expected behavior:** Each catalog item should have a dedicated, authentic product photo hosted on Cloudinary, AWS S3, or Firebase Storage.
- **Actual behavior:** The source Excel sheet `App_Import` had empty `Image_URL` columns. The importer and Flutter client use keyword regex fallbacks to 6 generic Unsplash URLs.
- **Evidence:** `src/db/import_store_products_excel.ts:22-54`.
- **Root cause:** Source Excel workbook lacked product photography URLs.
- **Impact:** Repetitive visuals diminish the premium feel of the Pooja Store.
- **Recommended fix:** Upload genuine product photos to cloud storage and update `products.image_url` via an update migration.
- **Dependencies:** None.

---

## 6. Database and Data Persistence

### BUG-014: Astrological Profile Updates in KundliScreen Never Persisted to Database

- **Status:** Open
- **Severity:** Medium
- **Verification:** Confirmed
- **Affected component:** Flutter / Astrological Profile
- **Affected files:**
  - `frontend/pandit_ssetu/lib/screens/kundli_screen.dart` (Lines 41–60)
- **User-visible symptom:** A user updates their birth details (DOB, TOB, POB, Gotra, Zodiac) on the Kundli screen and sees `"Astrological Profile updated successfully!"`. However, leaving the screen or closing the app discards the changes completely.
- **Expected behavior:** Birth and astrological parameter edits should be sent to `ApiService.updateProfile()` and persisted in the `users` table.
- **Actual behavior:** `_saveAstroProfile()` only invokes `UserData.save(...)` in memory. It never makes an HTTP call to the backend.
- **Evidence:** `kundli_screen.dart:41-53`: No `ApiService` call exists in `_saveAstroProfile()`.
- **Root cause:** Omission of backend sync in Kundli profile form submit handler.
- **Impact:** Inability to retain devotee astrological information.
- **Recommended fix:** Add `await ApiService.updateProfile({...})` inside `_saveAstroProfile()`.
- **Dependencies:** None.

---

## 7. Backend APIs and Integrations

### BUG-019: Backend Server Lacks Explicit 0.0.0.0 Interface Binding

- **Status:** Resolved
- **Severity:** Medium
- **Verification:** Verified (Backend server start + LAN interface binding verification)
- **Affected component:** Backend Server
- **Affected files:**
  - `src/server.ts` (Line 20)
- **Resolution Summary:**
  1. Updated `src/server.ts` line 20 to explicitly bind the HTTP server to all network interfaces: `const host = process.env.HOST || "0.0.0.0"; httpServer.listen(env.port, host, () => ...);`.
  2. Preserved the configured port (`PORT=5000`), error handling, and graceful shutdown behavior.
  3. Verified health check endpoint `http://127.0.0.1:5000/health` responds with `{"success": true, "status": "UP"}`.
  4. Note on external constraints: Physical devices connecting over Wi-Fi LAN require Windows Firewall to permit incoming TCP traffic on port 5000 for Node.js, and both PC and phone must be on the same local network subnet (or connected via USB with `adb reverse`).

---

### BUG-022: Nearby Pandits Endpoint Fails with 400 If Coordinates Omitted

- **Status:** Open
- **Severity:** Medium
- **Verification:** Confirmed
- **Affected component:** Backend API / Validator
- **Affected files:**
  - `src/validators/pandits.validator.ts` (Lines 1–15)
  - `frontend/pandit_ssetu/lib/services/api_service.dart` (Lines 176–200)
- **User-visible symptom:** If the client calls `GET /api/v1/pandits/nearby` without query parameters, backend responds with 400 Bad Request.
- **Expected behavior:** The endpoint should either default to a central coordinate (e.g. Varanasi / Delhi) or return an empty list with clear validation guidance, and Flutter should query device GPS.
- **Actual behavior:** Strict Zod validator rejects any request without `lat`, `lng`, and `radiusKm`. Flutter currently hardcodes Delhi coordinates (`28.6139, 77.2090`) to prevent crashing.
- **Evidence:** `src/validators/pandits.validator.ts:3-12`.
- **Root cause:** Mandatory query params without server-side defaults.
- **Impact:** Real device location cannot be leveraged without proper GPS client integration.
- **Recommended fix:** Install `geolocator` in Flutter to supply actual user coordinates to `getNearbyPandits()`.
- **Dependencies:** BUG-018.

---

## 8. Flutter UI and User Experience

### BUG-017: Panchang Screen Hardcodes Calendar Date to September 2026

- **Status:** Open
- **Severity:** Low
- **Verification:** Confirmed
- **Affected component:** Flutter / Panchang
- **Affected files:**
  - `frontend/pandit_ssetu/lib/screens/panchang_screen.dart` (Lines 18–37)
- **User-visible symptom:** Opening the Panchang screen always shows the calendar centered on September 8, 2026, regardless of the actual current date.
- **Expected behavior:** The screen should initialize to `DateTime.now()` and display today's actual Tithi, Nakshatra, and Rahu Kaal.
- **Actual behavior:** `_selectedDate` is hardcoded to `DateTime(2026, 9, 8)`. The festival list is a static map of 10 hardcoded festival dates in late 2026.
- **Evidence:** `panchang_screen.dart:35-36`: `_selectedDate = DateTime(2026, 9, 8); _focusedMonth = DateTime(2026, 9, 1);`.
- **Root cause:** Hardcoded prototype date values.
- **Impact:** Devotees cannot check current real-time Panchang without manually scrolling back to today's date.
- **Recommended fix:** Change initialization to `DateTime.now()`.
- **Dependencies:** None.

---

### BUG-023: Flutter Automated Widget Test Fails Due to Rebranded Splash Screen Title

- **Status:** Open
- **Severity:** Low
- **Verification:** Confirmed
- **Affected component:** Flutter Tests
- **Affected files:**
  - `frontend/pandit_ssetu/test/widget_test.dart` (Lines 12–13)
### BUG-023: Automated Flutter Widget Test Fails Due to Stale Brand Name

- **Status:** Resolved
- **Severity:** Low
- **Verification:** Verified (`flutter test`)
- **Affected component:** Flutter / Automated Testing
- **Affected files:**
  - `frontend/pandit_ssetu/test/widget_test.dart`
- **Actual Root Cause:** `splash_screen.dart` was rebranded to display `"SARV MANGALS"`, but `widget_test.dart` looked for legacy `"Pandit Setu"`.
- **Fix Implemented:** Updated `widget_test.dart` assertion to expect `'SARV MANGALS'` and `'Sacred Vedic Rituals & Astrological Guidance'`.
- **Tests Run & Actual Results:** `flutter test` passed with 0 failures.

---

### BUG-026: Insecure Hardcoded Fallback Secrets for Razorpay Payments & Webhooks

- **Status:** Resolved
- **Severity:** Critical
- **Verification:** Verified (Backend unit tests + Startup validation check)
- **Affected component:** Backend / Payments Security
- **Affected files:**
  - `src/services/payments.service.ts`
  - `src/config/env.ts`
  - `src/routes/payments.routes.ts`
  - `src/tests/payments.test.ts`
  - `src/tests/subscriptions.test.ts`
  - `vitest.config.ts`
- **Actual Root Cause:** `payments.service.ts` contained hardcoded fallback strings `"test_key_secret"` and `"test_webhook_secret"`. In unconfigured environments or production misconfigurations, HMAC SHA-256 signatures could be forged using these known static keys.
- **Fix Implemented:** Removed all hardcoded fallback secrets. Added strict runtime checks throwing `AppError(500, "CONFIGURATION_ERROR", ...)` if credentials are missing. Added `validateProductionConfig()` in `src/config/env.ts` to abort startup in production if payment credentials are not set. Added idempotency guard in `verifyPaymentSignature` for already PAID bookings. Added `/verify-signature` route alias. Added `pool: "forks"` to `vitest.config.ts` for clean test worker teardown on Windows.
- **Tests Run & Actual Results:** `npm run test` passed 73/73 tests across 13 test files (including new unit tests for missing credentials, production validation, idempotency, and `/verify-signature` route alias). `npm run typecheck` passed with 0 errors.
- **Remaining Manual Verification:** Ensure production environment `.env` contains valid production Razorpay keys before launch.

---

## 9. Incomplete, Mock, and Hardcoded Features

The following features currently exist only as visual mockups or client-side simulations with no genuine backend integration:

1. **AI Jyotish Chat (`widgets/pandit_chat_modal.dart:74-95`):**
   - Implemented via Dart `if/else` keyword matching (`contains('marriage')`, `contains('career')`).
   - Responses are canned static strings with `Future.delayed(1200ms)`.
   - No backend LLM service or Gemini API is connected.
2. **Astrological Consultations (`widgets/consultation_flow_modal.dart:1204-1260`):**
   - Displays a static Google Meet URL (`https://meet.google.com/smg-vedic-session-7842`).
   - Claims "PANDIT ASSIGNED FROM ADMIN PANEL" without creating any database records or scheduling sessions.
3. **Flower & Garland Subscriptions (`screens/phool_mala_screen.dart:623-645`):**
   - "Subscribe Now" button immediately shows a success popup without charging the user or calling backend subscription routes (`POST /api/v1/subscriptions`).
4. **Nearest Temples Screen (`screens/nearest_temple_screen.dart:16-65`):**
   - Uses a hardcoded list of 4 Ujjain temples.
   - Backend Google Places integration (`GET /api/v1/temples/nearby`) is never called by the screen.
5. **Video Puja (`screens/live_pooja_tracking_screen.dart`):**
   - Agora WebRTC SDK is not present in Flutter; video sessions are simulated timers.

---

## 10. Configuration and Physical Android Device

### Network Architecture & Connectivity Summary

| Environment | Client Base URL | Connectivity Status | Notes |
| :--- | :--- | :--- | :--- |
| **Android Emulator** | `http://10.0.2.2:5000/api/v1` | **WORKING** | Resolves to host machine via emulator virtual router. |
| **Physical Android Device** | `http://10.0.2.2:5000/api/v1` (Default) | **BROKEN** | `10.0.2.2` does not exist on physical hardware. |
| **Physical Android Device** | `http://<LAN_IP>:5000/api/v1` | **BLOCKED** | Blocked by Android OS due to missing `usesCleartextTraffic`. |
| **Physical Android Device (USB)**| `http://localhost:5000/api/v1` + `adb reverse` | **BLOCKED** | Requires manifest cleartext permission and `--dart-define`. |

### Remediation Checklist for Physical Device Deployment
1. Add `android:usesCleartextTraffic="true"` to `frontend/pandit_ssetu/android/app/src/main/AndroidManifest.xml`.
2. Add `<uses-permission android:name="android.permission.INTERNET"/>` to `src/main/AndroidManifest.xml`.
3. Bind backend Express server to `0.0.0.0` in `src/server.ts`.
4. Launch Flutter with `--dart-define=API_BASE_URL=http://<PC_LAN_IP>:5000/api/v1` or configure USB port reverse.

---

## 11. Security and Production Readiness

1. **Hardcoded Development OTPs:** `PanditLoginScreen` hardcodes OTP `123456` in client code.
2. **CORS Configuration:** `app.ts` defaults `CORS_ORIGIN=*` if not configured. For production, restrict to verified mobile app origins and admin portal domains.
3. **Database Secrets:** Database credentials are securely loaded via `.env` and are not committed to source control.
4. **Firebase Admin Credentials:** Backend logs warning on startup if `FIREBASE_SERVICE_ACCOUNT_BASE64` or `PATH` is missing. Push notifications gracefully no-op in development.

---

## 12. Testing and Current Coverage

### Current Test Execution Summary
- **Backend (Vitest):** 14 test files passed, 93 tests passed (100% pass rate).
- **Frontend (Flutter Test):** 24 tests passed across 5 test suites (100% pass rate).
- **Static Analysis:** `tsc --noEmit` passed with 0 errors; `flutter analyze` passed with 0 issues.

---

## 13. Lower-Priority Bugs and Improvements

- **BUG-017:** Panchang screen calendar date initialized to static September 2026.
- **BUG-024:** Store product images using keyword-based Unsplash placeholders.

---

## 14. Resolved Issues

- **BUG-025 (Pandit Dashboard Bypass & Role Authorization) [RESOLVED IN PHASE P2-A]:**
  - *Root Cause:* Flutter `PanditLoginScreen` immediately navigated to `/pandit-dashboard` upon OTP verification, ignoring backend verification and approval status. Backend `/api/v1/pandits/dashboard` only checked JWT role `PANDIT` without checking `verificationStatus === 'APPROVED'`.
  - *Resolution:* Implemented backend `requireApprovedPandit` middleware strictly gating dashboard access. Built 5-step onboarding and verification state machine (`STAGE_1_PHONE_VERIFIED` -> `STAGE_2_PROFILE_COMPLETE` -> `STAGE_3_DOCS_SUBMITTED` -> `STAGE_4_VIDEO_COMPLETED` -> `APPROVED`). Added multi-role single-identity support (Yajman can apply for Pandit without duplicate phone record; Pandit can access Yajman portal). Added full route guard `_verifyAccess()` in `PanditDashboardScreen`.
- **BUG-023 (Branding Title Discrepancy in widget_test.dart) [RESOLVED IN PHASE P2-A]:**
  - *Resolution:* Standardized official application display name to **SARV MANGAL** (`AppBranding.appDisplayName = 'SARV MANGAL'`) across constants, splash screen, onboarding, manifests (`AndroidManifest.xml`, `Info.plist`, `web/index.html`), and updated test assertion in `widget_test.dart`.
- **BUG-003 (Pooja Catalog HTTP 400 Bad Request):** Resolved by aligning client limit to 50 in `book_screen.dart:60` and clamping defensively in `api_service.dart`. Tested and verified live with 26 poojas returned.
- **RES-001 (Store Catalog Product Master Synchronization):** Imported 1,267 store catalog products from `Pooja_Store_App_Product_Master_500Plus.xlsx` into PostgreSQL `products` table via `0007_products_catalog_sync.sql`.
- **RES-002 (User Profile Route Mounting):** Mounted `/profile` in `users.routes.ts` supporting `GET`, `PUT`, and `PATCH`.

---

## 15. Verification Blockers

1. **Physical Device Live Verification:** Requires applying Android manifest cleartext permissions before physical device HTTP requests can be accepted by the Android OS.
2. **Third-Party Payment Verification:** Requires active Razorpay API keys and Flutter SDK installation to verify end-to-end checkout.

---

## 16. Prioritized Fix Roadmap

### Batch P0: Critical Blockers & Persistence [COMPLETED]
*Dependencies: None*
1. **[RESOLVED] Fix BUG-001 (User Profile Data Wipe):** Fixed `response['data']` parsing in `profile_screen.dart`, added `_fetchProfileFromServer()` in `user_profile_detail_screen.dart`, added `SharedPreferences` persistence to `UserData`, and verified with regression tests and live database roundtrip.
2. **[RESOLVED] Fix BUG-002 (Physical Android Cleartext & Network):** Added `android:usesCleartextTraffic="true"` and `INTERNET` permission to `src/main/AndroidManifest.xml`, documented `--dart-define` and USB `adb reverse` workflows, and improved network error reporting.
3. **[RESOLVED] Fix BUG-019 (Backend 0.0.0.0 Binding):** Bound `httpServer.listen` to `process.env.HOST || "0.0.0.0"` in `src/server.ts`.
4. **[RESOLVED] Fix BUG-006 (Pandit Login Verification):** Replaced simulated fake login with live `sendOtp` and `verifyOtp` with role `PANDIT`, implemented backend pandit record creation, and added unit tests in `src/tests/auth.test.ts`.

### Batch P1: Core Rituals, Catalog & Booking Fidelity
*Dependencies: P0*
1. **Fix BUG-004 (Store Catalog Pagination & Search):** Add infinite scroll or pagination controls to `ShopScreen` and wire search/category chips to backend API parameters.
2. **Fix BUG-008 (Booking Date & Time Format):** Format user-selected date and time slot into ISO 8601 string before calling `ApiService.createBooking()`.
3. **Fix BUG-010 (Hero Carousel Tap Mismatch):** Update `_heroSlides` with actual database pooja UUIDs.
4. **Fix BUG-023 (Failing Flutter Test):** Update `widget_test.dart` to expect `'SARV MANGALS'`.

### Batch P2-A: Multi-Role Auth, Onboarding & Protected Dashboard [COMPLETED]
*Status: 100% Verified (93 backend tests, 24 flutter tests passing)*
1. **[RESOLVED] BUG-025 (Pandit Dashboard Bypass & Role Authorization):** Implemented backend `requireApprovedPandit` middleware guarding `/dashboard`, `/duty-status`, and `/accept-booking`. Built authoritative 5-step onboarding state machine and route protection.
2. **[RESOLVED] BUG-023 (Branding Standardized to SARV MANGAL):** Centralized `AppBranding.appDisplayName = 'SARV MANGAL'` across all Flutter screens and platform manifests.

### Batch P2-B: Pandit Duty Status, Geospatial Location & Live Booking Dispatch [IN PROGRESS - TASKS 1-5 COMPLETED]
*Prerequisites: Batch P2-A completed*
1. **[RESOLVED] TASK 1 — Online/Offline Duty Status:** Wire `PanditDashboardScreen._toggleOnlineState` to `PATCH /api/v1/pandits/duty-status` with real-time UI synchronization and Geolocator GPS integration.
2. **[RESOLVED] TASK 2 — Real Booking Dispatch Engine:** Discovers nearby available approved Pandits (Redis GEO + PostGIS fallback), checks availability, and emits targeted Socket.IO events (`booking:new-request`).
3. **[RESOLVED] TASK 3 — Real-Time Pooja Request Modal:** Incoming Pooja modal with 60-second real-time countdown ring, Dakshina earnings display, and privacy shielding.
4. **[RESOLVED] TASK 4 — Atomic Booking Acceptance, Persistent Decline & Concurrency Safety:**
   - Atomic conditional update in PostgreSQL (`WHERE id = bookingId AND status = 'PENDING' AND pandit_id IS NULL RETURNING *`), ensuring single-winner assignment under concurrent requests and 409 Conflict rejection for losers without partial mutation.
   - Persistent decline endpoint `POST /api/v1/pandits/decline-booking` recording decisions in new `booking_declines` table (Migration `0009_booking_declines.sql`) with composite unique constraint `(booking_id, pandit_id)` and reason validation (`TOO_FAR`, `BUSY`, `SCHEDULE_CONFLICT`, `OTHER`). Global booking status remains `PENDING`.
   - Dispatch engine excludes declined candidates from retry alerts while keeping other candidates eligible.
   - Flutter `IncomingPoojaRequestModal` includes decline reason dialog, double-tap protection via `_isSubmitting`, and authentic network error handling.
5. **[RESOLVED] TASK 5 — Booking Lifecycle State Machine & Real-Time Status Synchronization:**
   - Safe PostgreSQL migration `0010_booking_lifecycle_statuses.sql` adding `HEADING_TO_VENUE`, `ARRIVED`, `PUJA_STARTED` to `booking_status` enum.
   - Strict server-side state machine: `CONFIRMED → HEADING_TO_VENUE → ARRIVED → PUJA_STARTED → COMPLETED`.
   - Authorization: Only assigned, approved Pandit can trigger transitions; unassigned bookings, wrong Pandits, unapproved Pandits, and Yajmans are rejected (400/403). Skipped, reversed, or cancelled transitions are blocked (400/409).
   - Atomic conditional update (`WHERE id = bookingId AND status = expectedStatus AND pandit_id = userId`) prevents concurrent overwrite races.
   - Authenticated Socket.IO delivery (`booking:status-change`) and FCM push notifications with sanitized payloads emitted only after database transaction commits.
   - Flutter `PanditDashboardScreen` wired to real APIs with double-tap protection, loading spinners, state preservation on failure, and automatic duty state restoration on reconnect/reload.
   - Devotee `LivePoojaTrackingScreen` loads authoritative booking from `ApiService.getBookingById()`, listens to Socket.IO `booking:status-change`, and synchronizes stepper truthfully.
6. **[RESOLVED] TASK 6 — Dakshina Collection & Booking Closure:**
   - Explicit data modeling for Dakshina collections (`dakshina_collections` table, Migration `0011_dakshina_collections.sql`), cleanly separated from initial booking creation payments.
   - Cash Dakshina collection API `POST /api/v1/bookings/:id/dakshina/cash` with server-side positive bounded amount validation, collector identity auditing, atomic conditional record creation, and optional atomic completion.
   - Online Dakshina workflow via Razorpay: server-controlled order creation `POST /api/v1/bookings/:id/dakshina/create-order` (reusing existing pending orders idempotently) and cryptographic signature verification `POST /api/v1/bookings/:id/dakshina/verify` using `crypto.timingSafeEqual` and `RAZORPAY_KEY_SECRET`.
   - Authoritative booking closure gate: `bookings.service.ts` rejects transitioning booking to `COMPLETED` unless a paid Dakshina record exists (raising HTTP 400 `DAKSHINA_NOT_COLLECTED`).
   - Authorization: Strict enforcement that only the assigned, approved Pandit (`isVerified === true` and `verificationStatus === 'APPROVED'`) can collect Dakshina; unassigned Pandits, wrong Pandits, and Yajmans are rejected (HTTP 403).
   - Sanitized Socket.IO `dakshina:collected` and `booking:status-change` event delivery emitted strictly after PostgreSQL transaction commits.
   - Flutter `PanditDashboardScreen` integration: Dedicated Dakshina Collection panel replacing fake completion buttons, supporting Cash vs Online toggle, double-tap lockout (`_isCollectingDakshina`), loading indicators, Razorpay listener lifecycle management (`_dakshinaRazorpay.clear()` in `dispose`), and state restoration on app launch/reconnect.
   - Full automated test coverage: 16 Vitest backend tests (157/157 passing), 10 Flutter unit/widget tests (77/77 passing), `npm run typecheck` clean (0 errors), and `flutter analyze` clean (0 issues).

