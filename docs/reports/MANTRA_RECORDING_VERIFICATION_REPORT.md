# SARV MANGAL — Mantra Recording Verification Implementation Report

**Official Brand:** SARV MANGAL (सर्व मंगल)  
**Date:** 2026-10-22  
**Component:** Pandit Onboarding & Verification Desk  
**Status:** IMPLEMENTED, LOCALLY VALIDATED & BACKEND MIGRATED (AWS NEON POSTGRESQL VERIFIED)

---

## 1. Executive Summary & Objective

In the SARV MANGAL ecosystem, Pandit Onboarding requires rigorous Vedic authentications. Previously, Step 3 (Verification) was exclusively based on an appointment-driven Video Call verification workflow.

This enhancement introduces **Mantra Recording Verification** as a fully supported, alternative verification path alongside **Video Call Verification**, without breaking or rebuilding the existing onboarding screen:
1. **Dual Verification-Method Selector**: Directly below the onboarding step progress indicator, Pandits can select between **Option A (Video Call)** and **Option B (Mantra Recording)**.
2. **Preservation of Existing Workflows**: The video call appointment details, date/time pickers, rescheduling flow, and application status checks remain intact and fully operational.
3. **Reviewed Sanskrit Mantra Prompts**: Configurable catalog of 5 Vedic Sanskrit mantras with verified Devanagari text, Roman transliteration, English meaning, and pronunciation guidance.
4. **Interactive Recording & Preview**: In-app recording with live pulsating duration indicator, animated waveform visualizer, stop/preview controls, audio scrub slider, retake capability, and upload with progress feedback.
5. **Real Server Upload & Persistence**: Audio files are verified using magic bytes (WAV, MP4/M4A, AAC, WebM, OGG), stored in private filesystem storage (`storage/documents/<panditId>/`), and persisted to the PostgreSQL database in the `pandit_mantra_recordings` table.
6. **Admin Portal KYC Desk Integration**: Authorized administrators can inspect submitted recordings, stream audio securely with query-token authentication, approve recitations, request resubmissions with specific pronunciation guidance notes, or reject with a formal reason.
7. **Human Review Safeguard**: A Pandit can never be automatically verified upon uploading; admin authorization is strictly blocked until a human reviewer approves the recitation.

---

## 2. Architecture & Database Changes

### 2.1 Database Schema & Migration

Applied migration `drizzle/0015_add_mantra_recordings.sql` to Neon live database:
- Added `verification_method` to `pandits` table: `varchar(50) NOT NULL DEFAULT 'VIDEO_CALL'` (`VIDEO_CALL` or `MANTRA_RECORDING`).
- Added `mantra_recording_status` to `pandits` table: `varchar(50) NOT NULL DEFAULT 'NOT_SUBMITTED'` (`NOT_SUBMITTED`, `PENDING`, `APPROVED`, `REJECTED`, `RESUBMISSION_REQUIRED`).
- Created `pandit_mantra_recordings` table:
  - `id` (UUID PK)
  - `pandit_id` (UUID FK -> `pandits.id` ON DELETE CASCADE)
  - `mantra_id` (varchar(64) NOT NULL)
  - `mantra_title` (varchar(255) NOT NULL)
  - `media_url` (varchar(512) NOT NULL)
  - `file_name` (varchar(255) NOT NULL)
  - `file_size` (integer NOT NULL)
  - `mime_type` (varchar(100) NOT NULL)
  - `duration_seconds` (integer NOT NULL DEFAULT 0)
  - `status` (varchar(50) NOT NULL DEFAULT 'PENDING')
  - `reviewer_id` (UUID FK -> `users.id`)
  - `reviewer_notes` (text)
  - `rejection_reason` (text)
  - `reviewed_at` (timestamp with time zone)
  - `created_at` (timestamp with time zone DEFAULT now())
  - `updated_at` (timestamp with time zone DEFAULT now())
  - Indexes: `idx_pandit_mantra_recordings_pandit_id`, `idx_pandit_mantra_recordings_status`.

### 2.2 Security & Storage Model
- **Private Storage**: Audio recordings are saved with randomized unique filenames (`mantra_<timestamp>_<hex>.<ext>`) with `0o600` permissions inside private directories (`storage/documents/<panditId>/`).
- **No Public URLs**: Direct URLs are never exposed. Media is streamed via authenticated endpoints:
  - Pandit: `GET /api/v1/pandits/me/mantra-recordings/:recordingId/stream` (enforces Pandit ownership).
  - Admin: `GET /api/v1/admin/pandits/:panditId/mantra-recordings/:recordingId/stream` (enforces `role: "ADMIN"`).
