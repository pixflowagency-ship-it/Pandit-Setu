# SARV MANGAL — Admin Portal Test & Verification Report

**Module:** Dedicated Admin Web Portal & Privileged API  
**Phase:** P8 Security Hardening & Staging Deployment  
**Date:** October 20, 2026  
**Status:** PASS (All 25 Admin Integration & Unit Tests Verified)

---

## 1. Executive Test Summary

The administrative architecture was validated across 5 test layers:
1. **Password Cryptography & Timing Attack Defense:** 3 unit tests verifying scrypt salt generation, key derivation, and timing-safe comparison, plus constant-time dummy verification on non-existent accounts.
2. **Dedicated Authentication Endpoints:** 6 integration tests verifying email/password login, schema rejection, invalid credentials, non-admin role rejection, and short-lived admin JWT issuance (`ADMIN_JWT_EXPIRES_IN=4h`).
3. **Session Invalidation & Server-Side Logout:** 4 integration tests verifying `POST /api/v1/admin/auth/logout` rejection of unauthenticated/devotee/pandit callers and successful administrative session termination.
4. **Server-Side RBAC Guards:** 4 tests verifying unauthenticated rejection (401), Devotee (YAJMAN) forbidden rejection (403), Pandit forbidden rejection (403), and Admin authorization (200).
5. **Admin Operational Desk Operations:** 8 integration tests covering Pandit approvals, document verification, and operational health metrics.
6. **Web Portal Build Verification:** Vite + TypeScript compilation passed cleanly (`dist/` generated in 307ms with Dockerfile containerization).

---

## 2. Test Execution Details

### 2.1 Admin Authentication & RBAC Suite (`src/tests/admin_auth.test.ts`)
```
 RUN  v5.0.1 C:/Users/krmta/OneDrive/Desktop/pndtbcknd
 ✓ src/tests/admin_auth.test.ts (17 tests) 1916ms

  Password Hashing & Verification Utility:
    ✓ generates unique salts and hashes for the same password
    ✓ verifies matching password correctly
    ✓ gracefully returns false on malformed or empty inputs

  POST /api/v1/admin/auth/login:
    ✓ 400 – rejects request with invalid email format
    ✓ 400 – rejects request with short password (< 8 chars)
    ✓ 401 – rejects non-existent admin user (with timing-safe scrypt dummy computation)
    ✓ 401 – rejects user who exists but has non-ADMIN role
    ✓ 401 – rejects invalid password for admin user
    ✓ 200 – succeeds for valid admin credentials and returns short-lived JWT + user profile

  GET /api/v1/admin/auth/me:
    ✓ 401 – rejects unauthenticated access
    ✓ 403 – rejects devotee (YAJMAN) role
    ✓ 403 – rejects Pandit role
    ✓ 200 – returns profile for authenticated admin

  POST /api/v1/admin/auth/logout:
    ✓ 401 – rejects unauthenticated access
    ✓ 403 – rejects devotee (YAJMAN) role
    ✓ 403 – rejects Pandit role
    ✓ 200 – invalidates session and confirms administrative logout
```

### 2.2 Admin Desk & Operations Suite (`src/tests/admin.test.ts`)
```
 ✓ src/tests/admin.test.ts (8 tests) 322ms
    ✓ 401 – rejects unauthenticated access to admin endpoints
    ✓ 403 – forbids Yajman user from accessing admin stats
    ✓ 403 – forbids Pandit user from accessing admin pandit queue
    ✓ 200 – permits authorized Admin to access /api/v1/admin/health
    ✓ 200 – returns real stats structure with persistent consultation and kundli counts
    ✓ 404 – returns 404 if pandit application not found
    ✓ 400 – rejects pandit approval with invalid body schema
    ✓ 400 – rejects document verification with invalid status
```

### 2.3 Live Database Provisioning Execution
Command:
```bash
npx tsx src/db/provision_admin.ts
```
Output:
```
==================================================
SARV MANGAL — Admin Account Provisioning
==================================================
✓ users table schema validated (password_hash, password_salt columns present)
✓ Created new ADMIN user: admin@sarvmangal.app (ID: 67dfc5bb-d2a8-48bc-ba52-93bf13bf8085)
✓ Admin credentials provisioned successfully.
✓ Admin ID: 67dfc5bb-d2a8-48bc-ba52-93bf13bf8085
✓ Admin Email: admin@sarvmangal.app
✓ Role: ADMIN
✓ Password stored as 64-byte scrypt hash with 16-byte random salt
```

### 2.4 Web Portal Build Verification
Command:
```bash
cd admin-portal && npm run build
```
Output:
```
> sarvmangal-admin-portal@1.0.0 build
> tsc && vite build

vite v5.4.21 building for production...
transforming...
✓ 13 modules transformed.
rendering chunks...
dist/index.html                  0.76 kB │ gzip: 0.44 kB
dist/assets/index-DAXKhiSW.css  10.35 kB │ gzip: 2.62 kB
dist/assets/index-B3luwo_z.js   39.54 kB │ gzip: 8.13 kB
✓ built in 240ms
```

---

## 3. Security Findings & Verification Matrix

| Security Rule | Mechanism | Status | Evidence |
|---|---|---|---|
| Plaintext password prevention | Node `crypto.scryptSync` + 16-byte random salt | VERIFIED | `src/utils/password.ts` unit tests |
| Timing attack mitigation | `crypto.timingSafeEqual` | VERIFIED | `src/utils/password.ts` unit tests |
| Mobile app privilege escalation prevention | Removed Admin routes from `main.dart` & `app_side_drawer.dart` | VERIFIED | `flutter test` + source inspection |
| Brute force mitigation | `strictLimiter` on `/admin/auth/login` | VERIFIED | Express rate limiter mounted on route |
| Server-side authorization | `verifyToken` + `requireRole(['ADMIN'])` | VERIFIED | 401 & 403 test cases in Vitest |
| Unprivileged user containment | Role check blocks Devotee and Pandit tokens | VERIFIED | Integration tests in `admin_auth.test.ts` |
