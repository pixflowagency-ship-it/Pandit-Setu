CREATE TYPE "public"."payment_status" AS ENUM('PENDING', 'PAID', 'FAILED');--> statement-breakpoint
ALTER TABLE "bookings" ALTER COLUMN "payment_status" SET DEFAULT 'PENDING'::"public"."payment_status";--> statement-breakpoint
ALTER TABLE "bookings" ALTER COLUMN "payment_status" SET DATA TYPE "public"."payment_status" USING "payment_status"::"public"."payment_status";--> statement-breakpoint
ALTER TABLE "bookings" ALTER COLUMN "payment_status" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "bookings" ADD COLUMN "razorpay_order_id" varchar(255);--> statement-breakpoint
ALTER TABLE "bookings" ADD COLUMN "payment_id" varchar(255);--> statement-breakpoint
CREATE INDEX "idx_pandits_location_gist" ON "pandits" USING gist ("location");