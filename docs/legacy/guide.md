C

You are the lead software architect and senior full-stack engineer responsible for taking the existing Sarvmangal / Pandit Setu project from its current partially connected state to a production-ready application.

I have attached three reference documents:

1. Application Discovery Report
2. Backend Audit Report
3. Services + UI Gap Analysis / Cost-Efficient Stack Report

These documents are the source of truth for the current project state and requirements.

---

1. MOST IMPORTANT RULE

DO NOT REWRITE THE EXISTING BACKEND FROM SCRATCH.

Do not migrate the backend to Python/FastAPI, NestJS, Firebase-only architecture, or any other stack.

The existing backend is built with:

- Node.js
- TypeScript
- Express
- PostgreSQL
- PostGIS
- Drizzle ORM
- Redis
- Socket.IO
- Razorpay
- Firebase Admin
- Agora token generation

The existing architecture is already layered:

"Routes → Middleware → Controllers → Services → Database"

Preserve this architecture unless there is a strong technical reason to change a specific component.

The goal is:

AUDIT → FIX → CONNECT → COMPLETE → HARDEN → TEST → PRODUCTION READY

not:

DELETE → REWRITE → REBUILD

---

2. FIRST: FULL PROJECT INSPECTION

Before modifying code, inspect the COMPLETE repository.

Inspect:

- Backend
- Flutter frontend
- Database schemas
- Drizzle migrations
- API routes
- Controllers
- Services
- Middleware
- Validators
- Authentication
- Payments
- Redis
- Socket.IO
- Firebase
- Agora
- File uploads
- Tests
- Environment configuration
- Flutter API service
- All screens
- All widgets
- Local JSON/mock data
- SharedPreferences/local storage
- Navigation
- Error handling

Do not assume that the reports are 100% correct.

Verify every important claim against the actual repository.

Create an internal implementation matrix:

Feature| UI| Backend| Database| External Service| Connected| Production Ready

Mark every feature as:

- READY
- PARTIAL
- BROKEN
- MOCK
- MISSING

Do not duplicate functionality that already exists.

---

3. PRESERVE EXISTING FUNCTIONALITY

Before changing a working component:

1. Understand how it works.
2. Identify its dependencies.
3. Identify what consumes it.
4. Make the smallest safe change required.
5. Run tests/typecheck/build afterward.

Do not remove working APIs simply because another implementation looks cleaner.

Do not rename routes unnecessarily.

Do not change database tables unnecessarily.

Do not introduce unnecessary dependencies.

Do not create duplicate services for functionality that already exists.

---

4. PRIMARY OBJECTIVE

The final system must allow a real user to use the application without fake success states.

No important user action should appear successful while only saving data locally.

Remove or replace production-critical:

- hardcoded data
- mock OTP
- dummy bookings
- fake Pandits
- fake payment success
- fake tracking
- fake notifications
- fake Meet links
- fake AI responses
- simulated Pandit dashboard actions
- local-only booking history
- local-only product catalogue

If a feature is not yet implemented, expose a clear controlled state instead of pretending it worked.

---

5. FIRST PRIORITY — FLUTTER ↔ BACKEND CONNECTION

Fix the existing integration before building new features.

API BASE URL

Remove the hardcoded:

"http://localhost:5000/api/v1"

Implement environment/config based API configuration suitable for:

- local development
- Android emulator
- physical Android device
- production server

Do not hardcode production URLs inside source code.

---

6. FIX KNOWN API MISMATCHES

PROFILE

Flutter currently calls:

"GET /auth/profile"

Backend provides:

"GET /users/me"

Make Flutter use the actual backend contract.

Profile update must also persist to the backend.

Do not use only in-memory UserData.

---

BOOKING

Flutter currently sends a payload similar to:

"poojaId, bookingDate, bookingTime, bookingType, address, totalAmount"

The backend expects fields according to its validated booking schema, including:

"poojaId"
"date"
"time"
"location"
"latitude"
"longitude"
"materialsIncluded"

Update the Flutter request model and backend integration correctly.

Do not weaken validation just to make the old Flutter payload pass.

The database booking must be the source of truth.

---

NEARBY PANDITS

