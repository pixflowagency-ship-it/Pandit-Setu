# SARV MANGAL — Project Structure & Directory Layout

**Platform:** SARV MANGAL Multi-Tier Architecture  
**Date:** October 20, 2026

---

## 1. Top-Level Hierarchy

```
pndtbcknd/
├── .dockerignore                   # Build context exclusion for Docker
├── .env.example                    # Sanitized backend environment template
├── .gitignore                      # Git tracking exclusions
├── Dockerfile                      # Multi-stage production container build
├── docker-compose.staging.yml      # Local containerized staging stack (API, DB, Redis)
├── MASTER.md                       # Canonical project ledger & release tracker
├── README.md                       # Primary repository onboarding documentation
├── package.json                    # Backend NPM manifest
├── package-lock.json               # Backend locked dependency tree
├── tsconfig.json                   # Backend TypeScript compiler configuration
├── vitest.config.ts                # Backend test runner configuration
├── drizzle.config.ts               # Drizzle ORM migration configuration
│
├── admin-portal/                   # Standalone Admin Web Application (SPA)
│   ├── .env.example                # Admin portal environment template
│   ├── index.html                  # Web entry point
│   ├── package.json                # Vite & TypeScript manifest
│   ├── tsconfig.json               # Frontend TypeScript configuration
│   ├── vite.config.ts              # Vite bundler configuration
│   └── src/                        # Admin Portal source code
│       ├── api.ts                  # Type-safe backend HTTP client
│       ├── auth.ts                 # Local session & token storage
│       ├── main.ts                 # App bootstrap & view router
│       ├── style.css               # Vanilla CSS design system
│       ├── types.ts                # TypeScript data interfaces
│       └── views/
│           ├── dashboard.ts        # Top navigation & tab coordinator
│           ├── login.ts            # Dedicated Admin email/password login
│           └── tabs/
│               ├── consultations.ts# Vedic consultation queue & scheduling
│               ├── kundli.ts       # Handmade Kundli orders desk
│               ├── overview.ts     # System metrics & cluster health
│               ├── pandits.ts      # Pandit KYC verification desk
│               └── subscriptions.ts# Recurring devotee plans oversight
│
├── frontend/pandit_ssetu/          # Flutter Mobile Application
│   ├── pubspec.yaml                # Flutter packages & asset configuration
│   ├── pubspec.lock                # Locked Flutter dependency tree
│   ├── analysis_options.yaml       # Dart analyzer rules
│   ├── lib/
│   │   ├── main.dart               # App entrypoint & GoRouter routing
│   │   ├── user_data.dart          # Local SharedPreferences user session
│   │   ├── user_profile_detail_screen.dart # Devotee astrological profile
│   │   ├── config/                 # Mobile environment configuration
│   │   ├── constants/
│   │   │   └── branding.dart       # SARV MANGAL app title & Sanskrit shloka
│   │   ├── screens/                # 20+ Mobile screens (Auth, Bookings, Store, Profile)
│   │   ├── services/               # REST API, Socket.IO & Location services
│   │   ├── theme/                  # Centralized Design System
│   │   │   ├── app_colors.dart     # Saffron, Gold, and Semantic palette
│   │   │   ├── app_spacing.dart    # 4px grid spacing, radii, and shadows
│   │   │   ├── app_theme.dart      # Material 3 ThemeData factory
│   │   │   └── app_typography.dart # Font scale & weights
│   │   ├── utils/                  # Formatting helpers
│   │   └── widgets/                # UI components
│   │       ├── common/             # Reusable Sarv* widgets
│   │       │   ├── sarv_button.dart# Primary, secondary, outlined, destructive buttons
│   │       │   ├── sarv_card.dart  # Elevated warm cards
│   │       │   ├── sarv_states.dart# Loading, empty, and error/retry views
│   │       │   ├── sarv_status_badge.dart # Semantic lifecycle chips
│   │       │   └── sarv_text_field.dart # Form fields with password toggle
│   │       ├── app_side_drawer.dart# Drawer (Admin tile removed)
│   │       ├── consultation_flow_modal.dart # Devotee consultation booking
│   │       ├── handmade_kundli_order_modal.dart # Devotee Kundli ordering
│   │       ├── pandit_chat_modal.dart # In-app direct messaging
│   │       └── pooja_request_modal.dart # Pandit dispatch acceptance
│   └── test/                       # 17 Test files (104 Passing Tests)
│
├── src/                            # Backend API Service
│   ├── server.ts                   # HTTP listener & cluster bootstrap
│   ├── app.ts                      # Express application assembly & middleware
│   ├── config/                     # Environment, DB & Redis connectors
│   ├── controllers/                # 14 HTTP Controllers
│   │   ├── admin-auth.controller.ts# Dedicated Admin Login & Me handler
│   │   ├── admin.controller.ts     # Pandit KYC & system stats handlers
│   │   ├── consultations.controller.ts # Consultation desk operations
│   │   ├── kundli_orders.controller.ts # Kundli fulfillment operations
│   │   ├── payments.controller.ts  # Razorpay order & raw webhook handlers
│   │   └── ...
│   ├── db/                         # Database schema & migrations
│   │   ├── index.ts                # Drizzle ORM client initialization
│   │   ├── provision_admin.ts      # Protected Admin provisioning CLI
│   │   ├── schema/                 # 22 PostgreSQL Table Schemas
│   │   └── verify_staging_db.ts    # Neon DB live health inspector
│   ├── middleware/                 # Auth, RBAC, Rate Limiting, Async Handler
│   ├── routes/                     # Express Router mounts
│   ├── services/                   # Business logic engines
│   │   ├── admin.service.ts        # Admin aggregations
│   │   ├── consultations.service.ts# Consultation persistence
│   │   ├── kundli_orders.service.ts# Kundli persistence
│   │   ├── jwt.service.ts          # Token signing & decoding
│   │   ├── sms.service.ts          # Fast2SMS Bulk V2 client
│   │   └── ...
│   ├── tests/                      # 24 Test Suites (273 Passing Tests)
│   ├── types/                      # TypeScript definitions
│   ├── utils/                      # Password hashing, logger, response wrappers
│   └── validators/                 # Zod request body & query schemas
│
└── docs/                           # Documentation Library
    ├── audits/                     # Historical audit documents
    ├── legacy/                     # Early specifications
    └── ...                         # Active architecture & release deliverables
```
