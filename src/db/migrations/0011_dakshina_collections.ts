import "dotenv/config";
import { sql } from "drizzle-orm";
import { db } from "../index.js";

async function runMigration() {
  console.log("Applying Migration 0011: Dakshina Collections Table...");

  await db.execute(sql`
    DO $$ BEGIN
      CREATE TYPE "public"."payment_status" AS ENUM('PENDING', 'PAID', 'FAILED');
    EXCEPTION
      WHEN duplicate_object THEN null;
    END $$;
  `);

  await db.execute(sql`
    CREATE TABLE IF NOT EXISTS "dakshina_collections" (
      "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
      "booking_id" uuid NOT NULL,
      "pandit_id" uuid NOT NULL,
      "amount" numeric(10, 2) NOT NULL,
      "currency" varchar(10) DEFAULT 'INR' NOT NULL,
      "payment_method" varchar(20) NOT NULL,
      "payment_status" "public"."payment_status" DEFAULT 'PENDING' NOT NULL,
      "razorpay_order_id" varchar(255),
      "razorpay_payment_id" varchar(255),
      "razorpay_signature" text,
      "collected_at" timestamp with time zone,
      "notes" text,
      "created_at" timestamp with time zone DEFAULT now() NOT NULL,
      "updated_at" timestamp with time zone DEFAULT now() NOT NULL
    );
  `);

  await db.execute(sql`
    DO $$ BEGIN
      ALTER TABLE "dakshina_collections" ADD CONSTRAINT "dakshina_collections_booking_id_bookings_id_fk" FOREIGN KEY ("booking_id") REFERENCES "public"."bookings"("id") ON DELETE cascade ON UPDATE no action;
    EXCEPTION
      WHEN duplicate_object THEN null;
    END $$;
  `);

  await db.execute(sql`
    DO $$ BEGIN
      ALTER TABLE "dakshina_collections" ADD CONSTRAINT "dakshina_collections_pandit_id_users_id_fk" FOREIGN KEY ("pandit_id") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;
    EXCEPTION
      WHEN duplicate_object THEN null;
    END $$;
  `);

  await db.execute(sql`
    CREATE INDEX IF NOT EXISTS "idx_dakshina_booking_id" ON "dakshina_collections" ("booking_id");
  `);
  await db.execute(sql`
    CREATE INDEX IF NOT EXISTS "idx_dakshina_pandit_id" ON "dakshina_collections" ("pandit_id");
  `);
  await db.execute(sql`
    CREATE INDEX IF NOT EXISTS "idx_dakshina_razorpay_order_id" ON "dakshina_collections" ("razorpay_order_id");
  `);

  console.log("✅ Migration 0011 applied successfully!");
  process.exit(0);
}

runMigration().catch((err) => {
  console.error("Migration 0011 failed:", err);
  process.exit(1);
});