- **Streaming Authentication**: Express `verifyToken` middleware supports both `Bearer` authorization headers and `?token=` query parameters (for native HTML5 `<audio>` and mobile media elements).

---

## 3. Approved Sanskrit Mantras Catalog

The server exposes `GET /api/v1/pandits/mantras` providing reviewed mantras:

1. **Gayatri Mahamantra (गायत्री महामंत्र)**
   - **Sanskrit**: `ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि धियो यो नः प्रचोदयात्॥`
   - **Transliteration**: `Om Bhur Bhuvah Svah, Tat-Savitur Varenyam, Bhargo Devasya Dheemahi, Dhiyo Yo Nah Prachodayaat.`
   - **Pronunciation Guidance**: Clear Sandhi pauses, resonant Omkara, and steady Gayatri Chhanda cadence.
2. **Mahamrityunjaya Mantra (महामृत्युंजय मंत्र)**
   - **Sanskrit**: `ॐ त्र्यम्बकं यजामहे सुगन्धिं पुष्टिवर्धनम्। उर्वारुकमिव बन्धनान् मृत्योर्मुक्षीय मामृतात्॥`
   - **Transliteration**: `Om Tryambakam Yajaamahe Sugandhim Pushti-Vardhanam, Urvaarukamiva Bandhanaan Mrityor-Muksheeya Maamritaat.`
   - **Pronunciation Guidance**: Precise enunciation of 'Tryambakam' and the Visarga before 'Maamritaat'.
3. **Vedic Shanti Mantra (शांति पाठ)**
   - **Sanskrit**: `ॐ द्यौः शान्तिरन्तरिक्षं शान्तिः पृथिवी शान्तिरापः शान्तिरोषधयः शान्तिः। वनस्पतयः शान्तिर्विश्वेदेवाः शान्तिर्ब्रह्म शान्तिः सर्वं शान्तिः शान्तिरेव शान्तिः सा मा शान्तिरेधि॥ ॐ शान्तिः शान्तिः शान्तिः॥`
   - **Transliteration**: `Om Dyauh Shaantir-Antariksham Shaantih, Prithivee Shaantir-Aapah Shaantir-Oshadhayah Shaantih, Vanaspatayah Shaantir-Vishvedevaah Shaantir-Brahma Shaantih, Sarvam Shaantih Shaantir-Eva Shaantih, Saa Maa Shaantir-Edhi. Om Shaantih Shaantih Shaantih.`
   - **Pronunciation Guidance**: Serene rhythm, soft nasal consonants (Anusvara), and peaceful terminal Om.
4. **Shri Ganesh Vandana (श्री गणेश वंदना)**
   - **Sanskrit**: `वक्रतुण्ड महाकाय सूर्यकोटि समप्रभ। निर्विघ्नं कुरु मे देव सर्वकार्येषु सर्वदा॥`
   - **Transliteration**: `Vakratunda Mahaakaaya Suryakoti Samaprabha, Nirvighnam Kuru Me Deva Sarva-Kaaryeshu Sarvadaa.`
   - **Pronunciation Guidance**: Resonant, devotional cadence with respectful elongation of the final vowels.
5. **Guru Vandana & Mangalacharan (गुरु वंदना)**
   - **Sanskrit**: `गुरुर्ब्रह्मा गुरुर्विष्णुः गुरुर्देवो महेश्वरः। गुरुः साक्षात् परं ब्रह्म तस्मै श्रीगुरवे नमः॥`
   - **Transliteration**: `Gurur Brahmaa Gurur Vishnuh Gurur Devo Maheshwarah, Guruh Saakshaat Param Brahma Tasmai Shri Gurave Namah.`
   - **Pronunciation Guidance**: Pure Sanskrit tone emphasizing the reverence of the Guru-Shishya tradition.

---

## 4. Flutter Mobile Implementation

### 4.1 UI Workflow & Method Selection
In `frontend/pandit_ssetu/lib/screens/pandit_onboarding_screen.dart`:
- Progress bar step title dynamically displays **"Verification"** (handling both Video and Mantra).
- Top Selector Cards:
  - **Option A (Video Call)**: Video camera icon, orange theme, subtitle `5-minute live verification`.
  - **Option B (Mantra Recording)**: Microphone icon, orange theme, subtitle `Record a mantra for verification`.
