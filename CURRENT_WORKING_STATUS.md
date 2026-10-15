# SARV MANGAL (Pandit Setu) — Current Working Status Report

**Audit Mode:** READ-ONLY AUDIT  
**Audit Timestamp:** 2026-10-15  
**Codebase:** Node.js (ESM) + TypeScript + Express + PostgreSQL (PostGIS) + Drizzle ORM + Redis + Socket.IO + Razorpay + Flutter (Dart)  
**Live Database:** Neon PostgreSQL (Migrations 0000–0011 applied)

---

## 1. Automated Verification Command Outputs

### 1.1 Backend TypeScript Type-Check
```bash
$ npm run typecheck
> poojapaath-backend@0.1.0 typecheck
> tsc --noEmit
Exit Code: 0 (0 errors)
```

### 1.2 Backend Vitest Test Suite
```bash
$ npm run test
> poojapaath-backend@0.1.0 test
> vitest run

Test Files: 17 passed (17)
Tests:      175 passed (175)
Duration:   20.15s
Exit Code:  0
```
*Note: Non-fatal test logs show expected fallback logging for unconfigured Firebase Admin and Google Places API mocks.*

### 1.3 Flutter Static Analyzer
```bash
$ flutter analyze
Analyzing pandit_ssetu...
No issues found! (ran in 3.1s)
Exit Code: 0
```

### 1.4 Flutter Unit & Widget Test Suite
```bash
$ flutter test
00:24 +82: All tests passed!
Exit Code: 0 (82 tests passing across 11 test files, 100% pass rate)
```

---

## 2. Module-by-Module Working Status

