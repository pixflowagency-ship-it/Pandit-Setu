# SARV MANGAL (सर्व मंगल)

> **सर्व मंगल मांगल्ये शिवे सर्वार्थ साधिके। शरण्ये त्र्यम्बके गौरि नारायणि नमोऽस्तु ते॥**  
> *Sacred Vedic Rituals, Astrological Guidance & Verified Pandit Services Platform*

[![Build Status](https://img.shields.io/badge/Backend_Tests-311%20Passed-success)](#)
[![Flutter Tests](https://img.shields.io/badge/Flutter_Tests-120%20Passed-success)](#)
[![Typecheck](https://img.shields.io/badge/TypeScript-0_Errors-brightgreen)](#)
[![Flutter Analyze](https://img.shields.io/badge/Flutter_Analyze-0_Issues-brightgreen)](#)
[![Database](https://img.shields.io/badge/PostgreSQL_18.6-PostGIS_3.6.4-blue)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 1. Project Overview

**SARV MANGAL** is a comprehensive, production-grade spiritual technology platform providing on-demand Vedic rituals, verified pandit proximity dispatch, handmade astrological Kundli generation, online video consultations, recurring pooja subscriptions, and sacred samagri e-commerce.

The ecosystem comprises three primary applications:
1. **Flutter Mobile Application (`frontend/pandit_ssetu`)**: Native Android & iOS client for Devotees (Yajmans) and Pandits, featuring live telemetry, booking dispatch, and video verification.
2. **Backend API Server (`src/`)**: Node.js / TypeScript / Express / PostGIS cluster with Redis Geo/pub-sub, Socket.IO real-time dispatch, and distributed token revocation.
3. **Dedicated Admin Web Portal (`admin-portal/`)**: Standalone executive single-page web application for KYC verification, mantra video review, video consultation scheduling, and Kundli fulfillment.

---

## 2. Core Features

- **Devotee Services**:
  - 26 Vedic Poojas catalog with rich samagri options and transparent pricing.
  - Geo-proximity Pandit dispatch with live GPS tracking.
  - Vedic Astrological Consultations with online video calling.
  - Handwritten & Postal Kundli generation with birth detail tracking.
  - Sacred Samagri E-Commerce with server-calculated checkout totals.
  - Phool Mala daily/weekly pooja subscriptions.
- **Pandit Partner Ecosystem**:
  - Single-method **Mantra Video Verification** studio with camera/mic viewfinder, live waveforms, and ISO BMFF MP4 recording.
  - Duty status toggle (Online/Offline) with continuous background GPS telemetry.
  - Instant booking dispatch alerts with accept/decline workflows and duplicate protection.
  - Cash Dakshina recording and Razorpay online Dakshina verification.
- **Admin & Operations Portal**:
  - Independent Vite SPA with scrypt password hashing and constant-time authentication.
  - Pandit KYC Dossier with HTML5 authorized `<video>` player and mantra review queue.
  - Approved Mantras Catalog CRUD Desk (add, edit, activate/deactivate Sanskrit mantras).
  - Consultation scheduling desk and Kundli postal fulfillment tracking.
  - Distributed token revocation engine ensuring secure administrative logouts.

---

## 3. Technology Stack

| Layer | Technologies |
|---|---|
| **Backend Core** | Node.js (ESM), TypeScript 5.8, Express 5.1 |
| **Database & ORM** | PostgreSQL 18.6 (AWS Neon) with PostGIS 3.6.4, Drizzle ORM |
| **Cache & Real-time** | Redis 7.2 (with in-memory fallback), Socket.IO 4.8 |
| **Logging & Security** | Pino (with sensitive field redaction), scrypt password hashing, JWT with distributed denylist |
| **Frontend Mobile** | Flutter 3.24+, Dart 3.5+, GoRouter, Material 3, Tokenized UI Design System |
| **Admin Web Portal** | Vite 5.4, TypeScript, Vanilla CSS Design System, HTML5 Media APIs |
| **Automated Testing** | Vitest 5.0 (Backend), Flutter Test / Flutter Driver (Mobile) |
| **Containerization** | Multi-stage Dockerfile, Docker Compose |

---

## 4. Repository Structure

```text
sarv-mangal/
├── README.md                           # Authoritative project overview & quickstart
├── MASTER.md                           # Canonical living phase ledger & issue tracker
├── LICENSE                             # MIT License
├── .gitignore                          # Standardized Git exclusion rules
├── .gitattributes                      # Git line-ending normalization & binary attributes
├── .editorconfig                       # Consistent code formatting configuration
├── .env.example                        # Backend environment variable template
├── docker-compose.yml                  # Local development container orchestration
├── docker-compose.staging.yml          # Containerized staging deployment stack
├── Dockerfile                          # Multi-stage production backend container
├── package.json                        # Root backend dependencies & operational scripts
├── package-lock.json                   # Deterministic backend dependency tree
├── tsconfig.json                       # Backend TypeScript configuration
├── drizzle.config.ts                   # Drizzle ORM database toolkit configuration
├── vitest.config.ts                    # Vitest automated test suite configuration
├── Pooja List.xlsx                     # Master Excel catalog for 26 Vedic poojas
├── Pooja_Store_App_Product_Master_500Plus.xlsx # Master Excel catalog for 1,267 store items
│
├── src/                                # Backend API Source Code (TypeScript)
│   ├── app.ts                          # Express application initialization & middleware
│   ├── server.ts                       # HTTP server entrypoint & graceful shutdown
│   ├── config/                         # Environment, Neon DB, and Redis configurations
│   ├── controllers/                    # HTTP request handlers & response formatters
│   ├── db/                             # Drizzle schema, custom PostGIS types & migrations
│   ├── middleware/                     # Token verification, RBAC, error & async handlers
│   ├── routes/                         # Express API route declarations
│   ├── services/                       # Core business logic, dispatch, payments & tokens
│   ├── tests/                          # 26 automated Vitest test suites (311 tests)
│   ├── types/                          # Shared backend type definitions
│   ├── utils/                          # Scrypt cryptography, API errors, and Pino logger
│   └── validators/                     # Zod request payload validation schemas
│
├── frontend/pandit_ssetu/              # Flutter Mobile Client
│   ├── pubspec.yaml                    # Flutter dependencies & declared assets
│   ├── lib/
│   │   ├── main.dart                   # Application entrypoint & GoRouter configuration
│   │   ├── branding.dart               # Official SARV MANGAL brand constants
│   │   ├── user_data.dart              # Devotee & Pandit persistent state models
│   │   ├── screens/                    # Mobile screens (Booking, Telemetry, Onboarding)
│   │   ├── services/                   # ApiService, SocketService, LocationService
│   │   ├── theme/                      # Centralized design tokens (Colors, Typography, Theme)
│   │   └── widgets/                    # Standardized UI components & Sarv* widgets
│   ├── test/                           # 19 Flutter test suites (120 passing widget tests)
│   └── assets/                         # Optimized application images, logos & data
│
├── admin-portal/                       # Dedicated Executive Web Portal (SPA)
│   ├── index.html                      # HTML5 web shell
│   ├── package.json                    # Vite + TypeScript build configuration
│   ├── Dockerfile                      # Multi-stage Nginx container configuration
│   ├── src/
│   │   ├── api.ts                      # Admin REST client with auto-logout handling
│   │   ├── main.ts                     # Portal entrypoint & view coordinator
│   │   ├── types.ts                    # Admin TypeScript interfaces & mantra contracts
│   │   └── views/                      # Desk views (Overview, KYC, Consultations, Kundli)
│   └── vite.config.ts                  # Vite production bundler configuration
│
├── scripts/                            # Operational & Data Management Scripts
│   └── convert_excel.cjs               # Data extraction utility for catalog assets
│
└── docs/                               # Comprehensive Engineering Documentation
    ├── DOCUMENTATION_MANIFEST.md       # Complete inventory of repository documentation
    ├── AUDIT_SUMMARY.md                # System audit findings & recommendations
    ├── BUGS_AND_INCOMPLETENESS.md      # Bug tracker & quality dispositions
    ├── CLEANUP_MANIFEST.md             # Sanitization & hygiene manifest
    ├── architecture/                   # System & UI Architecture Specifications
    │   ├── ADMIN_PORTAL_ARCHITECTURE.md
    │   ├── BUTTON_AND_TAB_INVENTORY.md
    │   ├── FEATURE_INVENTORY.md
    │   ├── PROJECT_STRUCTURE.md
    │   ├── UI_CUSTOMIZATION_GUIDE.md
    │   ├── USER_JOURNEYS.md
    │   └── Sarvmangal_Services_UI_Gaps_Cost_Efficient_Stack.pdf
    ├── setup/                          # Developer Environment Setup
    │   └── SETUP_GUIDE.md
    ├── api/                            # API Specifications
    │   └── API_AND_INTEGRATION_INVENTORY.md
    ├── deployment/                     # Deployment & Release Checklists
    │   ├── RELEASE_CHECKLIST.md
    │   └── STAGING_DEPLOYMENT.md
    ├── security/                       # Security & External Provider Audits
    │   ├── PROVIDER_VERIFICATION_MATRIX.md
    │   └── SECURITY_AUDIT.md
    ├── reports/                        # Phase Milestone & Test Evidence Reports
    │   ├── ADMIN_PORTAL_TEST_REPORT.md
    │   ├── MANTRA_RECORDING_VERIFICATION_REPORT.md
    │   ├── PHASE_MANTRA_VERIFICATION_REPORT.md
    │   ├── PHASE_P10_REPORT.md
    │   ├── ...                         # Historical Phase Reports (P5 - P9)
    │   └── UPLOAD_PACKAGE_REPORT.md
    ├── audits/                         # Historical Audit Archives (Preserved)
    └── legacy/                         # Historical Scope Specifications
```

---

## 5. Quick Start & Setup

### Prerequisites
- **Node.js**: v20+ LTS
- **Flutter SDK**: 3.24+ (Dart 3.5+)
- **PostgreSQL**: 16+ with PostGIS extension enabled
- **Redis**: 7.0+ (optional; memory fallback included)

### 1. Backend API Server
```bash
# Install dependencies
npm install

# Configure environment variables
cp .env.example .env
# Edit .env with your local PostgreSQL and Redis credentials

# Run database schema migrations
npm run db:push

# Seed master pooja and store catalogs from Excel
npm run seed
npm run import:poojas
npm run import:products

# Run automated checks
npm run typecheck       # 0 errors
npm test                # 311 tests passing across 26 suites

# Launch development server
npm run dev             # Listens on http://localhost:5000
```

### 2. Dedicated Admin Web Portal
```bash
cd admin-portal

# Install dependencies
npm install

# Configure environment
cp .env.example .env

# Validate TypeScript & build production bundle
npm run build           # Vite production bundle in <400ms

# Launch development portal
npm run dev             # Available on http://localhost:3000
```

### 3. Flutter Mobile Application
```bash
cd frontend/pandit_ssetu

# Resolve dependencies
flutter pub get

# Static code analysis
flutter analyze         # No issues found!

# Run widget & integration tests
flutter test            # 120 tests passing across 19 suites

# Launch mobile application
flutter run
```

---

## 6. Testing & Quality Verification

All three applications feature comprehensive automated test suites:

| Component | Test Runner | Files | Tests | Status |
|---|---|---|---|---|
| **Backend API** | Vitest | 26 test files | **311 / 311** | **PASSED** (100% green) |
| **Backend Typecheck** | TypeScript `tsc --noEmit` | Entire codebase | 0 errors | **PASSED** |
| **Mobile Client** | Flutter Test | 19 test files | **120 / 120** | **PASSED** (100% green) |
| **Mobile Analysis** | `flutter analyze` | Entire Flutter app | 0 issues | **PASSED** |
| **Admin Portal** | TypeScript & Vite | 13 modules | 0 errors | **PASSED** (Built in 373ms) |
| **Live Database** | Drizzle ORM | 23 tables | Migration 0016 | **VERIFIED** on AWS Neon |

---

## 7. Security & Environment Configuration

- **Zero Hardcoded Credentials**: All secrets, JWT keys, and API tokens are loaded dynamically from environment variables.
- **Timing Attack Mitigation**: Admin authentication uses constant-time scrypt verification with dummy hash validation for non-existent users, mitigating user enumeration and timing side-channels.
- **Distributed Token Revocation**: State-driven administrative logouts revoke JWT tokens across multi-instance clusters using SHA-256 denylisting in Redis with automatic TTL expiration.
- **Field-Level Sensitive Redaction**: Pino logging filters redact `password`, `token`, `otp`, `jwt`, `authorization`, `razorpay_signature`, `dob`, and `tob`.
- **Private Video & Document Storage**: Pandit KYC files and mantra video recordings are stored outside public web roots with restricted permissions and authenticated streaming tokens.

---

## 8. Deployment Overview

- **Local Compose**: Execute `docker compose up --build -d` to launch Backend, Admin Portal, PostGIS, and Redis locally.
- **Staging Compose**: Execute `docker compose -f docker-compose.staging.yml up -d` for staging environments with explicit database separation.
- **Cloud Database**: Managed AWS Neon PostgreSQL 18.6 with PostGIS 3.6.4 and spatial index `idx_pandits_location_gist`.

For detailed staging guides, database rollback drills, and operational protocols, refer to [docs/deployment/STAGING_DEPLOYMENT.md](docs/deployment/STAGING_DEPLOYMENT.md).

---

## 9. License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
