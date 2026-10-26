# SARV MANGAL — Complete User Journeys Specification

**Official Brand:** SARV MANGAL  
**Repository:** https://github.com/pixflowagency-ship-it/Pandit-Setu  
**Audit Date:** 2026-10-20  
**Phase:** P7 Architecture & Separation  

---

## 1. Overview of Primary Personas

1. **Devotee (Yajman):** Seeks authentic Vedic rituals, astrological guidance, sacred store items, daily flower subscriptions, and temple darshan.
2. **Pandit Ji (Vedic Acharya):** Verified Sanskrit scholar and priest performing sacred rituals, managing on-duty status, receiving real-time bookings, and collecting Dakshina.
3. **Operations Administrator (Admin):** Manages Pandit KYC applications, document verification, consultation scheduling, Kundli preparation, and subscription oversight via the dedicated Admin Portal.

---

## 2. Devotee User Journeys

### Journey 1: In-Person Offline Pooja Booking & Live GPS Tracking
1. **Entry & Discovery:** Devotee opens SARV MANGAL app, selects "Offline Pooja" from the home 6-box grid.
2. **Pooja Selection:** Browses categorized Poojas (e.g., Satyanarayan Katha), reviews duration, inclusion of authentic samagri kit, mantra details, and fixed Dakshina. Taps "Book Now".
3. **Step 1 (Date & Slot):** Selects auspicious date and time slot (Morning / Afternoon / Evening); enters home address and city.
4. **Step 2 (Sankalpa Details):** Enters Yajman Full Name, Gotra, Nakshatra, and special spiritual prayer sankalpa.
5. **Step 3 (Samagri Customization):** Chooses whether to include the SARV MANGAL pre-packed authentic 156-item samagri kit or arrange items independently.
6. **Step 4 (Summary & Submission):** Inspects server-calculated price breakdown; selects payment mode (Cash on Completion / Online Razorpay). Taps "Confirm & Book Pooja".
7. **Proximity Dispatch:** Backend runs PostGIS spatial KNN search against online, approved Pandits with fresh GPS telemetry (<10m). Emits Socket.IO request to the nearest Pandit.
8. **Tracking:** Devotee is directed to `LivePoojaTrackingScreen`. Real-time status updates: `CONFIRMED` -> `ALLOTTED` -> `ON_THE_WAY` -> `ARRIVED` -> `IN_PROGRESS` -> `COMPLETED`. Devotee observes green "Live GPS" badge (<5m freshness) or amber "Last Known Location" badge.

### Journey 2: Vedic Jyotish Consultation Booking
1. **Entry:** Devotee taps "Vedic Jyotish Consultation" tile on Home screen.
2. **Modal Configuration:** Selects consultation domain (Career & Wealth, Kundli Milan, Health & Longevity, Vastu Shastra); chooses timing slot and medium (Video Call or Audio Call).
3. **Submission:** Taps "Confirm Consultation". Backend persists consultation with a unique reference number (e.g. `CNS-20261020-XXXXXX`) in `PENDING` status.
4. **Transparent Desk Notice:** Devotee receives immediate on-screen helpline card and SMS confirmation with assigned reference; consultation desk schedules Acharya and confirms call link.

### Journey 3: Handmade Kundali Ordering & Speed Post Fulfilment
1. **Entry:** Devotee taps "Handmade Kundali" tile on Home screen.
2. **Birth Data Entry:** Submits Date of Birth, exact Time of Birth (with AM/PM), Place of Birth (City/State), and Gotra.
3. **Package & Shipping:** Selects Astrological Edition (Varshphal, Brihat Kundli, Sampoorna Patrika), script language (Hindi / Sanskrit / English), and physical delivery address with PIN code.
4. **Order Creation:** Backend creates order in `kundli_orders` table with unique reference (e.g. `KND-20261020-XXXXXX`).
5. **Fulfilment:** Dedicated Admin Desk reviews birth charts, assigns Vedic Astrologer, prints handwritten patrika, and dispatches via India Post Speed Post with live tracking ID.