| # | Module | Classification | Verified Reality & Findings |
| :--- | :--- | :--- | :--- |
| **1** | **Authentication** | **PARTIALLY WORKING** | Phone normalization, Redis-backed OTP storage (`otp:<phone>`) with in-memory Map fallback, and JWT creation (`signToken`) are fully working. However, SMS delivery is a console logger mock (`sms.service.ts`), and `mockOtp` is returned in non-production responses. |
| **2** | **User Profiles** | **WORKING** | `GET`, `PUT`, `PATCH /api/v1/users/profile` and `/users/me` are connected to PostgreSQL. Devotee profile viewing and editing in `ProfileScreen` and `UserProfileDetailScreen` persist to the database. |
| **3** | **Pandit Onboarding & KYC** | **WORKING** | 5-stage lifecycle (`STAGE_1_PHONE_VERIFIED` to `APPROVED`), magic-byte document validation (PDF, PNG, JPEG), isolated local storage (`storage/documents/<panditId>/`), reviewer verify/approval endpoints, and `requireApprovedPandit` route guards are fully operational and verified by 12 backend tests. |
| **4** | **Pooja Catalog** | **WORKING** | 26 real poojas and 156 samagri items imported from Excel into PostgreSQL. `GET /api/v1/poojas` returns paginated, category-filtered rituals. Flutter `BookScreen` fetches live UUIDs and displays the catalog with pull-to-refresh. |
| **5** | **Booking Creation** | **WORKING** | `POST /api/v1/bookings` validates schema, calculates pricing, saves to PostgreSQL `bookings` table, and triggers background dispatch. |
| **6** | **Request Dispatch Engine** | **WORKING** | `dispatchBooking()` queries candidates via Redis GEO (`pandits:live`) and PostGIS `geometryPoint`, excludes busy/declined pandits, and emits private `booking:new-request` Socket.IO events with 60s countdown. |
| **7** | **Accept / Decline Workflow** | **WORKING** | `POST /accept-booking` uses atomic PostgreSQL conditional row-level locking (`status = 'PENDING' AND pandit_id IS NULL RETURNING *`), ensuring a single winner under race conditions. `POST /decline-booking` persists reasons in `booking_declines` table (Migration `0009`). Flutter modal handles 60s ring, double-tap lockout, and decline reason selection. |
| **8** | **Booking Lifecycle State Machine** | **WORKING** | Strict server-side state machine (`CONFIRMED → HEADING_TO_VENUE → ARRIVED → PUJA_STARTED → COMPLETED`). Enforces caller identity (approved assigned Pandit), prevents invalid jumps, and emits sanitized `booking:status-change` Socket.IO events post-commit. |
| **9** | **Dakshina Collection & Closure** | **WORKING** | Explicitly modeled in `dakshina_collections` (Migration `0011`). Supports Cash (server bounds validation) and Online Razorpay order creation and HMAC-SHA256 signature verification. Hardens `updateBookingStatus` so that marking a booking `COMPLETED` requires a confirmed paid Dakshina record (`DAKSHINA_NOT_COLLECTED` rejection if missing). |
| **10** | **GPS & Location** | **PARTIALLY WORKING** | Pandit duty toggle captures GPS via `geolocator` and writes to PostGIS and Redis GEO. But en-route background GPS telemetry is not running, Flutter devotee tracking UI uses a custom canvas painter rather than an active map widget, and `getNearbyPandits` defaults to hardcoded New Delhi coordinates. |
| **11** | **Product Store Catalog** | **WORKING** | 1,267 products imported from Excel into PostgreSQL `products` table. Backend `GET /api/v1/products` supports search, category filters, and pagination. Flutter `ShopScreen` connects to the API and renders items with debounced server-side search and infinite scrolling pagination. |
| **12** | **Shopping Cart** | **WORKING** | `CartService` implemented as a reactive, singleton ChangeNotifier backed by `SharedPreferences`. Manages items, quantity bounds (1-99), line totals, provisional subtotal, and delivery charge calculations (free if >= ₹500, else ₹50). Dedicated `CartScreen` displays items, quantity steppers, and order summary. |
| **13** | **Store Checkout** | **WORKING** | Dedicated `CheckoutScreen` with full shipping address form validation (name, phone, address, city, state, pincode), order summary review, backend order initiation, Razorpay checkout launch, and backend signature verification. Cart is safely cleared only upon server-verified `PAID` confirmation. |
| **14** | **Product Orders** | **WORKING** | PostgreSQL schema with `product_orders` and `product_order_items` tables (Migration `0012`). Authenticated endpoints: `POST /api/v1/product-orders` (database transaction, authoritative price lookup, inactive item rejection), `GET /api/v1/product-orders` (paginated customer orders), and `GET /api/v1/product-orders/:id` (ownership-protected details). |
| **15** | **Razorpay Payment Integration** | **WORKING** | Server order creation and cryptographic signature verification work in test mode for initial booking payments, online Dakshina, and merchandise product orders (`/product-orders/:id/payment` and `/verify-payment`). Backend webhook handler in `payments.service.ts` processes `bookings`, `productOrders`, and `dakshinaCollections` asynchronously on `order.paid` and `payment.captured`. |
| **16** | **Handmade Kundli** | **NOT IMPLEMENTED** | Flutter modal uses a 900ms `Future.delayed` timer to transition to a fake confirmation screen with a hardcoded allotted Pandit ("Pt. Rameshwar Sharma Shastri"). Zero backend tables or endpoints exist. |
| **17** | **AI Spiritual Chat** | **NOT IMPLEMENTED** | Flutter chat modal uses client-side Dart `if/else` keyword substring matching. There is no backend AI proxy, rate limiter, or LLM API integration. |
| **18** | **Astrology Consultations** | **NOT IMPLEMENTED** | Flutter modal is 100% visual simulation without making any network calls. Zero backend tables or endpoints exist. |
| **19** | **Phool Mala Subscriptions** | **PARTIALLY WORKING** | Backend has `subscriptions` table and Razorpay subscription endpoints. Flutter `PhoolMalaScreen` shows a local alert dialog without calling the backend. |
| **20** | **Video Puja Calling** | **BLOCKED** | Backend token generator exists (`agora.service.ts`), but Agora credentials are unconfigured, and Flutter `pubspec.yaml` lacks `agora_rtc_engine`. |
| **21** | **Push Notifications (FCM)** | **BLOCKED** | Backend notification service catches uninitialized Firebase and skips delivery. Flutter `pubspec.yaml` lacks `firebase_messaging` and `firebase_core`. |
| **22** | **Admin Portal** | **PARTIALLY WORKING** | Backend exposes `/admin/health` and KYC verification endpoints with `requireRole(['ADMIN'])`. However, no web portal or Flutter Admin interface exists. |