Flutter must provide the required:

- latitude
- longitude
- radius

to the backend.

Remove the hardcoded fallback Pandit list.

Use the real PostGIS nearby search.

---

7. REMOVE FALSE SUCCESS FALLBACKS

This is extremely important.

If an API fails:

DO NOT silently save a fake booking to SharedPreferences.

DO NOT show a fake successful payment.

DO NOT display a fake Pandit.

DO NOT create fake booking history.

DO NOT hide backend errors.

Instead:

- show a proper user-friendly error
- log the technical error
- preserve retry capability
- keep the backend/database as the source of truth

SharedPreferences may be used for appropriate client-side caching/session information, but NOT as a replacement for backend business data.

---

8. YAJMAN AUTHENTICATION

Make the complete authentication flow production-ready.

Current system uses:

Mobile number → OTP → JWT

Keep this architecture.

Implement:

- real SMS OTP provider abstraction
- OTP expiration
- rate limiting
- resend limits
- abuse protection
- secure OTP handling
- Redis-backed OTP storage where appropriate
- JWT validation
- proper logout/session handling
- refresh-token strategy if appropriate
- role-based access control

Development OTP bypass must never be active in production.

Never return "mockOtp" in production.

---

9. PUJA SYSTEM

Make the existing Puja system fully functional.

Puja catalogue

Flutter must load the real catalogue from:

"GET /api/v1/poojas"

Do not use hardcoded Puja lists.

Puja detail screen must load actual backend data.

---

Offline Puja

Support:

- Puja selection
- Date
- Time
- User location
- Address
- Latitude
- Longitude
- Samagri selection
- Manual Pandit selection
- Automatic Pandit assignment
- Price calculation
- Booking creation
- Payment
- Booking confirmation
- Booking history
- Pandit assignment
- Notifications
- Status updates

---

Online Puja

Support:

- Puja selection
- Date/time
- Online session
- Payment
- Pandit assignment
- Video session lifecycle
- Session status
- Notifications
- Completion

Use the existing Agora infrastructure where appropriate.

Do not introduce another video provider unnecessarily.

---

10. PANDIT SYSTEM

Make the Pandit application real rather than simulated.

Implement:

Authentication

- Phone number
- OTP
- JWT
- Secure session

Registration

- Name
- City
- Experience
- Languages
- Specialization
- Profile information

Verification

Support:

- ID proof
- Address proof
- Certificates/documents
- Profile information
- 30-second introduction video
- Verification status

Statuses:

- pending
- approved/verified
- rejected

Do not allow an unverified Pandit to accept production bookings unless the business rules explicitly allow it.

---

11. PANDIT AVAILABILITY

The Pandit dashboard must communicate with the backend.

The online/offline switch must update the backend.

Do not use:

"_isOnline = !_isOnline"

as the final implementation.

Use the backend availability state.

---

12. BOOKING ASSIGNMENT

Implement the real booking lifecycle.

Possible flow:

Yajman creates booking

↓

Payment confirmation

↓

Manual Pandit selected
OR
Automatic assignment requested

↓

Nearby eligible Pandits identified

↓

Booking request sent

↓

Pandit accepts/rejects

↓

Booking assigned

↓

Yajman notified

↓

Pandit performs service

↓

Status updated

↓

Service completed

↓

Payment/earning finalized

Use Socket.IO and/or FCM where appropriate.

Do not rely on timers or fake 30-second simulations.

---

13. AUTOMATIC PANDIT ASSIGNMENT

The backend already has PostGIS nearby-Pandit capability.

Build proper assignment logic around it.

Consider:

- distance
- availability
- verification status
- service compatibility
- current workload
- booking time
- acceptance/rejection
- timeout
- retry with next eligible Pandit

Avoid race conditions where two Pandits accept the same booking.

Use database transactions/locking where appropriate.

---

14. PAYMENTS

Use the existing Razorpay backend implementation.

Complete the Flutter integration.

Flow should be:

1. Create booking/order as appropriate.
2. Create Razorpay order.
3. Open Razorpay checkout.
4. Receive payment response.
5. Verify payment server-side.
6. Process webhook.
7. Update database payment status.
8. Notify user.
9. Only then show appropriate confirmation.

