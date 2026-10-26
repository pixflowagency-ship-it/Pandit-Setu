# SARV MANGAL — Complete API and Integration Inventory

**Official Brand:** SARV MANGAL  
**Repository:** https://github.com/pixflowagency-ship-it/Pandit-Setu  
**Audit Date:** 2026-10-20  
**Phase:** P7 Architecture & Separation  

---

## 1. Authentication & System Probes

| HTTP Method | Route | Auth / Role | Description | Rate Limit | Request Body / Query | Success Response | Error Codes |
|---|---|---|---|---|---|---|---|
| `GET` | `/` | Public | Brand Welcome Endpoint | Standard | None | Brand metadata, version | None |
| `GET` | `/health` | Public | Backward-compatible health check | Standard | None | `{ success: true, status: "UP" }`| None |
| `GET` | `/health/live` | Public | Liveness probe (Node.js event loop) | Standard | None | `{ status: "ok", uptimeSeconds }`| None |
| `GET` | `/health/ready` | Public | Deep readiness probe (DB, Redis, Providers) | Standard | None | `{ status: "ok"|"degraded", checks }`| 503 if DB down |
| `POST`| `/api/v1/auth/send-otp` | Public | Generate phone OTP & initiate SMS | 5 req / 10m | `{ phone: string }` | `{ success: true, data: { expiresInSeconds, mockOtp? } }` | 400 VALIDATION_ERROR |
| `POST`| `/api/v1/auth/verify-otp`| Public | Verify 6-digit OTP, issue JWT session | 10 req / 10m | `{ phone: string, otp: string, role?: string, name?: string }` | `{ success: true, data: { token, user, isPandit } }` | 401 INVALID_OTP |
| `POST`| `/api/v1/admin/auth/login` | Public | Dedicated Admin email & password login | 5 req / 15m | `{ email: string, password: string }` | `{ success: true, data: { token, admin } }` | 401 INVALID_CREDENTIALS |
| `GET` | `/api/v1/admin/auth/me` | `ADMIN` | Retrieve current authenticated admin profile | Standard | None | `{ success: true, data: { admin } }` | 401 UNAUTHORIZED |

---

## 2. Devotee & Catalog Endpoints

| HTTP Method | Route | Auth / Role | Description | Request Body / Query | Success Response |
|---|---|---|---|---|---|
| `GET` | `/api/v1/users/profile` | Authenticated | Retrieve devotee profile | None | `{ user: { id, phone, name, email, gotra, dob, ... } }` |
| `PATCH` | `/api/v1/users/profile` | Authenticated | Update devotee profile | `{ name, gotra, dob, tob, pob, city, email }` | `{ user: UpdatedUser }` |
| `GET` | `/api/v1/poojas` | Public | List 26 Pooja master rituals | `?category=ghar_jeevan` | `{ poojas: Pooja[] }` |
| `GET` | `/api/v1/poojas/:id` | Public | Retrieve single Pooja with samagri kit | None | `{ pooja: PoojaDetail, samagri: SamagriItem[] }` |
| `GET` | `/api/v1/products` | Public | List 1,267 store items with search & filter | `?category=...&search=...&limit=50` | `{ products: Product[], total }` |
| `GET` | `/api/v1/products/:id`| Public | Retrieve single store product details | None | `{ product: ProductDetail }` |
| `GET` | `/api/v1/temples/nearby`| Public | Retrieve nearby temples using Geohash cache | `?lat=28.5355&lng=77.3910` | `{ temples: Temple[] }` |

---

## 3. Pooja Bookings, Dispatch & Tracking

