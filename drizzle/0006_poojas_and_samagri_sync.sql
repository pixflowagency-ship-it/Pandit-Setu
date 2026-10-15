ALTER TABLE "poojas" ADD COLUMN IF NOT EXISTS "category" varchar(150);--> statement-breakpoint
ALTER TABLE "poojas" ADD COLUMN IF NOT EXISTS "duration" varchar(100);--> statement-breakpoint
ALTER TABLE "poojas" ADD COLUMN IF NOT EXISTS "required_pandits" varchar(50);--> statement-breakpoint
ALTER TABLE "poojas" ADD COLUMN IF NOT EXISTS "samagri_price" numeric(10, 2) DEFAULT '0.00';--> statement-breakpoint

ALTER TABLE "samagri_items" ADD COLUMN IF NOT EXISTS "s_no" integer;--> statement-breakpoint
ALTER TABLE "samagri_items" ADD COLUMN IF NOT EXISTS "category" varchar(150);--> statement-breakpoint
ALTER TABLE "samagri_items" ADD COLUMN IF NOT EXISTS "name_english" varchar(255);--> statement-breakpoint
ALTER TABLE "samagri_items" ADD COLUMN IF NOT EXISTS "quantity" numeric(10, 2);--> statement-breakpoint
ALTER TABLE "samagri_items" ADD COLUMN IF NOT EXISTS "required_available" varchar(50) DEFAULT 'Required';--> statement-breakpoint
ALTER TABLE "samagri_items" ADD COLUMN IF NOT EXISTS "remarks" text;--> statement-breakpoint
ALTER TABLE "samagri_items" ALTER COLUMN "price" SET DEFAULT '0.00';--> statement-breakpoint
ALTER TABLE "samagri_items" ALTER COLUMN "price" DROP NOT NULL;