Never trust payment status supplied only by Flutter.

Do not create fake payment-success states.

---

15. NOTIFICATIONS

Complete Firebase Cloud Messaging integration.

Backend already has Firebase Admin capability.

Implement Flutter:

- firebase_core
- firebase_messaging
- device token registration
- token refresh
- notification handling
- foreground notification handling
- background notification handling
- notification navigation

Use notifications for:

- OTP where applicable
- booking creation
- Pandit assignment
- booking acceptance
- booking rejection
- reminders
- payment updates
- consultation updates
- service completion

---

16. SOCKET.IO

The backend already uses Socket.IO.

Connect the Flutter client properly.

Use real-time events for appropriate features such as:

- booking request
- Pandit acceptance
- booking status
- live service status
- tracking updates

Do not create fake timers to simulate real-time events.

---

17. CONSULTATION SYSTEM

The current UI contains consultation flows but backend support is missing.

Implement proper backend architecture for:

Online consultation

- immediate consultation
- scheduled consultation
- 15 min
- 30 min
- 60 min
- pricing
- Pandit availability
- Pandit assignment
- payment
- call/video session
- session status
- completion

Offline consultation

Support:

- Sarvmangal office
- user's location

Do not generate fake Google Meet links.

If Google Meet is selected, implement a proper integration.

If Agora is selected, use the existing Agora architecture.

Choose the simplest reliable production approach based on the existing project architecture.

---

18. HANDMADE KUNDLI

The UI currently simulates this service.

Create the necessary backend/database workflow.

Support:

- customer birth details
- DOB
- time
- place
- order
- payment
- admin assignment
- Pandit processing
- order status
- delivery/upload
- customer access/download

Do not fake the admin assignment.

---

19. PHOOL MALA

Connect the existing Flutter screen to the backend subscription system.

Support:

- daily
- weekly/monthly as defined by product requirements
- subscription creation
- payment
- subscription status
- cancellation where appropriate
- order history

Do not show only a dialog saying subscription was successful.

---

20. POoja STORE

Replace local:

"products.json"

as the production source.

Use:

"GET /api/v1/products"

Implement the real e-commerce flow:

- product list
- product detail
- cart
- quantity
- checkout
- order
- payment
- stock
- order status
- delivery status

Do not consider "_cartCount++" a real cart.

---

21. TEMPLE FEATURE

Connect Flutter to the existing:

"GET /api/v1/temples/nearby"

Use actual device coordinates.

Do not use hardcoded Ujjain temples as the production result.

---

22. AI SPIRITUAL CHAT

The current AI chat is only local keyword matching.

Replace this with a secure backend AI architecture.

Important:

Never expose an AI API key inside Flutter.

The flow should be:

Flutter → Backend → AI provider → Backend → Flutter

Implement:

- conversation handling
- authentication
- rate limits
- usage limits
- message limits
- abuse protection
- cost controls
- configurable free/paid limits

Use an abstraction layer so the AI provider can be changed later.

---

23. ADMIN SYSTEM

An actual Admin Portal is required.

The discovery report explicitly identifies the Admin Portal as missing.

Build an admin web interface/API layer capable of managing:

Users

- Yajmans
- Pandits
- admins

Pandits

- applications
- documents
- verification
- approval/rejection
- services
- availability

Poojas

- create
- edit
- delete/deactivate
- price
- duration
- materials
- categories

Bookings

- view
- assign Pandit
- reassign
- status
- payment status
- cancellation
- history

Products

- catalogue
- stock
- price
- active/inactive

Flowers/subscriptions

- subscriptions
- status
- orders

Handmade Kundli

- orders
- Pandit assignment
- status
- delivery

Consultations

- assignments
- schedules
- status

Banners/Ads

- create
- edit
- activate/deactivate

Payments

- transactions
- payment status
- refunds where applicable

Analytics

- bookings
- revenue
- Pandits
- customers
- services

Protect every admin API with proper RBAC.

---

24. DATABASE

Do not casually modify the database.

Before adding a table:

