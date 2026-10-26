# SARV MANGAL — Complete Bug, Incompleteness, and Gap Audit

**Official Brand:** SARV MANGAL  
**Repository:** https://github.com/pixflowagency-ship-it/Pandit-Setu  
**Audit Date:** 2026-10-20  
**Phase:** P7 Architecture & Separation  

---

## 1. Executive Summary

This document consolidates every defect, architectural gap, missing implementation, mocked provider dependency, and security vulnerability discovered and analyzed during the Phase P7 audit.

| Total Tracked Issues | Resolved in Baseline / P7 | Incomplete / Blocked by Credentials | Hardware Blocked |
|---|---|---|---|
| **26 Issues** | 22 Resolved & Verified | 3 Provider Blockers | 1 Physical Android Device Blocker |

---

## 2. Comprehensive Issue Ledger

| Issue ID | Severity | Module | Description & Root Cause | Affected Files | Status | Resolution / Current Mitigation |
|---|---|---|---|---|---|---|
| **BUG-01** | P0 | Auth | Admin login defaulted to `role: "YAJMAN"` | `src/services/auth.service.ts` | **RESOLVED** | Dynamically issues `role: "ADMIN"` if user possesses admin record in DB |
| **BUG-02** | P1 | Modals | Fake payment/allotment simulation in Kundli and Consultation modals | `consultation_flow_modal.dart`, `handmade_kundli_order_modal.dart` | **RESOLVED** | Replaced simulation with transparent desk helpline dispatch notices |
| **BUG-03** | P1 | Temples | Temple screen unhandled exception on location denial | `nearest_temple_screen.dart` | **RESOLVED** | Added graceful permission and disabled-location fallback |
| **BUG-04** | P2 | Admin | Missing Admin application queue list endpoint | `src/routes/pandits.routes.ts` | **RESOLVED** | Created dedicated `GET /api/v1/admin/pandits` queue |
| **BUG-05** | P2 | Security | Document verification permitted unauthenticated file download | `src/services/pandit-verification.service.ts` | **RESOLVED** | Restricted document streaming strictly to document owner or ADMIN token |
| **BUG-06** | P1 | State | Lack of server-side state transition validations in consultation/kundli | `consultations.service.ts`, `kundli_orders.service.ts` | **RESOLVED** | Implemented explicit state transition tables with 400 rejection |
| **BUG-07** | P2 | Privacy | Sensitive birth data (DOB, TOB) exposed in queue list views | `kundli_orders.service.ts` | **RESOLVED** | Masked birth timestamps in list queries; exposed only in single detail view |
| **BUG-08** | P1 | Dispatch | Stale Pandits eligible for live in-person dispatch | `src/services/dispatch.service.ts` | **RESOLVED** | Reduced `maxLocationAgeMs` to 10 minutes (600,000 ms) |
| **BUG-09** | P2 | Ops | Lack of request correlation in Express logging | `src/app.ts` | **RESOLVED** | Added correlation middleware propagating/generating UUIDv4 `x-request-id` |
| **BUG-10** | P1 | Ops | Ungraceful server shutdown on termination signals | `src/server.ts` | **RESOLVED** | Implemented graceful shutdown closing HTTP, Sockets, Redis, DB with 10s timeout |
| **BUG-11** | P1 | Telemetry | `req.validatedParams` unhandled access causing 500 in tracking controller | `src/controllers/tracking.controller.ts` | **RESOLVED** | Added fallback to `req.params.bookingId` safely |
| **BUG-12** | P1 | Security | Prototype pollution in `proxy-addr` dependency | `package-lock.json` | **RESOLVED** | Executed non-breaking `npm audit fix` |
| **BUG-13** | P2 | Security | Plaintext logging of sensitive tokens, OTPs, and birth data | `src/utils/logger.ts` | **RESOLVED** | Added Pino field-level `redact.paths` for secrets and birth data |
| **BUG-14** | P2 | Health | Health readiness probe failure scenarios lacked automated tests | `src/tests/health.test.ts` | **RESOLVED** | Added test cases for 503 (database down) and 200 (redis degraded) |
| **BUG-15** | P1 | DB | Live database was missing migration 0013 and spatial GIST index | `0013_consultations_and_kundli_orders.sql` | **RESOLVED** | Applied migration 0013 and `idx_pandits_location_gist` on Neon DB |
| **BUG-16** | P1 | Payments | Webhook smoke test conflated missing config (500) with signature validation | `live_smoke.ts`, `payments.test.ts` | **RESOLVED** | Separated signature verification from business processing; diagnosed 500 CONFIGURATION_ERROR |
| **BUG-17** | P1 | Auth/SMS | SMS OTP delivery lacked dedicated provider integration tests | `sms.service.ts`, `src/tests/sms.test.ts` | **RESOLVED** | Created `src/tests/sms.test.ts` (5 tests) and dynamic production error guard |
| **BUG-18** | P1 | Admin | Admin Portal entry point accessible inside ordinary mobile app drawer | `app_side_drawer.dart`, `main.dart` | **RESOLVED** | Removed Admin Portal entry point from mobile drawer & router; separated to web portal |
| **BUG-19** | P1 | Auth | Lack of dedicated Admin ID/Email and Password authentication endpoint | `src/routes/auth.routes.ts` | **RESOLVED** | Implemented `POST /api/v1/admin/auth/login` using NIST salt + scrypt hashing |
| **BUG-20** | P2 | UI | Hardcoded colors and styling scattered across Flutter screens | `frontend/pandit_ssetu/lib` | **RESOLVED** | Created centralized design system (`AppColors`, `AppTypography`, `AppSpacing`, `AppTheme`) and reusable `Sarv*` widgets |
| **BUG-21** | P2 | Clutter | Root directory cluttered with 7 historical Markdown audit files | Workspace root | **RESOLVED** | Relocated historical documents to `docs/audits/` and `docs/legacy/`; root `MASTER.md` preserved |
| **BUG-22** | P1 | Providers | External providers unverified on live sandbox environments | `.env` | **BLOCKED** | Razorpay, Fast2SMS, Firebase, Google Places, Agora lack live sandbox keys |
| **BUG-23** | P0 | Security | Initial admin credential exposed in docs, login UI hint, and tests | `login.ts`, `provision_admin.ts`, `docs/` | **RESOLVED** | Completely eliminated hardcoded credential from source, UI, and docs; rotated staging DB admin password to secure random 24-byte key |
| **BUG-24** | P1 | Security | Admin login susceptible to timing attacks and account enumeration | `src/controllers/admin-auth.controller.ts` | **RESOLVED** | Implemented constant-time dummy scrypt verification for non-existent accounts; generic 401 error message |
| **BUG-25** | P1 | Security | Admin sessions lacked short expiry and explicit server logout endpoint | `jwt.service.ts`, `admin-auth.controller.ts`, `admin.routes.ts` | **RESOLVED** | Added `signAdminToken` with 4-hour default validity; implemented `POST /api/v1/admin/auth/logout`; wired to portal UI |
| **BUG-26** | P1 | DevOps | Admin portal lacked containerization and staging service configuration | `admin-portal/Dockerfile`, `docker-compose.staging.yml` | **RESOLVED** | Created multi-stage Dockerfile with Nginx security headers and SPA routing; added service on port 3000 |

