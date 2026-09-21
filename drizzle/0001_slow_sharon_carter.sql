CREATE TYPE "public"."booking_mode" AS ENUM('IN_PERSON', 'ONLINE');--> statement-breakpoint
ALTER TABLE "bookings" ALTER COLUMN "pandit_id" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "poojas" ADD COLUMN "samagri_price" numeric(10, 2) DEFAULT '0.00' NOT NULL;--> statement-breakpoint
ALTER TABLE "bookings" ADD COLUMN "mode" "booking_mode" NOT NULL;--> statement-breakpoint
ALTER TABLE "bookings" ADD COLUMN "idempotency_key_hash" varchar(64);--> statement-breakpoint
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_idempotency_key_hash_unique" UNIQUE("idempotency_key_hash");