1. Check whether the functionality already has a suitable table.
2. Reuse existing relationships where possible.
3. Add normalized tables only when required.
4. Create proper Drizzle migrations.
5. Add indexes.
6. Add foreign keys.
7. Add constraints.
8. Consider transaction boundaries.
9. Never manually modify production schema without migrations.

Every schema change must have:

- migration
- updated Drizzle schema
- validation
- tests

---

25. FILE STORAGE

Current file uploads use local disk.

That is not reliable for cloud production.

Create a storage abstraction.

Recommended architecture:

"FileStorageService"

with provider implementation such as:

- Cloudinary
- AWS S3
- Google Cloud Storage

Do not hardcode the provider throughout the application.

Files include:

- Pandit documents
- profile images
- introduction videos
- Kundli documents
- product images

---

26. REDIS

Use Redis appropriately for:

- OTP storage
- rate limiting where useful
- temporary assignment state
- caching
- Socket.IO adapter
- short-lived distributed state

Do not store critical permanent business data only in Redis.

---

27. SECURITY HARDENING

Perform a complete security pass.

Check:

- JWT security
- RBAC
- input validation
- Zod validation
- SQL injection protection
- rate limiting
- OTP abuse
- CORS
- Helmet
- file upload validation
- MIME validation
- file size limits
- path traversal
- webhook signature validation
- payment verification
- secret management
- API error leakage
- logging of sensitive information
- production environment configuration

Never log:

- OTPs
- JWTs
- payment secrets
- API keys
- passwords
- private credentials

Development-only debugging must be disabled in production.

---

28. ERROR HANDLING

Every API must have consistent error responses.

Use the existing error architecture.

Errors should contain useful information for the client without leaking internal implementation details.

Flutter must handle:

- 400
- 401
- 403
- 404
- 409
- 422
- 429
- 500
- network timeout
- connection failure

Do not silently swallow errors.

---

29. TESTING

Do not claim the backend is production-ready without testing it.

Implement/run:

Backend

- unit tests
- service tests
- controller tests
- integration tests
- authentication tests
- authorization tests
- booking tests
- payment verification tests
- Pandit assignment tests
- subscription tests
- validation tests

API

Test every important endpoint.

Flutter

At minimum verify:

- authentication
- profile
- Puja list
- booking
- Pandit selection
- payment
- booking history
- Pandit dashboard
- notifications

---

30. PRODUCTION CONFIGURATION

Create proper environment configuration.

Separate:

Development

Staging

Production

Never commit secrets.

Provide/update:

".env.example"

with required variables clearly documented.

---

31. LOGGING & OBSERVABILITY

Implement useful structured logging.

Log:

- request ID
- important business events
- errors
- payment events
- booking lifecycle
- Pandit assignment events

Do not log sensitive information.

---

32. API DOCUMENTATION

Document the production API.

For every endpoint include:

- method
- URL
- authentication
- role
- request body
- query parameters
- response
- errors

Prefer OpenAPI/Swagger if practical.

---

33. PERFORMANCE

Review:

- database indexes
- PostGIS queries
- N+1 queries
- pagination
- Redis caching
- API response sizes
- unnecessary Flutter network requests
- image sizes
- file uploads
- concurrent booking assignment

Do not optimize blindly.

Measure or reason from actual code.

---

34. DO NOT OVERENGINEER

Use the simplest production-ready solution.

Do not add expensive services unnecessarily.

Prefer existing infrastructure.

Current stack should remain the foundation.

For example:

- Existing PostgreSQL → keep
- Existing PostGIS → keep
- Existing Redis → keep
- Existing Socket.IO → keep
- Existing Razorpay → keep
- Existing Firebase Admin → keep
- Existing Agora → use where appropriate
- Existing Express architecture → keep

Do not introduce a new framework merely for style.

---

35. IMPLEMENTATION ORDER

Work in this order.

PHASE 0 — AUDIT

Inspect everything.

Produce:

- current architecture
- broken integrations
- missing features
- duplicate features
- risk list
- dependency list

Do not make destructive changes.

---

PHASE 1 — FOUNDATION

Fix:

- environment configuration
- API base URL
- authentication
- JWT
- OTP architecture
- error handling
- logging
- validation
- security basics
- Flutter API client

