ALTER TABLE "pandits" ADD COLUMN IF NOT EXISTS "verification_method" VARCHAR(50) DEFAULT 'VIDEO_CALL';
ALTER TABLE "pandits" ADD COLUMN IF NOT EXISTS "mantra_recording_status" VARCHAR(50) DEFAULT 'NOT_SUBMITTED';

CREATE TABLE IF NOT EXISTS "pandit_mantra_recordings" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "pandit_id" UUID NOT NULL REFERENCES "pandits"("id") ON DELETE CASCADE,
  "mantra_id" VARCHAR(50) NOT NULL,
  "mantra_title" VARCHAR(255) NOT NULL,
  "media_url" TEXT NOT NULL,
  "file_name" VARCHAR(255),
  "file_size" INTEGER,
  "mime_type" VARCHAR(100),
  "duration_seconds" INTEGER DEFAULT 0,
  "status" VARCHAR(50) NOT NULL DEFAULT 'PENDING',
  "rejection_reason" TEXT,
  "reviewer_id" UUID,
  "reviewer_notes" TEXT,
  "reviewed_at" TIMESTAMP WITH TIME ZONE,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS "idx_pandit_mantra_recordings_pandit_id" ON "pandit_mantra_recordings"("pandit_id");
