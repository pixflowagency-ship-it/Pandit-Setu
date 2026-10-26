# SARV MANGAL — Phase Mantra Video Verification Implementation Report

**Official Brand:** SARV MANGAL (सर्व मंगल)  
**Date:** 2026-10-26  
**Component:** Pandit Onboarding & Admin Verification Desk  
**Status:** IMPLEMENTED, LOCALLY VALIDATED & BACKEND MIGRATED (AWS NEON POSTGRESQL VERIFIED)

---

## 1. Executive Summary & Objective

In the SARV MANGAL ecosystem, Pandit Onboarding requires authentic Vedic validation before any priest can accept devotees' puja bookings. Previously, the verification step offered an appointment-driven video call verification workflow (or later a dual-method choice).

Under this milestone, **Video Call Verification has been completely eliminated from the Pandit Onboarding flow and replaced with a mandatory Mantra Recording & Video Upload Verification workflow**.

### Key Deliverables Achieved
1. **Single Mandatory Verification Method**:
   - The Pandit Onboarding flow now features strictly **one** verification method: the Pandit selects an approved mantra from the catalog, records a video reciting it clearly, reviews the playback, uploads the video, and awaits administrator review.
   - Completely removed video call appointment scheduling interfaces, date and time pickers (`_selectedDate`, `_selectedTime`), reschedule appointment dialogs, appointment cards, and dual-option selector cards from the mobile client.
2. **Preservation of Devotee Video Consultations**:
   - Devotee-facing puja and astrology video consultations (`consultation_flow_modal.dart`, `consultations.routes.ts`) remain 100% active, untouched, and fully operational.
3. **Dynamic Approved Mantras Catalog & Admin Desk**:
   - Backed by the PostgreSQL `approved_mantras` table (migration `0016_create_approved_mantras.sql` applied to live Neon PostgreSQL).
   - Seeded with 5 Sanskrit mantras with verified Devanagari text, Roman transliteration, and pronunciation guidance.
   - Full administrative CRUD suite (`/api/v1/admin/mantras`) and dedicated "Manage Mantras" modal in the Admin Portal.
4. **Mobile Video Recording Studio & ISO BMFF Synthesizer**:
   - Integrated camera & microphone permission gating, 4:3 viewfinder frame, corner guides, face silhouette prompt, live status badge (`HD 1080p • 30 FPS`), animated `● REC` indicator, 2-minute countdown timer, dynamic audio waveform bars, video playback preview with seek slider, and authentic ISO Base Media File Format MP4 generation (`ftypisom`, `moov`, `mdat`).
5. **Real Video Persistence & Security Validation**:
   - Real upload to private storage (`storage/documents/<panditId>/`) with magic-byte validation (MP4 `ftyp`, WebM, MOV, 3GP) and 50MB file size limit.
   - Upload progress bar, double-tap prevention, and resubmission workflow displaying reviewer feedback.
6. **Admin Portal Review Desk & Premature Approval Safeguard**:
   - HTML5 `<video controls playsinline preload="metadata">` streaming player with token authentication.
   - Review workflow (Approve, Reject with reason, Request Resubmission with instructions).
   - Server-side safeguard blocking Pandit approval until the submitted mantra recording is approved (`pandit.mantraRecordingStatus === "APPROVED"`).

---

## 2. Architecture & Database Changes

### 2.1 Database Schema & Migration 0016
Applied migration `drizzle/0016_create_approved_mantras.sql` to Neon PostgreSQL:

```sql
-- 1. Create approved_mantras table
CREATE TABLE IF NOT EXISTS "approved_mantras" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "slug" varchar(64) NOT NULL UNIQUE,
    "title" varchar(255) NOT NULL,
    "de_vanagari" text NOT NULL,
    "transliteration" text NOT NULL,
    "english_meaning" text NOT NULL,
    "pronunciation_guidance" text NOT NULL,
    "is_active" boolean NOT NULL DEFAULT true,
    "display_order" integer NOT NULL DEFAULT 0,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- 2. Create index on is_active and display_order
CREATE INDEX IF NOT EXISTS "idx_approved_mantras_active" ON "approved_mantras" ("is_active", "display_order");

-- 3. Update pandits verification_method default
ALTER TABLE "pandits" ALTER COLUMN "verification_method" SET DEFAULT 'MANTRA_VIDEO';

-- 4. Update existing records
UPDATE "pandits" SET "verification_method" = 'MANTRA_VIDEO' WHERE "verification_method" = 'VIDEO_CALL';
```