---

PHASE 2 — CORE PUJA BOOKING

Complete:

- Pooja catalogue
- details
- booking
- date/time
- location
- samagri
- manual Pandit
- nearby Pandit
- automatic assignment
- payment
- booking history
- notifications

This phase is the highest priority.

---

PHASE 3 — REAL PANDIT PLATFORM

Complete:

- Pandit authentication
- registration
- verification
- documents
- profile
- availability
- booking requests
- accept/reject
- service lifecycle
- earnings
- notifications

---

PHASE 4 — ONLINE SERVICES

Complete:

- online Puja
- Agora/session lifecycle
- consultation
- immediate consultation
- scheduled consultation
- duration pricing
- call/video

---

PHASE 5 — ADDITIONAL SERVICES

Complete:

- Handmade Kundli
- Phool Mala
- Pooja Store
- cart/order
- delivery
- temple discovery
- notifications

---

PHASE 6 — ADMIN PORTAL

Build the complete admin system.

---

PHASE 7 — AI

Implement the secure backend AI service.

---

PHASE 8 — PRODUCTION HARDENING

Perform:

- security audit
- performance audit
- test coverage
- migration verification
- environment verification
- deployment configuration
- logging
- monitoring
- backup strategy
- failure handling

---

36. IMPORTANT DEVELOPMENT RULE

After each phase:

1. Run TypeScript typecheck.
2. Run backend tests.
3. Run build.
4. Check database migrations.
5. Check Flutter analysis.
6. Check Flutter build where possible.
7. Test affected API endpoints.
8. Review changed files.
9. Fix regressions.
10. Only then move to the next phase.

Never make hundreds of uncontrolled changes and only test at the end.

---

37. KEEP A CHANGELOG

Maintain:

"IMPLEMENTATION_PROGRESS.md"

For every completed task record:

- Feature
- Files changed
- Database changes
- API changes
- Flutter changes
- Tests performed
- Result
- Remaining issues

Also maintain:

"KNOWN_ISSUES.md"

for anything that cannot yet be completed.

---

38. DEFINITION OF DONE

A feature is NOT considered complete merely because:

- the UI exists
- an API exists
- the database table exists
- a button works
- a timer runs
- a mock response appears

A feature is complete only when the complete flow works:

Flutter UI → API → Validation → Business Logic → Database → External Service if required → Response → Flutter state → User-visible result

and appropriate tests pass.

---

39. FINAL PRODUCTION-READY CHECKLIST

Before declaring the backend production-ready, verify:

- [ ] No production mock OTP
- [ ] No hardcoded API URL
- [ ] No fake bookings
- [ ] No fake Pandit data
- [ ] No fake payment success
- [ ] No fake tracking
- [ ] No fake notification list
- [ ] No simulated Pandit dashboard
- [ ] No local-only business data
- [ ] Real authentication
- [ ] Real authorization
- [ ] Real database persistence
- [ ] Real booking lifecycle
- [ ] Real Pandit assignment
- [ ] Real payment verification
- [ ] Real notifications
- [ ] Real file storage
- [ ] Proper Redis usage
- [ ] Proper Socket.IO connection
- [ ] Proper Flutter/backend API contracts
- [ ] Admin system
- [ ] Security hardening
- [ ] Database migrations
- [ ] Tests
- [ ] Production environment configuration
- [ ] Error handling
- [ ] Logging
- [ ] API documentation

---

40. FINAL INSTRUCTION

Do not stop after producing an audit.

Do not merely tell me what is wrong.

Actually implement the fixes in the repository.

However, do not blindly modify everything at once.

Work phase-by-phase.

Before each major architectural change, inspect the existing implementation and preserve compatible code.

When a requirement from the attached reports conflicts with the actual repository, verify the repository first and clearly document the discrepancy before choosing the implementation.

The final goal is:

Sarvmangal / Pandit Setu should become a real, connected, secure, scalable and production-ready application using the existing Node.js/TypeScript backend foundation and Flutter frontend—not a rewritten demo.

Start with PHASE 0 — FULL AUDIT, then proceed automatically through the phases as each phase passes its tests and acceptance criteria.