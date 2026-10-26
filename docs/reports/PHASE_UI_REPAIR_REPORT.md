# SARV MANGAL (सर्व मंगल) — Master UI Repair & Functionality Fix Report

**Date:** October 22, 2026  
**Status:** COMPLETE (All Tests Verified)  
**Target Applications:**
- Mobile App: Flutter (`frontend/pandit_ssetu/`)
- Backend: Node.js + Express + TypeScript (`src/`)
- Database: PostgreSQL + Drizzle ORM (`drizzle/`)
- Admin Portal: Vite + TypeScript (`admin-portal/`)

---

## Executive Summary

A comprehensive, source-driven repair across the entire SARV MANGAL platform was executed to resolve UI inconsistencies, responsive layout defects, Kundli type and concern selection flows, subscription card viewport fitting, Yajman profile address persistence, and Pooja booking flow resilience.

All changes were implemented cleanly within the existing codebase architecture without breaking API contracts or changing billing/pricing rules.

---

## 1. Global Design System, Typography & Branding (Part 1)

### Standardized Sans-Serif Typography
- **Status:** `VERIFIED`
- **Root Cause:** Individual screens had disparate styles and fallback ambiguities.
- **Resolution:** Centralized sans-serif font configuration established in [`AppTheme.lightTheme`](file:///C:/Users/krmta/OneDrive/Desktop/pndtbcknd/frontend/pandit_ssetu/lib/theme/app_theme.dart) and [`AppTypography`](file:///C:/Users/krmta/OneDrive/Desktop/pndtbcknd/frontend/pandit_ssetu/lib/theme/app_typography.dart) using `GoogleFonts.lato` with `sansSerifFallback = ['Lato', 'sans-serif']` and `Noto Sans Devanagari` fallback for Hindi and Sanskrit sacred text.
- **Serif Removal:** Unintended serif/Times styles eliminated throughout all text themes.

### Official Brand Displays
- **Status:** `VERIFIED`
- **Standard Lockup:** Standardized Latin script to `SARV MANGAL` and Hindi script to `सर्व मंगल`.
- **Enforcement:** Updated across app bars, home screens, consultation modals, dialogs, and admin portals.

### Logo Outline Fix
- **Status:** `VERIFIED`
- **Root Cause:** In [`home_screen.dart`](file:///C:/Users/krmta/OneDrive/Desktop/pndtbcknd/frontend/pandit_ssetu/lib/screens/home_screen.dart#L377) and [`book_screen.dart`](file:///C:/Users/krmta/OneDrive/Desktop/pndtbcknd/frontend/pandit_ssetu/lib/screens/book_screen.dart#L258), the circular logo artwork was wrapped in an outer `Container` with an additional `border: Border.all(color: Color(0xFFE65100), width: 1.5)` and box shadow, creating an unwanted double outline outside the genuine circular logo artwork.
- **Resolution:** Replaced outer decorated containers with clean `SizedBox(width: 38, height: 38, child: ClipOval(child: Image.asset(...)))` preserving the original artwork's inner design and aspect ratio.

---

## 2. Phool Mala Store: Festive Subscription Card (Part 2)

### Single-Screen Viewport Fit
- **Status:** `VERIFIED`
- **Root Cause:** The Festive Offer Subscription card previously required vertical scrolling or a second screen to view the ₹399/mo pricing and `Subscribe Now` action.
- **Resolution:**
  - Compacted header banner in [`phool_mala_screen.dart`](file:///C:/Users/krmta/OneDrive/Desktop/pndtbcknd/frontend/pandit_ssetu/lib/screens/phool_mala_screen.dart#L357) to 115px height with concise typography.
  - Reduced inter-section spacers to 8px.
  - Compacted card margins (horizontal: 14, vertical: 12) with 4px bullet-item padding and 14px icons.
  - Positioned the ₹399/mo price (21px bold) and `Subscribe Now` button together within the card so they are immediately visible on standard phone viewports (390x844).
  - Wrapped pricing and action rows in `Flexible` and `Expanded` to eliminate `RenderFlex` horizontal overflow on narrow screens down to 320px width.

---

## 3. Handmade Kundli: Kundli Type Selection (Part 3)

### Kundli Type Selector
- **Status:** `VERIFIED`
- **Implementation:** Replaced the static 32-page Janam Patri intro text in [`handmade_kundli_order_modal.dart`](file:///C:/Users/krmta/OneDrive/Desktop/pndtbcknd/frontend/pandit_ssetu/lib/widgets/handmade_kundli_order_modal.dart#L257) with a dedicated `Select Your Kundli Type` selector offering exactly two selectable radio cards:
  1. **Patrika** `(32 Page Kundli)`
  2. **Online Kundli** `(Digital PDF Chart)`
- **Persistence & API:**
  - Updated [`createKundliOrderSchema`](file:///C:/Users/krmta/OneDrive/Desktop/pndtbcknd/src/validators/kundli_orders.validator.ts#L4) to accept optional `kundliType: z.string().max(100)`.
  - Updated [`createKundliOrder()`](file:///C:/Users/krmta/OneDrive/Desktop/pndtbcknd/src/services/kundli_orders.service.ts#L36) to embed `kundliType` into the persisted order notes `[Type: ${kundliType}]`, ensuring 100% backward-compatible persistence and query retrieval.

---

## 4. Kundli: Concern Categories & Validation (Part 4)

### Category Selection Reusing Consultation Categories
- **Status:** `VERIFIED`
- **Implementation:** Replaced free-text-only concern field in [`handmade_kundli_order_modal.dart`](file:///C:/Users/krmta/OneDrive/Desktop/pndtbcknd/frontend/pandit_ssetu/lib/widgets/handmade_kundli_order_modal.dart#L556) with `Select Your Concern` dropdown reusing the consultation categories:
  - `Marriage & Kundli Dosha`
  - `Career, Job & Business Growth`
  - `Health, Family Peace & Prosperity`
  - `Griha Vastu Dosha Remedy`
  - `Child Education & Higher Studies`
  - `Navagraha & Rahu-Ketu Shanti`
  - `Others`
- **Interaction Rules:**
  - Standard categories hide the custom description field.
  - Selecting `Others` reveals the dedicated `Describe Your Specific Concern *` text field.
  - Validation blocks proceeding to Review if `Others` is selected with empty whitespace, displaying a floating error SnackBar.
  - Custom descriptions and category selections survive step navigation and appear in the review summary.

---

## 5. Home Screen: Six Service Cards & Explore Guide Gap (Part 5)

### Spacing Reduction
- **Status:** `VERIFIED`
- **Root Cause:** In [`home_screen.dart`](file:///C:/Users/krmta/OneDrive/Desktop/pndtbcknd/frontend/pandit_ssetu/lib/screens/home_screen.dart#L990), `_buildSixBoxServiceGrid` had default `GridView.builder` padding (16px bottom) and `childAspectRatio: 0.90`, followed by a 16px container spacer, resulting in over 32px of blank vertical gap before `Explore Guide / Life Problems?`.
- **Resolution:** Set `GridView.builder` padding to `EdgeInsets.zero`, `childAspectRatio: 0.98`, `mainAxisSpacing: 8`, and `crossAxisSpacing: 8`, connecting the six service cards naturally to the Explore Guide section with a clean 10px intentional visual gap.

---

## 6. Profile: Yajman Address Update Persistence Bug (Part 6)

### Root Cause & Comprehensive Fix
- **Status:** `VERIFIED`
- **Root Cause Diagnosed:**
  1. The PostgreSQL `users` table and Drizzle schema [`users.ts`](file:///C:/Users/krmta/OneDrive/Desktop/pndtbcknd/src/db/schema/users.ts) contained `city` but lacked an `address` column.
  2. [`updateProfileSchema`](file:///C:/Users/krmta/OneDrive/Desktop/pndtbcknd/src/validators/users.validator.ts#L4) did not permit `address` updates.
  3. In [`profile_screen.dart`](file:///C:/Users/krmta/OneDrive/Desktop/pndtbcknd/frontend/pandit_ssetu/lib/screens/profile_screen.dart), the address edit button was an unlinked placeholder (`onPressed: () {}`), and `_loadUserProfile` was not pulling or syncing address.
  4. When `address` was added to the Drizzle schema, live PostgreSQL queries in `admin-portal` and authentication crashed with `column "address" of relation "users" does not exist`.
- **Full Resolution:**
  - Added `address: text("address")` to Drizzle schema.
  - Executed database migration [`0014_add_users_address.sql`](file:///C:/Users/krmta/OneDrive/Desktop/pndtbcknd/drizzle/0014_add_users_address.sql) ensuring `ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "address" text;`.
  - Added `address` to `updateProfileSchema` and controller handlers (`getProfileHandler`, `updateProfileHandler`).
  - Added `address` property to [`UserData`](file:///C:/Users/krmta/OneDrive/Desktop/pndtbcknd/frontend/pandit_ssetu/lib/user_data.dart) with SharedPreferences caching.
  - Connected `_showEditAddressDialog` and `_saveAddress` in `ProfileScreen` with genuine API calls to `ApiService.updateProfile()`.
  - Verified admin login query `where email = 'makemybit2026@gmail.com'` succeeds without error.

---

## 7. Pooja Booking Persistence & Pay Later Workflow (Part 7)

### Reliable Booking Creation
- **Status:** `VERIFIED`
- **Root Cause Diagnosed:**
  1. In [`pooja_booking_flow_screen.dart`](file:///C:/Users/krmta/OneDrive/Desktop/pndtbcknd/frontend/pandit_ssetu/lib/screens/pooja_booking_flow_screen.dart), selecting `pay_later` (Pay After Pooja) was unconditionally attempting to generate a Razorpay payment order, failing with a SnackBar and leading users to believe the booking was never created.
  2. In [`home_screen.dart`](file:///C:/Users/krmta/OneDrive/Desktop/pndtbcknd/frontend/pandit_ssetu/lib/screens/home_screen.dart#L2257), `_buildUpcomingBookingBanner` read `b['poojaTitle']` instead of `b['pooja']?['title']`, falling back to static strings even when bookings existed.
- **Resolution:**
  - Updated `_executeBookingSubmission()`: When `_selectedPaymentMethod == 'pay_later'`, persists the booking to the backend via `ApiService.createBooking()`, then immediately displays confirmation informing the user that their booking is confirmed and Dakshina can be given directly to the Pandit after the ritual.
  - For online payments, if payment gateway integration fails in dev/sandbox, gracefully preserves the persisted booking in database and routes user to My Bookings.
  - Corrected booking title and Pandit name extraction in `home_screen.dart`.

---

## 8. Verification Results

| Check Suite | Command | Result | Details |
|---|---|---|---|
| Flutter Analyzer | `flutter analyze` | **PASSED** | 0 errors, 0 warnings, 0 issues found |
| Flutter Test Suite | `flutter test` | **PASSED** | 115 / 115 tests passed |
| Master UI Tests | `flutter test test/master_ui_repair_and_persistence_test.dart` | **PASSED** | 4 / 4 tests passed |
| Backend Typecheck | `npm run typecheck` | **PASSED** | 0 TypeScript errors |
| Backend Vitest | `npm test` | **PASSED** | 25 / 25 test files passed (290 / 290 tests) |
| Admin Portal Build | `npm run build` | **PASSED** | Production bundle built cleanly |
| Live Query Check | Drizzle ORM `users.findFirst` | **PASSED** | `makemybit2026@gmail.com` query succeeded |

---

## 9. Modified Files Summary

### Mobile Frontend (`frontend/pandit_ssetu/`)
- `lib/theme/app_theme.dart` — Centralized sans-serif typography.
- `lib/theme/app_typography.dart` — Standardized typography tokens & Devanagari fallbacks.
- `lib/screens/home_screen.dart` — Clean circular logo (no outer orange border), tightened 6-box service grid gap.
- `lib/screens/book_screen.dart` — Clean circular logo.
- `lib/screens/phool_mala_screen.dart` — Single-screen festive subscription card layout & overflow fixes.
- `lib/screens/profile_screen.dart` — Address editing dialog & live backend persistence.
- `lib/screens/pooja_booking_flow_screen.dart` — Resilient `pay_later` and booking persistence flow.
- `lib/user_data.dart` — Added address persistence & SharedPreferences sync.
- `lib/widgets/handmade_kundli_order_modal.dart` — Kundli Type selector (`Patrika` vs `Online Kundli`), Concern categories dropdown, custom concern validation.
- `test/master_ui_repair_and_persistence_test.dart` — Comprehensive regression test suite.

### Backend & Database (`src/` & `drizzle/`)
- `src/db/schema/users.ts` — Added `address: text("address")` column.
- `drizzle/0014_add_users_address.sql` — Migration script for PostgreSQL `users` table.
- `src/validators/users.validator.ts` — Allowed `address` in `updateProfileSchema`.
- `src/controllers/users.controller.ts` — Persisted and returned `address` in profile endpoints.
- `src/validators/kundli_orders.validator.ts` — Allowed `kundliType` and `concernCategory`.
- `src/services/kundli_orders.service.ts` — Handled `kundliType` and `concernCategory` in order notes.