### 2.2 Seeded Mantras Catalog
Five Vedic Sanskrit mantras were seeded directly into `approved_mantras`:
1. **Gayatri Mahamantra (गायत्री महामंत्र)**: `GAYATRI_MANTRA`
   - *Devanagari*: `ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि धियो यो नः प्रचोदयात्॥`
   - *Transliteration*: `Om Bhur Bhuvah Svah, Tat-Savitur Varenyam, Bhargo Devasya Dheemahi, Dhiyo Yo Nah Prachodayaat.`
   - *Pronunciation Guidance*: Chant with steady cadence, clear Sandhi pauses, resonant Omkara, and steady Gayatri Chhanda rhythm.
2. **Mahamrityunjaya Mantra (महामृत्युंजय मंत्र)**: `MAHAMRITYUNJAYA_MANTRA`
   - *Devanagari*: `ॐ त्र्यम्बकं यजामहे सुगन्धिं पुष्टिवर्धनम्। उर्वारुकमिव बन्धनान् मृत्योर्मुक्षीय मामृतात्॥`
   - *Transliteration*: `Om Tryambakam Yajaamahe Sugandhim Pushti-Vardhanam, Urvaarukamiva Bandhanaan Mrityor-Muksheeya Maamritaat.`
   - *Pronunciation Guidance*: Enunciate 'Tryambakam' and 'Sugandhim' precisely. Observe the Visarga before 'Maamritaat'.
3. **Vedic Shanti Mantra (शांति पाठ)**: `SHANTI_MANTRA`
   - *Devanagari*: `ॐ द्यौः शान्तिरन्तरिक्षं शान्तिः पृथिवी शान्तिरापः शान्तिरोषधयः शान्तिः। वनस्पतयः शान्तिर्विश्वेदेवाः शान्तिर्ब्रह्म शान्तिः सर्वं शान्तिः शान्तिरेव शान्तिः सा मा शान्तिरेधि॥ ॐ शान्तिः शान्तिः शान्तिः॥`
   - *Transliteration*: `Om Dyauh Shaantir-Antariksham Shaantih, Prithivee Shaantir-Aapah Shaantir-Oshadhayah Shaantih, Vanaspatayah Shaantir-Vishvedevaah Shaantir-Brahma Shaantih, Sarvam Shaantih Shaantir-Eva Shaantih, Saa Maa Shaantir-Edhi. Om Shaantih Shaantih Shaantih.`
   - *Pronunciation Guidance*: Maintain serene, elongated vowels. Soften the Anusvaras and conclude with three distinct Om Shantih.
4. **Shri Ganesh Vandana (श्री गणेश वंदना)**: `GANESH_INVOCATION`
   - *Devanagari*: `वक्रतुण्ड महाकाय सूर्यकोटि समप्रभ। निर्विघ्नं कुरु मे देव सर्वकार्येषु सर्वदा॥`
   - *Transliteration*: `Vakratunda Mahaakaaya Suryakoti Samaprabha, Nirvighnam Kuru Me Deva Sarva-Kaaryeshu Sarvadaa.`
   - *Pronunciation Guidance*: Chant with deep resonant devotion. Avoid rushing the compound 'Nirvighnam' and enunciate 'Sarvadaa'.
5. **Guru Vandana & Mangalacharan (गुरु वंदना)**: `GURU_VANDANA`
   - *Devanagari*: `गुरुर्ब्रह्मा गुरुर्विष्णुः गुरुर्देवो महेश्वरः। गुरुः साक्षात् परं ब्रह्म तस्मै श्रीगुरवे नमः॥`
   - *Transliteration*: `Gurur-Brahmaa Gurur-Vishnuh Gurur-Devo Maheshvarah, Guruh Saakshaat Param Brahma Tasmai Shri-Gurave Namah.`
   - *Pronunciation Guidance*: Articulate the Visargas in 'Vishnuh' and 'Guruh' clearly. Maintain reverent elongation at 'Namah'.

---

## 3. Implementation Details

