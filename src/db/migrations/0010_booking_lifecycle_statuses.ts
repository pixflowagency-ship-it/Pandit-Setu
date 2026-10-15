import "dotenv/config";
import { sql } from "drizzle-orm";
import { db } from "../index.js";

async function runMigration() {
  console.log("Applying Migration 0010: Booking Lifecycle Statuses...");

  await db.execute(sql`
    ALTER TYPE "public"."booking_status" ADD VALUE IF NOT EXISTS 'HEADING_TO_VENUE';
  `);
  await db.execute(sql`
    ALTER TYPE "public"."booking_status" ADD VALUE IF NOT EXISTS 'ARRIVED';
  `);
  await db.execute(sql`
    ALTER TYPE "public"."booking_status" ADD VALUE IF NOT EXISTS 'PUJA_STARTED';
  `);

  console.log("✅ Migration 0010 applied successfully!");
  process.exit(0);
}

runMigration().catch((err) => {
  console.error("Migration 0010 failed:", err);
  process.exit(1);
});
