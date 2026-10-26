# SARV MANGAL — Cleanup Manifest

**Phase:** P7 Repository Organization & Hygiene  
**Date:** October 20, 2026

---

## 1. Principles of Repository Hygiene

The cleanup process followed strict non-destructive safety rules:
1. **No Destructive Deletions:** No tracked source files, test fixtures, seeds, migrations, or user assets were removed.
2. **Preservation of Build & Manifest Configs:** `package.json`, `package-lock.json`, `pubspec.yaml`, `pubspec.lock`, `tsconfig.json`, `Dockerfile`, and `docker-compose.staging.yml` were preserved.
3. **Exclusion of Secrets:** Local `.env` files and live database connection credentials remain excluded from public VCS via `.gitignore` and `.dockerignore`.
4. **Exclusion of Ephemeral Artifacts:** `node_modules/`, `.dart_tool/`, and build outputs are excluded from source distribution packages.

---

## 2. File Status Categorization

### 2.1 Preserved Essential Source & Assets
- `src/**`: Node.js / Express backend TypeScript codebase (controllers, services, db, tests, middleware).
- `frontend/pandit_ssetu/**`: Flutter mobile application (Dart source, assets, fonts, test suite).
- `admin-portal/**`: Standalone Vite + TypeScript Admin Portal SPA.
- `drizzle/**`: Drizzle SQL migrations (including `0013_consultations_and_kundli_orders.sql`).
- `storage/**`: Local storage folder for KYC document uploads.
- `Pooja List.xlsx` & `Pooja_Store_App_Product_Master_500Plus.xlsx`: Seed data catalogs for ritual and store product imports.

### 2.2 Migrated Documentation
- 7 root markdown files migrated safely into `docs/audits/` and `docs/legacy/`.
- Root `README.md` created as an authoritative, clean entrypoint.
- Root `MASTER.md` preserved as the living master engineering ledger.

### 2.3 Excluded / Ignored from Release Package
- `node_modules/` (Backend: 140+ packages)
- `admin-portal/node_modules/` (Admin Portal packages)
- `frontend/pandit_ssetu/.dart_tool/` (Flutter SDK metadata)
- `frontend/pandit_ssetu/build/` (Compiled APK/iOS intermediates)
- `.env` (Live credentials — replaced by sanitized `.env.example` and `admin-portal/.env.example`)
- `scratch/` (Temporary testing logs)