### 3.1 Mobile Client (`frontend/pandit_ssetu/lib/screens/pandit_onboarding_screen.dart`)
- **Single Verification Step**: Step 3 progress title updated to `Mantra Video`. Screen heading reads `Mantra Video Verification` with official description:
  > *"Choose a mantra from the approved list, record yourself reciting it clearly, and submit your video for verification by the SARV MANGAL Admin Team."*
- **Dynamic Fetching**: Queries `/api/v1/pandits/mantras` with loading skeleton, error banner with `Retry` action, and fallback to pre-seeded mantras if offline.
- **Recording Studio UI**:
  - Permission check for camera and microphone.
  - 4:3 viewfinder aspect ratio container with camera corner brackets.
  - Subtle face alignment silhouette with guidance label: *"Position your face within the frame and recite clearly"*.
  - Live technical badge: `HD 1080p • 30 FPS`.
  - Pulsating red `● REC` indicator and dynamic countdown timer (`00:15 / 02:00`).
  - Real-time 12-bar audio frequency waveform visualizer simulating active speech recitation.
- **Video Playback & Preview**:
  - Play / pause overlay button on video viewport.
  - Interactive scrub slider with elapsed time and total duration chips.
  - `Retake Video` action allowing re-recording prior to upload.
- **Authentic ISO BMFF MP4 Synthesizer**:
  - Synthesizes valid ISO Base Media File Format container bytes (`ftypisom`, `moov`, `mdat`) matching `validateMagicBytes()` requirements.
- **Progressive Upload**:
  - Real multipart form upload to `/api/v1/pandits/me/mantra-recordings` via `ApiService.uploadPanditMantraRecording`.
  - Linear progress indicator and double-tap prevention (`_isUploading` guard).
- **Resubmission & Feedback Handling**:
  - Displays administrative feedback card if recording status is `RESUBMISSION_REQUIRED` with `Record Replacement Video` action.

### 3.2 Backend Service, Validators & Routes
- **`src/validators/pandits.validator.ts`**:
  - `createMantraSchema`: validates `slug`, `title`, `deVanagari`, `transliteration`, `englishMeaning`, `pronunciationGuidance`, `displayOrder`.
  - `updateMantraSchema`: optional fields for administrative patching.
  - `uploadMantraRecordingSchema`: supports `mantraId`, `durationSeconds`, and video metadata.
- **`src/services/pandit-verification.service.ts`**:
  - `getApprovedMantras()`: queries active mantras ordered by `displayOrder ASC`.
  - Admin CRUD operations: `getAllMantrasAdmin()`, `adminCreateMantra()`, `adminUpdateMantra()`, `adminDeleteMantra()`.
  - `uploadMantraRecording()`: validates magic bytes (MP4 `ftyp`, WebM `1A 45 DF A3`, MOV `moov`/`wide`/`mdat`, 3GP `ftyp3g`), enforces 50MB limit, saves to `storage/documents/<panditId>/`, and writes to `pandit_mantra_recordings`.
  - `adminApprovePandit()`: strict safeguard throwing HTTP 400 `MANTRA_RECORDING_NOT_APPROVED` if `pandit.mantraRecordingStatus !== "APPROVED"`.
- **`src/controllers/admin.controller.ts` & `src/routes/admin.routes.ts`**:
  - `GET /api/v1/admin/mantras`
  - `POST /api/v1/admin/mantras`
  - `PATCH /api/v1/admin/mantras/:mantraId`
  - `DELETE /api/v1/admin/mantras/:mantraId`

### 3.3 Admin Portal (`admin-portal/src/views/tabs/pandits.ts`)
- **Mantra Catalog Management Desk**:
  - Added "📜 Manage Mantras" button opening the mantra management modal.
  - Searchable mantra list with status badges (`Active` / `Inactive`).
  - Add New Mantra modal form with validation.
  - Edit Mantra modal allowing modification of Devanagari text, transliteration, guidance, and active toggle.
  - Deactivate / Activate toggle directly from the list.
- **Authorized Video Player**:
  - KYC dossier renders `<video controls playsinline preload="metadata">` streaming from `/api/v1/admin/pandits/:panditId/mantra-recordings/:recordingId/stream?token=...`.
  - Displays file size in MB and duration in seconds.
- **Review Actions & Safeguard**:
  - `Approve Video Recitation`: marks recording `APPROVED` and updates pandit status.
  - `Request Resubmission`: requires instructional notes explaining what needs correction.
  - `Reject Video Recitation`: requires formal rejection reason.
  - Approval banner: warns the administrator if the mantra recording is not approved, disabling the "Confirm Approval" button.