- Selecting an option updates backend state via `PUT /api/v1/pandits/me/verification-method` without clearing appointment bookings or prior recordings.

### 4.2 Recording Interaction
- **Prompt Selection**: Cards displaying Sanskrit Devanagari text, transliteration, English meaning, and pronunciation guidance tags.
- **Recording State Machine**:
  - `Not Recording`: Big orange mic button `Start Recording`.
  - `Recording`: Animated pulsating ripple, live duration timer (`00:15 / 01:30`), real-time waveform bars, and `Stop Recording` button.
  - `Preview & Playback`: Play/Pause toggle, scrub slider, current time vs total time, `Retake` button, and `Submit for Verification` action.
  - `Uploading`: Linear progress bar with percentage indicator and double-tap prevention.
  - `Status Presentation`:
    - `PENDING`: Golden card showing "Recitation Under Review by SARV MANGAL team".
    - `APPROVED`: Emerald badge "Recitation Verified & Approved".
    - `RESUBMISSION_REQUIRED`: Warning banner displaying reviewer feedback notes and `Record New Recitation` button.
    - `REJECTED`: Red alert banner with rejection reason.

---

## 5. Admin Portal Integration

In `admin-portal/src/views/tabs/pandits.ts`:
- **Filter**: Added `Mantra Review Queue` chip to quickly filter Pandits with pending mantra recordings.
- **Table Badges**: Displays `Mantra Recording` or `Video Call` tag, plus status chip (`Recitation Pending`, `Recitation Approved`, `Resubmission Required`).
- **Dossier Section (Mantra Recitation Verification)**:
  - Mantra Title & Recitation timestamp.
  - Native HTML5 `<audio>` player with authorized stream URL.
  - Review Actions:
    - **Approve Recitation**: Confirms chanting accuracy; sets status to `APPROVED`.
    - **Request Resubmission**: Prompts admin for pronunciation feedback notes (e.g. *Enunciate Visarga clearly*), setting status to `RESUBMISSION_REQUIRED`.
    - **Reject Recitation**: Rejects submission with mandatory reason.
- **Safety Lock**: If a Pandit's verification method is `MANTRA_RECORDING`, the overall `Approve Application` button remains disabled and rejected by the server with HTTP 400 until the mantra recording status is `APPROVED`.

---

## 6. Automated Test Results

### 6.1 Backend Tests (`npm test`)
- **Suite**: `src/tests/mantra_recording.test.ts` (15/15 passed)
- **Suite**: `src/tests/pandits_onboarding.test.ts` (12/12 passed)
- **Total Backend Suites**: 26 passed (26)
- **Total Backend Tests**: 305 passed (305), 0 failed
- **TypeScript Check (`npm run typecheck`)**: Exit code 0
- **Production Build (`npm run build`)**: Exit code 0

### 6.2 Flutter Mobile Tests (`flutter test`)
- **Suite**: `test/pandit_onboarding_test.dart` (7/7 passed)
- **Total Flutter Suites**: 19 passed (19)
- **Total Flutter Tests**: 117 passed (117), 0 failed
- **Flutter Analyzer (`flutter analyze`)**: 0 issues found

### 6.3 Admin Portal Build
- `npm run build` in `admin-portal`: `tsc && vite build` built production bundle in 314ms with 0 errors.

---

## 7. Files Changed Summary

1. **Database**:
   - `drizzle/0015_add_mantra_recordings.sql`
   - `src/db/schema/pandits.ts`
   - `src/db/schema/relations.ts`
2. **Backend**:
   - `src/validators/pandits.validator.ts`
   - `src/services/pandit-verification.service.ts`
   - `src/controllers/pandits.controller.ts`
   - `src/routes/pandits.routes.ts`
   - `src/services/admin.service.ts`
   - `src/controllers/admin.controller.ts`
   - `src/routes/admin.routes.ts`
   - `src/middleware/verify-token.ts`
   - `src/tests/mantra_recording.test.ts`
3. **Admin Portal**:
   - `admin-portal/src/types.ts`
   - `admin-portal/src/api.ts`
   - `admin-portal/src/views/tabs/pandits.ts`
4. **Mobile Client**:
   - `frontend/pandit_ssetu/lib/services/api_service.dart`
   - `frontend/pandit_ssetu/lib/screens/pandit_onboarding_screen.dart`
   - `frontend/pandit_ssetu/test/pandit_onboarding_test.dart`
5. **Documentation**:
   - `MASTER.md`
   - `docs/MANTRA_RECORDING_VERIFICATION_REPORT.md`