| HTTP Method | Route | Auth / Role | Description | Request Body / Query | Success Response |
|---|---|---|---|---|---|
| `POST`| `/api/v1/bookings` | `YAJMAN` | Create new Pooja booking | `{ poojaId, bookingDate, timeSlot, address, includesSamagri, sankalpa }` | `{ booking: CreatedBooking }` |
| `GET` | `/api/v1/bookings` | `YAJMAN` | List devotee's active and completed bookings | `?status=CONFIRMED` | `{ bookings: Booking[] }` |
| `GET` | `/api/v1/bookings/:id` | Authenticated | Retrieve booking details | None | `{ booking: BookingDetail }` |
| `PATCH`| `/api/v1/bookings/:id/cancel` | `YAJMAN` | Cancel pending/confirmed booking | `{ reason: string }` | `{ booking: CancelledBooking }` |
| `GET` | `/api/v1/tracking/:bookingId` | Authenticated | Devotee live tracking coordinate retrieval | None | `{ tracking: { status, lat, lng, lastUpdatedAt, isLive } }` |

---

## 4. Pandit Workflow & Telemetry Endpoints

| HTTP Method | Route | Auth / Role | Description | Request Body / Query | Success Response |
|---|---|---|---|---|---|
| `POST`| `/api/v1/pandits/apply` | Authenticated | Submit Pandit Vedic onboarding application | `{ vedicSpecialization, experienceYears, city, poojaCategories }` | `{ pandit: PanditProfile }` |
| `POST`| `/api/v1/pandits/upload-doc` | Authenticated | Upload KYC verification document (Aadhaar/PAN/Degree) | Multipart Form Data (`file`, `docType`) | `{ document: SavedDocument }` |
| `PATCH`| `/api/v1/pandits/duty-status`| `PANDIT` | Toggle online/offline duty with Geo registration | `{ isOnline: boolean, lat?: number, lng?: number }` | `{ pandit: { isOnline, status } }` |
| `POST`| `/api/v1/pandits/me/telemetry` | `PANDIT` | Ingest continuous GPS coordinates (3-10s) | `{ lat: number, lng: number, accuracy: number, speed?, heading? }` | `{ status: "ok" }` |
| `POST`| `/api/v1/pandits/accept-booking` | `PANDIT` | Accept incoming dispatched pooja booking | `{ bookingId: string }` | `{ booking: AcceptedBooking }` |
| `POST`| `/api/v1/pandits/decline-booking`| `PANDIT` | Decline booking with reason, trigger re-dispatch | `{ bookingId: string, reason: string }` | `{ status: "ok" }` |
| `POST`| `/api/v1/bookings/:id/dakshina/cash` | `PANDIT` | Record cash Dakshina collection & complete pooja | `{ cashAmount: number }` | `{ collection: DakshinaRecord, booking: CompletedBooking }` |

---

## 5. Consultations, Kundli & Store Orders

| HTTP Method | Route | Auth / Role | Description | Request Body / Query | Success Response |
|---|---|---|---|---|---|
| `POST`| `/api/v1/consultations` | `YAJMAN` | Create Vedic Jyotish consultation request | `{ consultationType, timingPreference, mediumPreference, devoteeNotes }` | `{ consultation: CreatedConsultation }` |
| `GET` | `/api/v1/consultations` | `YAJMAN` | List devotee's consultation requests | None | `{ consultations: Consultation[] }` |
| `POST`| `/api/v1/kundli-orders` | `YAJMAN` | Create handmade Kundali order with birth data | `{ packageType, birthDate, birthTime, birthPlace, gotra, address }` | `{ order: CreatedKundliOrder }` |
| `GET` | `/api/v1/kundli-orders` | `YAJMAN` | List devotee's handmade Kundli orders | None | `{ orders: KundliOrder[] }` |
| `POST`| `/api/v1/product-orders` | `YAJMAN` | Checkout store cart items with server-side validation | `{ items: [{ productId, quantity }], shippingAddress }` | `{ order: CreatedProductOrder }` |
| `POST`| `/api/v1/subscriptions` | `YAJMAN` | Subscribe to Phool & Mala daily offering plan | `{ planId: string, deliveryAddress: string }` | `{ subscription: CreatedSubscription }` |

---

## 6. Payments & Webhooks