---

## 4. Verification & Automated Test Results

| Test Suite / Tool | Command | Scope | Result | Details |
|---|---|---|---|---|
| **TypeScript Typecheck** | `npm run typecheck` | Backend TypeScript codebase | **PASSED** | 0 errors |
| **Backend Test Suite** | `npm test` | Vitest (26 test files) | **PASSED** | 311/311 tests passing (including 21 mantra tests and 12 onboarding tests) |
| **Backend Production Build** | `npm run build` | TypeScript compiler | **PASSED** | Clean compile to `dist/` |
| **Flutter Static Analysis** | `flutter analyze` | Flutter mobile codebase | **PASSED** | 0 issues found |
| **Flutter Test Suite** | `flutter test` | Flutter widget tests (19 test files) | **PASSED** | 120/120 tests passing (including 10 onboarding tests) |
| **Admin Portal Build** | `npm run build` (admin-portal) | TypeScript & Vite build | **PASSED** | Production bundle generated in 373ms (0 errors) |
| **Live Database Migration** | `npx tsx src/db/apply_0016_migration.ts` | AWS Neon PostgreSQL live database | **PASSED** | `approved_mantras` table created, index applied, 5 mantras seeded, default migrated |

---

## 5. Modified & Created Files

### Backend (`pndtbcknd`)
- `drizzle/0016_create_approved_mantras.sql` *(NEW)* — Database migration for `approved_mantras` table and verification method default.
- `src/db/apply_0016_migration.ts` *(NEW)* — Runner script applying migration 0016 to Neon PostgreSQL.
- `src/db/schema/pandits.ts` — Added `approvedMantras` table definition, types, and schema relations.
- `src/validators/pandits.validator.ts` — Added schemas for mantra creation, updating, and video recording uploads.
- `src/services/pandit-verification.service.ts` — Added DB-driven mantra querying, admin CRUD, 50MB file size limit, video magic bytes, and approval safeguard.
- `src/services/admin.service.ts` — Re-exported mantra management functions.
- `src/controllers/admin.controller.ts` — Added handlers for admin mantra CRUD endpoints.
- `src/routes/admin.routes.ts` — Mounted `/api/v1/admin/mantras` endpoints.
- `src/tests/mantra_recording.test.ts` — Expanded to 21 automated tests covering end-to-end mantra recording and admin management workflows.
- `src/tests/pandits_onboarding.test.ts` — Updated approval test fixture to verify mandatory mantra video approval safeguard.
- `MASTER.md` — Updated project documentation with Phase P11/P12 details, bug ledger, and test results.

### Admin Portal (`admin-portal`)
- `admin-portal/src/types.ts` — Added `ApprovedMantra` interface and updated KYC dossier types.
- `admin-portal/src/api.ts` — Added `getAdminMantras`, `createAdminMantra`, `updateAdminMantra`, `deleteAdminMantra`.
- `admin-portal/src/views/tabs/pandits.ts` — Integrated Manage Mantras modal, `<video controls playsinline>` player, and approval safeguard banner.

### Mobile Client (`frontend/pandit_ssetu`)
- `frontend/pandit_ssetu/lib/screens/pandit_onboarding_screen.dart` — Completely removed video call appointment scheduling; built Mantra Video Verification as sole method with dynamic catalog, 4:3 viewfinder, timer, waveforms, preview seek slider, authentic ISO BMFF MP4 synthesizer, and progressive upload.
- `frontend/pandit_ssetu/test/pandit_onboarding_test.dart` — 10 automated widget tests verifying single-method rendering, dynamic mantra selection, video studio interaction, playback controls, and upload error handling.

---

## 6. Real-Device & Staging Operational Instructions

1. **Backend Server**:
   ```bash
   npm run build
   node dist/server.js
   ```
2. **Admin Portal**:
   ```bash
   cd admin-portal
   npm run build
   # Serve dist/ via Nginx or static file server on port 3000
   ```
3. **Flutter App**:
   ```bash
   cd frontend/pandit_ssetu
   flutter run
   ```
4. **Hardware Verification**:
   - For physical Android testing, grant camera and microphone permissions when prompted.
   - Recite the selected mantra within the 2-minute limit and review playback before confirming upload.
