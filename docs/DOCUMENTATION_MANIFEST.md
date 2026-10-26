# SARV MANGAL — Documentation Manifest

**Module:** Repository Knowledge & Engineering Records  
**Status:** FULLY CATEGORIZED & ORGANIZED  
**Date:** October 26, 2026

---

## 1. Directory Structure

All engineering documents across the repository are categorized into structured subdirectories inside `docs/`:

```text
docs/
├── DOCUMENTATION_MANIFEST.md        # This manifest
├── AUDIT_SUMMARY.md                 # Summary of system audits and findings
├── BUGS_AND_INCOMPLETENESS.md       # Quality and bug tracking dispositions
├── CLEANUP_MANIFEST.md              # Repository hygiene and cleanup manifest
│
├── architecture/                    # System & UI Architecture Specs
│   ├── ADMIN_PORTAL_ARCHITECTURE.md
│   ├── BUTTON_AND_TAB_INVENTORY.md
│   ├── FEATURE_INVENTORY.md
│   ├── PROJECT_STRUCTURE.md
│   ├── UI_CUSTOMIZATION_GUIDE.md
│   ├── USER_JOURNEYS.md
│   └── Sarvmangal_Services_UI_Gaps_Cost_Efficient_Stack.pdf
│
├── setup/                           # Developer Setup & Onboarding
│   └── SETUP_GUIDE.md
│
├── api/                             # API Specs & Endpoint Catalog
│   └── API_AND_INTEGRATION_INVENTORY.md
│
├── deployment/                      # Deployment, Docker & Release Checklists
│   ├── RELEASE_CHECKLIST.md
│   └── STAGING_DEPLOYMENT.md
│
├── security/                        # Security Audits & Provider Matrix
│   ├── PROVIDER_VERIFICATION_MATRIX.md
│   └── SECURITY_AUDIT.md
│
├── reports/                         # Phase Milestone & Verification Reports
│   ├── ADMIN_PORTAL_TEST_REPORT.md
│   ├── MANTRA_RECORDING_VERIFICATION_REPORT.md
│   ├── PHASE_MANTRA_VERIFICATION_REPORT.md
│   ├── PHASE_P5_REPORT.md
│   ├── PHASE_P6_REPORT.md
│   ├── PHASE_P7_REPORT.md
│   ├── PHASE_P8_REPORT.md
│   ├── PHASE_P9_REPORT.md
│   ├── PHASE_P10_REPORT.md
│   ├── PHASE_UI_REPAIR_REPORT.md
│   └── UPLOAD_PACKAGE_REPORT.md
│
├── audits/                          # Historical Audit Snapshots (Preserved)
│   ├── BUGS.md
│   ├── CURRENT_WORKING_STATUS.md
│   ├── IMPLEMENTATION_PROGRESS.md
│   ├── KNOWN_ISSUES.md
│   └── bckndaudit.md
│
└── legacy/                          # Historical Design & Scope Specifications
    ├── guide.md
    └── project.md
```

---

## 2. Document Inventory & Classification

| Document Path | Classification | Description / Scope |
|---|---|---|
| `MASTER.md` (Root) | Canonical Master Ledger | Living project status, test metrics, and phase progress |
| `README.md` (Root) | Repository Entrypoint | Project overview, setup, architecture, and developer quickstart |
| `docs/setup/SETUP_GUIDE.md` | Setup Guide | Step-by-step developer environment setup for Backend, Flutter & Admin Portal |
| `docs/architecture/ADMIN_PORTAL_ARCHITECTURE.md` | Architecture Spec | Dedicated Admin Portal SPA architecture, routing, and RBAC |
| `docs/architecture/BUTTON_AND_TAB_INVENTORY.md` | UI Inventory | Mapping of all interactive buttons, tabs, dialogs, and callbacks |
| `docs/architecture/FEATURE_INVENTORY.md` | Product Inventory | 43 core features mapped across 14 modules |
| `docs/architecture/PROJECT_STRUCTURE.md` | Structure Spec | Comprehensive codebase folder hierarchy and file descriptions |
| `docs/architecture/UI_CUSTOMIZATION_GUIDE.md` | Design System | Centralized tokenized UI design system tokens, colors, typography |
| `docs/architecture/USER_JOURNEYS.md` | User Experience | 10 end-to-end user journeys for Devotee, Pandit, and Admin |
| `docs/api/API_AND_INTEGRATION_INVENTORY.md` | API Specification | All 48 backend endpoints with method, auth, and schema |
| `docs/deployment/STAGING_DEPLOYMENT.md` | Deployment Guide | Multi-stage Dockerfile, Compose, DB disambiguation, rollback protocol |
| `docs/deployment/RELEASE_CHECKLIST.md` | Release Checklist | Staging and production release readiness checklists |
| `docs/security/SECURITY_AUDIT.md` | Security Review | Cryptography, scrypt hashing, token revocation, RBAC, log redaction |
| `docs/security/PROVIDER_VERIFICATION_MATRIX.md` | Integration Matrix | Live status of PostgreSQL, Redis, Razorpay, Fast2SMS, FCM, Agora |
| `docs/reports/PHASE_MANTRA_VERIFICATION_REPORT.md` | Milestone Report | Elimination of video-call verification and mandatory Mantra Video Verification |
| `docs/reports/PHASE_P10_REPORT.md` | Milestone Report | Distributed cross-instance token revocation engine & multi-instance security |
| `docs/reports/PHASE_P9_REPORT.md` | Milestone Report | Live staging smoke suite & token invalidation proof |
| `docs/reports/PHASE_P8_REPORT.md` | Milestone Report | Admin credential remediation, timing attack mitigation, and session expiry |
| `docs/reports/PHASE_P7_REPORT.md` | Milestone Report | Admin portal decoupling, centralized design system, repository cleanup |
| `docs/reports/PHASE_P6_REPORT.md` | Milestone Report | Empirical provider audit and physical Android verification protocol |
| `docs/reports/PHASE_P5_REPORT.md` | Milestone Report | Cloud staging readiness, PostGIS migration, and containerization |
