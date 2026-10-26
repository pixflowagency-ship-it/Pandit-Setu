# SARV MANGAL — Complete Feature Inventory

**Official Brand:** SARV MANGAL  
**Repository:** https://github.com/pixflowagency-ship-it/Pandit-Setu  
**Audit Date:** 2026-10-20  
**Phase:** P7 Architecture & Separation  

---

## 1. Executive Summary

This inventory documents all functional modules, screens, capabilities, persistence models, and external integrations discovered across the SARV MANGAL codebase (Backend, Flutter Mobile Application, and Admin System).

| Module Count | Discovered Screens / Views | Backend Endpoints | DB Tables | External Integrations |
|---|---|---|---|---|
| **14 Modules** | 24 Screens + 8 Modals | 48 API Endpoints | 22 Tables | 5 Providers (Razorpay, Fast2SMS, Firebase, Google Places, Agora) |

---

## 2. Comprehensive Feature Matrix

| Feature ID | Module | Feature Name | Description | Client Interface | Backend Route | Data Persistence | Integration | Status |
|---|---|---|---|---|---|---|---|---|
| **AUTH-01** | Auth | Devotee Mobile Login | 10-digit Indian mobile number validation, send OTP | `yajman_login_screen.dart` | `POST /api/v1/auth/send-otp` | `users` table | Fast2SMS (Dev Mock) | **WORKING** |
| **AUTH-02** | Auth | Devotee OTP Verification | 6-digit OTP verification, user session issuance | `yajman_otp_screen.dart` | `POST /api/v1/auth/verify-otp` | Redis (TTL 300s), `users` | Node crypto | **WORKING** |
| **AUTH-03** | Auth | Dual-Portal Resolution | Resolves Yajman vs Pandit portal context on same phone | `auth.service.ts` | `POST /api/v1/auth/verify-otp` | `users`, `pandits` | JWT Service | **WORKING** |
| **AUTH-04** | Auth | User Profile Management | View and update devotee profile details (Gotra, DOB, City) | `user_profile_detail_screen.dart` | `GET/PATCH /api/v1/users/profile` | `users` table | None | **WORKING** |
| **AUTH-05** | Auth | Secure Admin Authentication | Email & Password login for dedicated Admin Portal | `admin-portal/src/Login.tsx` | `POST /api/v1/admin/auth/login` | `users` (`password_hash`) | Scrypt & Salt | **WORKING** |
| **AUTH-06** | Auth | Admin Session Verification | JWT verification and profile retrieval for admin desk | `admin-portal/src/App.tsx` | `GET /api/v1/admin/auth/me` | Signed JWT | Bearer Auth | **WORKING** |
| **HOME-01** | Home | Service 6-Box Grid | 6 primary Vedic service tiles with routing | `home_screen.dart` | None (Client Router) | Local State | None | **WORKING** |
| **HOME-02** | Home | Sacred Mantra Hero Banner | Auspicious Rigvedic & Gayatri mantra banners | `home_screen.dart` | None | Local Asset | None | **WORKING** |
| **CAT-01** | Catalog | 26 Pooja Master Catalog | Category filtering (Ghar, Shanti, Sanskar, Path) | `book_screen.dart` | `GET /api/v1/poojas` | `poojas` table (26 rows) | None | **WORKING** |
| **CAT-02** | Catalog | 156 Samagri Kit Inclusions | Custom samagri kit breakdown with toggle option | `pooja_booking_flow_screen.dart` | `GET /api/v1/poojas/:id` | `samagri_items` | None | **WORKING** |
| **CAT-03** | Catalog | Store Products Catalog | 1,267 seeded spiritual products with category filter | `shop_screen.dart` | `GET /api/v1/products` | `products` (1,267 rows) | None | **WORKING** |
| **BOOK-01** | Booking | Pooja Booking Form | 4-step wizard: Date/Time, Sankalpa, Samagri, Payment | `pooja_booking_flow_screen.dart` | `POST /api/v1/bookings` | `bookings` table | None | **WORKING** |
| **BOOK-02** | Booking | Proximity Dispatch Engine | PostGIS KNN distance search + Redis GEO matching | `dispatch.service.ts` | Internal Dispatch | Redis GEO, `pandits` | PostGIS 3.6 | **WORKING** |
| **BOOK-03** | Booking | Pandit Request Dispatch | Real-time 60s request popup modal via Socket.IO | `incoming_pooja_request_modal.dart`| Socket `booking:new-request`| In-Memory Socket | Socket.IO | **WORKING** |
| **BOOK-04** | Booking | Pandit Accept / Decline | Accept booking with concurrency guard; Decline reason | `incoming_pooja_request_modal.dart`| `POST /pandits/accept-booking` | `bookings`, `booking_declines`| Socket.IO | **WORKING** |
| **BOOK-05** | Booking | Devotee Live Tracking | Real-time GPS badge (<5m green vs >=5m amber vs none) | `live_pooja_tracking_screen.dart` | `GET /api/v1/tracking/:bookingId` | Redis, PostGIS | Socket.IO | **WORKING** |
| **TEL-01** | Telemetry| Continuous Pandit Telemetry | Authenticated on-duty Pandit GPS coordinates (3-10s) | `pandit_dashboard_screen.dart` | `POST /api/v1/pandits/me/telemetry` | Redis GEO & `pandits` | Socket.IO | **WORKING** |
| **TEL-02** | Telemetry| Dispatch Freshness Guard | Stale Pandits (>10m) excluded from in-person dispatch | `dispatch.service.ts` | Internal Engine | `pandits.lastTelemetryAt`| PostGIS | **WORKING** |
| **KYC-01** | Pandit | Pandit Onboarding Wizard | Vedic qualifications, specialization, experience | `pandit_onboarding_screen.dart` | `POST /api/v1/pandits/apply` | `pandits` table | None | **WORKING** |
| **KYC-02** | Pandit | Secure Document Upload | Aadhaar, PAN, Degree upload with magic-bytes check | `pandit_onboarding_screen.dart` | `POST /api/v1/pandits/upload-doc`| `storage/documents` | Node fs | **WORKING** |
| **KYC-03** | Pandit | Duty Status Toggle | Online/Offline toggle with instant Redis GEO registration | `pandit_dashboard_screen.dart` | `PATCH /api/v1/pandits/duty-status`| `pandits.isOnline`, Redis | Redis GEO | **WORKING** |
| **PAY-01** | Payment | Cash Dakshina Collection | In-person cash collection recording and booking closure | `pandit_dashboard_screen.dart` | `POST /bookings/:id/dakshina/cash`| `dakshina_collections` | None | **WORKING** |
| **PAY-02** | Payment | Razorpay Order Creation | Server-side amount calculation, order generation | `checkout_screen.dart` | `POST /api/v1/payments/create-order`| `bookings`, `product_orders` | Razorpay SDK | **WORKING** |
| **PAY-03** | Payment | Razorpay Signature Verification| Constant-time HMAC SHA256 payment verification | `api_service.dart` | `POST /payments/verify-signature` | `bookings`, `product_orders` | Razorpay SDK | **WORKING** |
| **PAY-04** | Payment | Webhook Raw-Buffer Processing | Raw-buffer signature check, 24h Redis deduplication | Backend Engine | `POST /api/v1/payments/webhook` | Redis (`webhook:processed:`) | Razorpay Webhook | **WORKING** |
| **CONS-01**| Consult | Vedic Consultation Request | Career, Kundli Milan, Health, Vastu consultation | `consultation_flow_modal.dart` | `POST /api/v1/consultations` | `consultations` table | Razorpay SDK | **WORKING** |
| **CONS-02**| Consult | Consultation Lifecycle & Schedule| Admin scheduling with date-time and Pandit assignment | `admin-portal` / Desk | `PATCH /consultations/:id/*` | `consultations` table | Socket.IO | **WORKING** |
| **KUNDLI-01**|Kundli | Handmade Kundli Ordering | Birth details submission (DOB, TOB, POB), Speed Post | `handmade_kundli_order_modal.dart` | `POST /api/v1/kundli-orders` | `kundli_orders` table | Speed Post | **WORKING** |
| **KUNDLI-02**|Kundli | Kundli Order Review & Dispatch| Admin review, Pandit assignment, Speed Post tracking | `admin-portal` / Desk | `PATCH /kundli-orders/:id/*` | `kundli_orders` table | Postal Engine | **WORKING** |
| **STORE-01**| Store | Shopping Cart Management | Add to cart, quantity change, persistent local storage | `cart_screen.dart` | Local State / Products API | Local Storage / Products | None | **WORKING** |
| **STORE-02**| Store | Order Checkout & Totals | Server-validated item prices, shipping fee calculation | `checkout_screen.dart` | `POST /api/v1/product-orders` | `product_orders`, items | Razorpay | **WORKING** |
| **SUB-01** | Subscr | Phool Mala Subscription | Daily floral offering plans (Daily, Bi-Weekly, Festival)| `phool_mala_screen.dart` | `POST /api/v1/subscriptions` | `subscriptions` table | Razorpay Subscr | **WORKING** |
| **TMPL-01** | Temple | Nearby Temple Discovery | Geohash precision-5 cached temple locator | `nearest_temple_screen.dart` | `GET /api/v1/temples/nearby` | Redis Geohash cache | Google Places | **WORKING** (Mock Fallback) |
| **CHAT-01** | Chat | Pandit Ji Guidance Assistant | Local Vedic FAQs, Muhurat guidance, ritual queries | `pandit_chat_modal.dart` | Client-side FAQs | Local Memory | None | **WORKING** |
| **ADM-01** | Admin | Admin Operational Metrics | High-level business stats (revenue, active pandits) | `admin-portal` Overview | `GET /api/v1/admin/stats` | Real DB counts | None | **WORKING** |
| **ADM-02** | Admin | Pandit Verification Queue | Review Pandit KYC applications, document verification | `admin-portal` Pandit KYC | `GET /api/v1/admin/pandits` | `pandits`, `documents` | None | **WORKING** |
| **ADM-03** | Admin | Pandit KYC Approval / Rejection | Approve application or reject with mandatory reason | `admin-portal` Action Modal | `PATCH /admin/pandits/:id/approval`| `pandits` table | None | **WORKING** |
| **ADM-04** | Admin | Document Download & Stream | Secure streaming of verification documents for admins | `admin-portal` Document Viewer| `GET /admin/documents/:id/download`| Filesystem storage | Stream | **WORKING** |
| **ADM-05** | Admin | Subscriptions Oversight | Review customer subscriptions, plan names, period ends | `admin-portal` Subscriptions | `GET /api/v1/admin/subscriptions` | `subscriptions` table | None | **WORKING** |
| **ADM-06** | Admin | Consultation Desk Oversight | Full consultation queue, assign pandit, update status | `admin-portal` Consultations | `GET/PATCH /admin/consultations` | `consultations` table | None | **WORKING** |
| **ADM-07** | Admin | Kundli Orders Fulfilment Desk | Review Kundli orders, assign astrologer, dispatch tracking| `admin-portal` Kundli Desk | `GET/PATCH /admin/kundli-orders` | `kundli_orders` table | Speed Post | **WORKING** |
| **OPS-01** | Ops | Liveness Health Probe | Native Node.js HTTP event loop check | Monitoring / Orchestrator | `GET /health/live` | In-Memory Uptime | Node.js | **WORKING** |
| **OPS-02** | Ops | Readiness Health Probe | Deep dependency check (Postgres, Redis, 5 Providers) | Monitoring / Orchestrator | `GET /health/ready` | DB Ping, Redis Ping | All Providers | **WORKING** |
| **OPS-03** | Ops | Graceful Server Shutdown | Intercepts SIGTERM/SIGINT, closes HTTP, Redis, Pool | Server Runtime | Process Signal Handlers | OS Signal Traps | Node.js | **WORKING** |