| HTTP Method | Route | Auth / Role | Description | Request Body / Headers | Success Response |
|---|---|---|---|---|---|
| `POST`| `/api/v1/payments/create-order` | Authenticated | Create Razorpay order with server-calculated price | `{ bookingId: string }` | `{ order: { id, amount, currency } }` |
| `POST`| `/api/v1/payments/verify-signature` | Authenticated | Constant-time HMAC SHA256 payment verification | `{ orderId, paymentId, signature }` | `{ booking: ConfirmedBooking }` |
| `POST`| `/api/v1/payments/webhook` | Public | Raw buffer Razorpay webhook ingestion | Raw JSON Buffer + Header `x-razorpay-signature` | `{ status: "ok" }` |

---

## 7. Admin Desk & Operations Management

| HTTP Method | Route | Auth / Role | Description | Request Body / Query | Success Response |
|---|---|---|---|---|---|
| `GET` | `/api/v1/admin/health` | `ADMIN` | Admin sub-router health probe | None | `{ status: "ok" }` |
| `GET` | `/api/v1/admin/stats` | `ADMIN` | High-level operational metrics | None | `{ revenue, activePandits, pendingKyc, ... }` |
| `GET` | `/api/v1/admin/pandits` | `ADMIN` | Application queue with document masking | `?status=PENDING` | `{ pandits: AdminPanditApplication[] }` |
| `GET` | `/api/v1/admin/pandits/:panditId` | `ADMIN` | Detailed Pandit profile and unmasked documents | None | `{ pandit: FullPanditDetail }` |
| `PATCH`| `/api/v1/admin/pandits/:panditId/approval` | `ADMIN` | Approve or reject Pandit with mandatory reason | `{ decision: "APPROVE"|"REJECT", rejectionReason? }` | `{ pandit: UpdatedPandit }` |
| `PATCH`| `/api/v1/admin/documents/:documentId/verify` | `ADMIN` | Verify specific KYC document | `{ isVerified: boolean }` | `{ document: UpdatedDocument }` |
| `GET` | `/api/v1/admin/documents/:documentId/download` | `ADMIN` | Stream secure document file buffer | None | Binary file stream |
| `GET` | `/api/v1/admin/subscriptions` | `ADMIN` | List customer recurring subscriptions | `?status=ACTIVE` | `{ subscriptions: AdminSubscription[] }` |
| `GET` | `/api/v1/admin/consultations` | `ADMIN` | List consultation desk queue | `?status=PENDING` | `{ consultations: Consultation[] }` |
| `PATCH`| `/api/v1/admin/consultations/:id/schedule` | `ADMIN` | Schedule consultation call timing | `{ scheduledStartTime, scheduledEndTime }` | `{ consultation: ScheduledConsultation }` |
| `PATCH`| `/api/v1/admin/consultations/:id/assignment` | `ADMIN` | Assign Vedic Acharya to consultation | `{ panditId: string }` | `{ consultation: AssignedConsultation }` |
| `PATCH`| `/api/v1/admin/consultations/:id/status` | `ADMIN` | Update consultation state machine status | `{ status: string }` | `{ consultation: UpdatedConsultation }` |
| `GET` | `/api/v1/admin/kundli-orders` | `ADMIN` | List Kundli orders fulfilment queue | `?status=PENDING` | `{ orders: KundliOrder[] }` |
| `PATCH`| `/api/v1/admin/kundli-orders/:id/decision` | `ADMIN` | Accept or reject Kundli order | `{ decision: "ACCEPT"|"REJECT", rejectionReason? }` | `{ order: UpdatedOrder }` |
| `PATCH`| `/api/v1/admin/kundli-orders/:id/assignment` | `ADMIN` | Assign Astrologer to write Kundli | `{ panditId: string }` | `{ order: AssignedOrder }` |
| `PATCH`| `/api/v1/admin/kundli-orders/:id/status` | `ADMIN` | Update status (PREPARING, DISPATCHED, DELIVERED) | `{ status: string, trackingNumber?: string }` | `{ order: DispatchedOrder }` |
