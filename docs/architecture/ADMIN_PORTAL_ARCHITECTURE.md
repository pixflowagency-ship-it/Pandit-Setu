# SARV MANGAL — Dedicated Admin Web Portal Architecture

**Brand:** SARV MANGAL  
**Module:** Administrative Operations, KYC Verification & Astrological Coordination  
**Directory:** `admin-portal/`  
**Deployment Target:** Standalone Single Page Web Application (Vite + TypeScript + Vanilla CSS)  
**Configurable Domain:** `https://admin.example.com` (Staging/Production configurable via environment)

---

## 1. Architectural Separation

Historically, administrative capabilities were exposed within the Flutter mobile application drawer (`/admin-dashboard`). Under Phase P7, complete architectural separation has been enforced:

```
                                  ┌───────────────────────────────┐
                                  │   Devotee & Pandit Mobile     │
                                  │   Flutter App (iOS & Android) │
                                  └───────────────┬───────────────┘
                                                  │ Public Endpoints & Mobile JWT
                                                  ▼
┌───────────────────────────────┐         ┌───────────────────────────────┐
│   Dedicated Admin Portal      ├────────►│   SARV MANGAL Backend API     │
│   (admin-portal/ SPA)         │ Admin   │   Node.js / Express / PostGIS │
│   Origin: https://admin...    │ JWT     └───────────────┬───────────────┘
└───────────────────────────────┘                         │
                                                          ▼
                                                  ┌───────────────────────────────┐
                                                  │   Neon PostgreSQL + PostGIS   │
                                                  │   22 Tables + Spatial GIST    │
                                                  └───────────────────────────────┘
```

### Key Security Boundaries:
1. **Mobile App Decoupled:** The `Admin Verification Desk` tile in `app_side_drawer.dart` and `/admin-dashboard` route in `main.dart` have been removed. Devotees and Pandits cannot reach administrative views on mobile.
2. **Dedicated Admin Origin:** The portal runs as an independent web application on its own origin (e.g. `http://localhost:5173` locally, `https://admin.example.com` in staging/production).
3. **CORS Enforcement:** The backend enforces CORS allowlists. Privileged admin headers are rejected from unapproved origins.
4. **Server-Side Role Guard:** Regardless of frontend state, every privileged API endpoint (`/api/v1/admin/*`) strictly validates that `req.user.role === 'ADMIN'`.

---

## 2. Authentication & Identity Architecture

### 2.1 Identity Storage
The `users` table in PostgreSQL has been extended non-destructively:
- `password_hash VARCHAR(255)`: 64-byte hex-encoded scrypt derived key.
- `password_salt VARCHAR(64)`: 16-byte cryptographically secure random salt.
- `role`: PostgreSQL enum `user_role` (`ADMIN`, `PANDIT`, `YAJMAN`).

### 2.2 Password Cryptography (`src/utils/password.ts`)
- **Algorithm:** Node.js native `crypto.scryptSync(password, salt, 64)`.
- **Salt Generation:** `crypto.randomBytes(16).toString("hex")`.
- **Verification:** Constant-time buffer comparison via `crypto.timingSafeEqual` prevents timing side-channel attacks.
- **Dependency Footprint:** Zero native C++ node-gyp bindings; zero build failures across container environments.

### 2.3 Authentication Endpoints & Session Lifecycle
- `POST /api/v1/admin/auth/login`:
  - Rate-limited via `strictLimiter` (5 attempts per window) against brute force.
  - Validates email and password length (min 8 chars) via Zod `adminLoginSchema`.
  - Timing attack defense: Computes scrypt verification against a precomputed dummy hash/salt if the account does not exist, guaranteeing constant CPU execution time to defeat account enumeration.
  - Verifies scrypt hash and ensures `role === 'ADMIN'`.
  - Issues dedicated short-lived administrative JWT signed via `signAdminToken` with validity controlled by `ADMIN_JWT_EXPIRES_IN` (defaults to 4 hours, unlike the 7-day mobile token).
- `GET /api/v1/admin/auth/me`:
  - Protected by `verifyToken` and `requireRole(['ADMIN'])`.
  - Returns current admin profile.
- `POST /api/v1/admin/auth/logout`:
  - Protected by `verifyToken` and `requireRole(['ADMIN'])`.
  - Terminates the administrative session and instructs the client to clear session tokens.

### 2.4 Provisioning Protocol (`src/db/provision_admin.ts`)
Admin accounts are never created via public self-service registration. They are provisioned through a controlled CLI command requiring environment variables:
```bash
ADMIN_INITIAL_EMAIL="admin@sarvmangal.app" ADMIN_INITIAL_PASSWORD="<STRONG_UNIQUE_PASSWORD>" npx tsx src/db/provision_admin.ts
```
Security Rules:
- Both `ADMIN_INITIAL_EMAIL` and `ADMIN_INITIAL_PASSWORD` are strictly required (minimum 12 characters).
- If the account already exists, existing credentials are preserved unless `FORCE_ADMIN_PASSWORD_RESET=true` is explicitly provided.
- Plaintext passwords, hashes, and salts are never output to console logs.

---

## 3. Five-Tab Operational Capabilities

| Tab Index | Operational Desk | Key Capabilities | Backend API Routes |
|---|---|---|---|
| **Tab 1** | **System Overview** | Real-time platform metrics, active pandits, booking totals, consultation backlogs, health probe | `GET /admin/stats`, `GET /admin/health` |
| **Tab 2** | **Pandit KYC Queue** | Filterable applicants (ALL, PENDING, APPROVED, REJECTED), applicant dossier, document verification, video status, Approve/Reject modal with reason | `GET /admin/pandits`, `GET /admin/pandits/:id`, `PATCH /admin/pandits/:id/approval`, `PATCH /admin/documents/:id/verify` |
| **Tab 3** | **Consultations Desk** | Vedic astrology video queue, schedule date/time, Agora link dispatch, status update | `GET /admin/consultations`, `PATCH /admin/consultations/:id/schedule`, `PATCH /admin/consultations/:id/status` |
| **Tab 4** | **Kundli Orders Desk** | Handwritten Kundli orders, devotee birth details (DOB, TOB, POB, Gotra), Accept/Reject decision, courier dispatch & tracking updates | `GET /admin/kundli-orders`, `PATCH /admin/kundli-orders/:id/decision`, `PATCH /admin/kundli-orders/:id/status` |
| **Tab 5** | **Subscriptions Oversight** | Devotee recurring pooja plans, monthly billing states (ACTIVE, PENDING, HALTED, CANCELLED) | `GET /admin/subscriptions` |

---

## 4. Deployment & Build Protocol

### Local Development
```bash
cd admin-portal
npm install
npm run dev
# Starts on http://localhost:5173 connecting to http://localhost:5000/api/v1
```

### Production Build
```bash
cd admin-portal
npm run build
# Outputs static HTML/CSS/JS bundle to admin-portal/dist/
```

### Static Hosting / Nginx Example
```nginx
server {
    listen 80;
    server_name admin.example.com;

    root /var/www/sarvmangal-admin-portal/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://backend-api:5000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```