### Journey 4: Pooja Samagri Store Browsing, Cart, and Checkout
1. **Catalog Exploration:** Devotee navigates to "Store" tab via bottom navigation bar. Filters across 1,267 seeded spiritual products (Diyas, Incense, Havan herbs, Yantras, Rudraksha).
2. **Cart Management:** Taps "Add to Sacred Cart". Floating cart badge increments. Navigates to `CartScreen` to adjust quantities; subtotal and shipping fees update dynamically.
3. **Server-Side Validation:** Taps "Proceed to Checkout". Enters shipping address. Backend validates item prices server-side, preventing client price tampering.
4. **Payment & Confirmation:** Devotee completes payment; order transitions to `PROCESSING`.

---

## 3. Pandit Ji (Vedic Acharya) Journeys

### Journey 5: Pandit Onboarding & Document Verification
1. **Role Context:** Pandit opens app, selects "Continue as Pandit Ji", verifies phone via OTP.
2. **Profile Submission:** Completes 4-step wizard: Sanskrit qualification (Shastri / Acharya), years of experience, specialization (Karmakand, Jyotish, Vastu).
3. **Document Upload:** Uploads government identification (Aadhaar, PAN) and Shastri certificate. File validation ensures magic bytes correspond to JPEG/PNG/PDF.
4. **Pending State:** Application enters `PENDING` state (Stage 3). Pandit dashboard indicates verification in review; Duty switch is safely disabled until admin approval.

### Journey 6: Duty Toggle & Continuous GPS Telemetry Loop
1. **Going Online:** Approved Pandit opens `PanditDashboardScreen`, toggles Duty switch to green "ON".
2. **Geo Registration:** Client checks fine location permission. Updates `pandits.isOnline = true` in PostgreSQL and registers coordinates in Redis GEO `pandits:live`.
3. **Periodic Telemetry:** Background timer executes every 25 seconds while on-duty, sending `{ lat, lng, accuracy, speed, heading }` to `POST /api/v1/pandits/me/telemetry`.
4. **Going Offline:** Pandit toggles Duty off. Telemetry loop is immediately cancelled; coordinates are deregistered from live dispatch.

### Journey 7: Pooja Request Acceptance & Dakshina Collection
1. **Incoming Request Modal:** Pandit handset receives Socket.IO `booking:new-request` notification. Modal pops up with 60-second visual countdown, pooja name, venue address, and dakshina.
2. **Acceptance:** Pandit taps "ACCEPT BOOKING". Backend executes atomic database update, assigning Pandit and changing status to `ALLOTTED`. (If request expired or accepted by another, surfaces clean notice).
3. **Ritual Execution & Dakshina:** Pandit arrives at devotee venue, conducts ritual. Upon completion, taps "Collect Cash Dakshina". Enters cash amount collected; backend creates record in `dakshina_collections` and marks booking `COMPLETED`.

---

## 4. Administrator Journeys (Dedicated Admin Portal)

### Journey 8: Secure Portal Login & Session Handling
1. **URL Entry:** Administrator opens `https://admin.example.com` (dedicated web portal origin).
2. **Authentication:** Enters Admin email and password. Clicks "Secure Admin Login".
3. **Validation:** Backend verifies credentials against `users.password_hash` using constant-time `crypto.scrypt` verification. Issues signed JWT with `role: "ADMIN"`.
4. **Session Management:** Token stored in secure client storage; header displays admin name and environment badge.

### Journey 9: Pandit KYC Review & Approval
1. **Queue Inspection:** Admin clicks "Pandit KYC Queue" tab. Filters by `PENDING`.
2. **Document Audit:** Clicks "View Document" to stream securely stored Aadhaar/certificate images.
3. **Decision:** Clicks "Approve" (activates Pandit) or "Reject" (prompts mandatory reason modal, updating database with rejection justification).

### Journey 10: Kundli Orders Fulfilment & Speed Post Dispatch
1. **Queue:** Admin clicks "Kundli Orders Desk" tab.
2. **Review:** Reviews devotee birth details and package selection.
3. **Assignment:** Clicks "Assign Astrologer" and selects verified Vedic Pandit.
4. **Dispatch:** Once written, clicks "Dispatch", inputs India Post Speed Post tracking number (`POST /api/v1/admin/kundli-orders/:id/status`). Status updates to `DISPATCHED`.
