DO $$ BEGIN
 CREATE TYPE "public"."consultation_type" AS ENUM('ONLINE', 'OFFLINE');
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
 CREATE TYPE "public"."consultation_timing" AS ENUM('IMMEDIATE', 'SCHEDULED');
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
 CREATE TYPE "public"."consultation_medium" AS ENUM('PHONE', 'VIDEO', 'IN_PERSON');
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
 CREATE TYPE "public"."consultation_status" AS ENUM(
  'REQUESTED',
  'UNDER_REVIEW',
  'SCHEDULED',
  'CONFIRMED',
  'IN_PROGRESS',
  'COMPLETED',
  'CANCELLED',
  'REJECTED'
 );
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
 CREATE TYPE "public"."kundli_order_status" AS ENUM(
  'REQUESTED',
  'UNDER_REVIEW',
  'ACCEPTED',
  'PAYMENT_PENDING',
  'PAID',
  'ASSIGNED',
  'PREPARING',
  'READY',
  'DISPATCHED',
  'DELIVERED',
  'CANCELLED',
  'REJECTED'
 );
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS "consultations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"consultation_number" varchar(50) NOT NULL UNIQUE,
	"user_id" uuid NOT NULL,
	"assigned_pandit_id" uuid,
	"type" "public"."consultation_type" NOT NULL,
	"timing" "public"."consultation_timing" NOT NULL,
	"medium" "public"."consultation_medium" NOT NULL,
	"topic" text NOT NULL,
	"duration_minutes" integer DEFAULT 15 NOT NULL,
	"amount" numeric(10, 2) NOT NULL,
	"currency" varchar(10) DEFAULT 'INR' NOT NULL,
	"status" "public"."consultation_status" DEFAULT 'REQUESTED' NOT NULL,
	"payment_status" "public"."payment_status" DEFAULT 'PENDING' NOT NULL,
	"devotee_name" varchar(255) NOT NULL,
	"devotee_phone" varchar(20) NOT NULL,
	"requested_date" timestamp with time zone,
	"requested_time_slot" varchar(50),
	"scheduled_date_time" timestamp with time zone,
	"venue_address" text,
	"kendra_name" varchar(255),
	"notes" text,
	"rejection_reason" text,
	"cancellation_reason" text,
	"razorpay_order_id" varchar(255),
	"razorpay_payment_id" varchar(255),
	"razorpay_signature" text,
	"paid_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "kundli_orders" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"order_number" varchar(50) NOT NULL UNIQUE,
	"user_id" uuid NOT NULL,
	"assigned_pandit_id" uuid,
	"status" "public"."kundli_order_status" DEFAULT 'REQUESTED' NOT NULL,
	"payment_status" "public"."payment_status" DEFAULT 'PENDING' NOT NULL,
	"amount" numeric(10, 2) DEFAULT '1501.00' NOT NULL,
	"currency" varchar(10) DEFAULT 'INR' NOT NULL,
	"devotee_name" varchar(255) NOT NULL,
	"devotee_phone" varchar(20) NOT NULL,
	"gender" varchar(20) DEFAULT 'Male' NOT NULL,
	"dob" varchar(50) NOT NULL,
	"tob" varchar(50) NOT NULL,
	"pob" text NOT NULL,
	"birth_accuracy" varchar(50) DEFAULT 'accurate' NOT NULL,
	"gotra" varchar(100),
	"language" varchar(50) DEFAULT 'Hindi' NOT NULL,
	"delivery_address" text NOT NULL,
	"special_notes" text,
	"rejection_reason" text,
	"cancellation_reason" text,
	"dispatch_tracking_number" varchar(100),
	"courier_partner" varchar(100),
	"razorpay_order_id" varchar(255),
	"razorpay_payment_id" varchar(255),
	"razorpay_signature" text,
	"paid_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

DO $$ BEGIN
 ALTER TABLE "consultations" ADD CONSTRAINT "consultations_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
 ALTER TABLE "consultations" ADD CONSTRAINT "consultations_assigned_pandit_id_pandits_id_fk" FOREIGN KEY ("assigned_pandit_id") REFERENCES "public"."pandits"("id") ON DELETE set null ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
 ALTER TABLE "kundli_orders" ADD CONSTRAINT "kundli_orders_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
 ALTER TABLE "kundli_orders" ADD CONSTRAINT "kundli_orders_assigned_pandit_id_pandits_id_fk" FOREIGN KEY ("assigned_pandit_id") REFERENCES "public"."pandits"("id") ON DELETE set null ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;

CREATE INDEX IF NOT EXISTS "idx_consultations_user_id" ON "consultations" ("user_id");
CREATE INDEX IF NOT EXISTS "idx_consultations_assigned_pandit_id" ON "consultations" ("assigned_pandit_id");
CREATE INDEX IF NOT EXISTS "idx_consultations_status" ON "consultations" ("status");
CREATE INDEX IF NOT EXISTS "idx_consultations_number" ON "consultations" ("consultation_number");

CREATE INDEX IF NOT EXISTS "idx_kundli_orders_user_id" ON "kundli_orders" ("user_id");
CREATE INDEX IF NOT EXISTS "idx_kundli_orders_assigned_pandit_id" ON "kundli_orders" ("assigned_pandit_id");
CREATE INDEX IF NOT EXISTS "idx_kundli_orders_status" ON "kundli_orders" ("status");
CREATE INDEX IF NOT EXISTS "idx_kundli_orders_number" ON "kundli_orders" ("order_number");
