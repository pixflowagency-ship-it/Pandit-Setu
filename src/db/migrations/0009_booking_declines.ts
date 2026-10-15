import "dotenv/config";
import { sql } from "drizzle-orm";
import { db } from "../index.js";

async function runMigration() {
  console.log("Applying Migration 0009: Booking Declines Schema...");

  await db.execute(sql`
    CREATE TABLE IF NOT EXISTS "booking_declines" (
      "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
      "booking_id" uuid NOT NULL REFERENCES "bookings"("id") ON DELETE CASCADE,
      "pandit_id" uuid NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
      "reason" varchar(50) DEFAULT 'OTHER' NOT NULL,
      "notes" text,
      "created_at" timestamp with time zone DEFAULT now() NOT NULL
    );
  `);

  await db.execute(sql`
    CREATE UNIQUE INDEX IF NOT EXISTS "idx_booking_declines_booking_pandit" 
      ON "booking_declines" ("booking_id", "pandit_id");
  `);

  await db.execute(sql`
    CREATE INDEX IF NOT EXISTS "idx_booking_declines_booking_id" 
      ON "booking_declines" ("booking_id");
  `);

  await db.execute(sql`
    CREATE INDEX IF NOT EXISTS "idx_booking_declines_pandit_id" 
      ON "booking_declines" ("pandit_id");
  `);

  console.log("✅ Migration 0009 applied successfully!");
  process.exit(0);
}

runMigration().catch((err) => {
  console.error("Migration 0009 failed:", err);
  process.exit(1);
});