---

## 3. Discovered Mock APIs, Hardcoded Data & Disconnects

1. **SMS Gateway:** `sendSmsOtp` in `src/services/sms.service.ts` only logs to Pino logger; no SMS provider (Twilio, MSG91, Fast2SMS) is configured.
2. **Store Cart Button [RESOLVED - Stage 3]:** Connected to reactive, persistent `CartService` and navigates to functional `CartScreen`.
3. **Store Pagination Disconnect [RESOLVED - Stage 3]:** `ShopScreen` now performs debounced server-side search and infinite scroll pagination querying all 1,267 products.
4. **Handmade Kundli Mock Timer:** `HandmadeKundliOrderModal` uses `await Future.delayed(Duration(milliseconds: 900))` to fake order placement and displays a hardcoded allotted Pandit.
5. **Consultation Flow Simulation:** `ConsultationFlowModal` executes no HTTP calls and displays simulated Google Meet links.
6. **Nearest Temple Disconnect:** `HomeScreen` shows a "Coming Soon" popup for temples, while `NearestTempleScreen` displays hardcoded static Ujjain cards instead of querying `GET /api/v1/temples/nearby`.
7. **Nearby Pandits Default Coordinates:** `ApiService.getNearbyPandits` defaults to New Delhi (`28.6139, 77.2090`), and `pooja_booking_flow_screen.dart` calls it without device coordinates.
8. **Devotee Live GPS Tracking UI:** `LivePoojaTrackingScreen` renders a stylized `CustomPainter` canvas on `GridPaper` rather than a Google Maps or Mapbox map widget.

---

## 4. External Configuration Blockers

1. **SMS Gateway Credentials:** Requires API key and sender ID for Twilio, MSG91, or Fast2SMS.
2. **Firebase Admin & FCM Client:** Requires `FIREBASE_SERVICE_ACCOUNT_BASE64` or `FIREBASE_SERVICE_ACCOUNT_PATH` on backend, plus Flutter dependencies `firebase_core` and `firebase_messaging`.
3. **Agora Video Calling:** Requires `AGORA_APP_ID` and `AGORA_APP_CERTIFICATE` in `.env`, plus Flutter dependency `agora_rtc_engine`.
4. **Google Places API Key:** `GOOGLE_PLACES_API_KEY` is needed for live temple searches outside the cached mock results.
5. **Production Razorpay Credentials:** Live `RAZORPAY_KEY_ID` and `RAZORPAY_KEY_SECRET` must replace test keys for real payments.

---

## 5. Five Most Important Remaining Tasks

1. **Live SMS Gateway Integration (Priority: High)**
   - Replace console logger in `sms.service.ts` with a real SMS provider integration, and ensure `mockOtp` is completely disabled in production mode.
2. **Devotee Dynamic Location & En-Route GPS Telemetry (Priority: High)**
   - Pass genuine device GPS coordinates from Flutter to `getNearbyPandits()`.
   - Implement background location pinging from the Pandit app during `HEADING_TO_VENUE`, and embed a live map widget in `LivePoojaTrackingScreen`.
3. **Firebase Push Notifications (FCM) Integration (Priority: Medium)**
   - Provide Firebase service account credentials on backend and integrate `firebase_messaging` in Flutter to deliver background dispatch alerts to Pandits.
4. **Phool Mala Subscriptions End-to-End Wiring (Priority: Medium)**
   - Wire Flutter `PhoolMalaScreen` to existing backend subscription endpoints.
5. **Admin Portal UI (Priority: Low)**
   - Build a web portal or administrative app view for KYC approvals and store catalog management.
