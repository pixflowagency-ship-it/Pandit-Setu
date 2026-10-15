import "dotenv/config";
import { sql } from "drizzle-orm";
import { db } from "../index.js";

async function runMigration() {
  console.log("Applying Migration 0008: Pandit Onboarding & Document Verification Schema...");

  await db.execute(sql`
    ALTER TABLE "pandits"
      ADD COLUMN IF NOT EXISTS "verification_stage" varchar(50) DEFAULT 'STAGE_1_COMPLETE' NOT NULL,
      ADD COLUMN IF NOT EXISTS "rejection_reason" text,
      ADD COLUMN IF NOT EXISTS "video_call_status" varchar(50) DEFAULT 'PENDING' NOT NULL,
      ADD COLUMN IF NOT EXISTS "video_scheduled_at" timestamp with time zone,
      ADD COLUMN IF NOT EXISTS "video_call_room_id" text,
      ADD COLUMN IF NOT EXISTS "video_verifier_id" uuid,
      ADD COLUMN IF NOT EXISTS "video_verifier_notes" text,
      ADD COLUMN IF NOT EXISTS "approved_at" timestamp with time zone,
      ADD COLUMN IF NOT EXISTS "approved_by" uuid;
  `);

  await db.execute(sql`
    ALTER TABLE "pandit_documents"
      ADD COLUMN IF NOT EXISTS "doc_number" varchar(100),
      ADD COLUMN IF NOT EXISTS "file_name" varchar(255),
      ADD COLUMN IF NOT EXISTS "file_size" integer,
      ADD COLUMN IF NOT EXISTS "mime_type" varchar(100),
      ADD COLUMN IF NOT EXISTS "rejection_reason" text;
  `);

  console.log("✅ Migration 0008 applied successfully!");
  process.exit(0);
}

runMigration().catch((err) => {
  console.error("Migration 0008 failed:", err);
  process.exit(1);
});
