# SARV MANGAL — Provider Verification Matrix

**Phase:** P10 Reproducible Deployment, Distributed Security, Release Integrity & Beta Readiness  
**Date:** October 20, 2026  
**Operating Standard:** Evidence-based classification using canonical status labels (`VERIFIED`, `CODE VERIFIED`, `BLOCKED`, `FAILED`, `NOT TESTED`). Never declare third-party providers or physical hardware verified without cryptographic proof or live sandbox telemetry.

---

## 1. Canonical Provider Classification Matrix

| Integration | Intended Role | Verification Status | Evidence & Test Suite | Pending Requirement / Owner Action |
|---|---|:---:|---|---|
| **PostgreSQL + PostGIS (AWS Neon)** | Relational data persistence & spatial geospatial pandit dispatch | `VERIFIED` | 22 public tables verified in AWS Neon cloud instance. PostGIS 3.6.4 extension active. Spatial GIST index `idx_pandits_location_gist` operational on `pandits.location`. Admin account provisioned with scrypt hash and 16-byte salt. Live readiness probe passed in Step 03 of staging smoke suite. | Continuous staging connection monitoring. |
| **Distributed Token Revocation Engine** | Cross-instance JWT invalidation on logout and token reuse rejection | `VERIFIED` | 9 tests in `src/tests/distributed_token_revocation.test.ts` passing: proven across two independently initialized backend instances sharing Redis; TTL calculation matches token expiry; fail-closed security policy enforced when Redis is offline. | Provide managed Redis URL for staging cluster deployment. |
| **Razorpay** | Online payments for Poojas, Consultations, Kundli orders, and Webhooks | `CODE VERIFIED` | 24 tests in `src/tests/payments.test.ts` passing: Raw HMAC body signature verification, payment event state transitions, and Redis/DB idempotency. Staging smoke steps 20 & 21 confirmed signature requirement and configuration guard. | Live Razorpay Dashboard Key ID, Key Secret, and Webhook Secret required for live sandbox tests. |
| **Fast2SMS** | Devotee and Pandit OTP SMS delivery via Bulk V2 API | `CODE VERIFIED` | 5 tests in `src/tests/sms.test.ts` passing: JSON route 'otp' payload, 10-digit phone sanitization, and production error throwing. Staging smoke step 06 verified OTP generation. | Real FAST2SMS_API_KEY and authorized test SIM required for carrier delivery verification. |
| **Firebase Cloud Messaging (FCM)** | Push notifications for booking requests, pandit proximity, and status updates | `CODE VERIFIED` | 4 tests in `src/tests/notification.test.ts` passing: credential loading, push dispatch, and automatic purge of stale/invalid FCM tokens. | `FIREBASE_SERVICE_ACCOUNT_BASE64` or service account JSON required for production APNs/FCM delivery. |
| **Google Places API** | Nearby temple discovery and devotee geolocation search | `CODE VERIFIED` | 3 tests in `src/tests/temples.test.ts` passing: Nearby temple query, geohash caching, and graceful fallback on API timeout/error. | Authorized Google Maps Platform API key with Places API enabled for production traffic. |
| **Agora RTC** | Real-time audio/video consultations for Vedic astrology | `CODE VERIFIED` | 2 tests in `src/tests/agora.test.ts` passing: Secure server-side RTC token generation (`RtcTokenBuilder`), privilege expiration, and channel validation. | Agora App ID & App Certificate required for live multi-party media streaming. |
| **Redis** | Geohash clustering, booking concurrency locking, socket room adapter, token denylist | `CODE VERIFIED` | Multi-instance distributed revocation and fallback tested in `distributed_token_revocation.test.ts`. Ready for staging cluster. | External managed Redis instance URL for staging/production cluster. |
| **Docker Staging Engine** | Containerized staging stack execution | `BLOCKED` | `docker` CLI not installed on host machine (`CommandNotFoundException`). `Dockerfile`, `admin-portal/Dockerfile`, and `docker-compose.staging.yml` verified by static analysis. | Install Docker Desktop / Docker Engine on host or build via CI runner. |
| **Physical Android & GPS Hardware** | Real background GPS telemetry, foreground service, battery optimization | `BLOCKED` | `flutter devices` reports only desktop web browsers (Chrome, Edge); no physical phone or emulator attached. 12-point manual protocol documented in `docs/PHASE_P10_REPORT.md`. | Physical Android hardware device running Android 12+ connected via USB debugging. |
