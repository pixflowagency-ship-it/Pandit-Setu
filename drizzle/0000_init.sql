CREATE TYPE "public"."booking_status" AS ENUM('PENDING', 'CONFIRMED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED');--> statement-breakpoint
CREATE TYPE "public"."doc_status" AS ENUM('PENDING', 'VERIFIED', 'REJECTED');--> statement-breakpoint
CREATE TYPE "public"."doc_type" AS ENUM('AADHAAR', 'PAN', 'DEGREE_CERTIFICATE', 'OTHER');--> statement-breakpoint
CREATE TYPE "public"."user_role" AS ENUM('YAJMAN', 'PANDIT', 'ADMIN');--> statement-breakpoint
CREATE TYPE "public"."verification_stage" AS ENUM('STAGE_1_COMPLETE', 'DOCS_SUBMITTED', 'VERIFIED', 'REJECTED');--> statement-breakpoint
CREATE TYPE "public"."verification_status" AS ENUM('PENDING', 'APPROVED', 'REJECTED');--> statement-breakpoint
CREATE TABLE "users" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"phone" varchar(15) NOT NULL,
	"full_name" varchar(255) NOT NULL,
	"dob" varchar(10),
	"tob" varchar(8),
	"pob" varchar(255),
	"gotra" varchar(255),
	"zodiac" varchar(255),
	"city" varchar(255),
	"email" varchar(255),
	"profile_picture_url" text,
	"role" "user_role" DEFAULT 'YAJMAN' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "users_phone_unique" UNIQUE("phone")
);
--> statement-breakpoint
CREATE TABLE "pandit_documents" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"pandit_id" uuid NOT NULL,
	"doc_type" "doc_type" NOT NULL,
	"doc_url" text NOT NULL,
	"status" "doc_status" DEFAULT 'PENDING' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "pandit_profiles" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"verification_stage" "verification_stage" DEFAULT 'STAGE_1_COMPLETE' NOT NULL,
	"is_online" boolean DEFAULT false NOT NULL,
	"bio" text,
	"rating" numeric(3, 2) DEFAULT '0.00' NOT NULL,
	"location" geometry(Point, 4326),
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "pandit_profiles_user_id_unique" UNIQUE("user_id")
);
--> statement-breakpoint
CREATE TABLE "pandit_services" (
	"pandit_id" uuid NOT NULL,
	"pooja_id" uuid NOT NULL,
	"custom_price" numeric(10, 2),
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "pandit_services_pandit_id_pooja_id_pk" PRIMARY KEY("pandit_id","pooja_id")
);
--> statement-breakpoint
CREATE TABLE "pandits" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"experience_years" integer,
	"vedic_specialization" text,
	"languages" jsonb,
	"bio" text,
	"is_verified" boolean DEFAULT false NOT NULL,
	"verification_status" "verification_status" DEFAULT 'PENDING' NOT NULL,
	"service_radius_km" integer DEFAULT 15 NOT NULL,
	"latitude" double precision,
	"longitude" double precision,
	"location" geometry(Point, 4326),
	"is_available" boolean DEFAULT true NOT NULL,
	"rating" numeric(3, 2) DEFAULT '5.00' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "pandits_user_id_unique" UNIQUE("user_id")
);
--> statement-breakpoint
CREATE TABLE "poojas" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"title" varchar(255) NOT NULL,
	"slug" varchar(150) NOT NULL,
	"description" text,
	"base_price" numeric(10, 2) NOT NULL,
	"duration_minutes" integer NOT NULL,
	"image_url" text,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "poojas_slug_unique" UNIQUE("slug")
);
--> statement-breakpoint
CREATE TABLE "products" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" varchar(255) NOT NULL,
	"description" text,
	"price" numeric(10, 2) NOT NULL,
	"category" varchar(100) NOT NULL,
	"badge" varchar(100),
	"samagri" text[] DEFAULT '{}'::text[] NOT NULL,
	"image_url" text,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "bookings" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"yajman_id" uuid NOT NULL,
	"pandit_id" uuid NOT NULL,
	"pooja_id" uuid NOT NULL,
	"booking_time" timestamp with time zone NOT NULL,
	"venue_location" geometry(Point, 4326),
	"venue_address" text,
	"samagri_included" boolean DEFAULT false NOT NULL,
	"payment_status" varchar(50),
	"custom_notes" text,
	"total_amount" numeric(10, 2) NOT NULL,
	"status" "booking_status" DEFAULT 'PENDING' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "pandit_documents" ADD CONSTRAINT "pandit_documents_pandit_id_pandits_id_fk" FOREIGN KEY ("pandit_id") REFERENCES "public"."pandits"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "pandit_profiles" ADD CONSTRAINT "pandit_profiles_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "pandit_services" ADD CONSTRAINT "pandit_services_pandit_id_pandits_id_fk" FOREIGN KEY ("pandit_id") REFERENCES "public"."pandits"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "pandit_services" ADD CONSTRAINT "pandit_services_pooja_id_poojas_id_fk" FOREIGN KEY ("pooja_id") REFERENCES "public"."poojas"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "pandits" ADD CONSTRAINT "pandits_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_yajman_id_users_id_fk" FOREIGN KEY ("yajman_id") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_pandit_id_users_id_fk" FOREIGN KEY ("pandit_id") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_pooja_id_poojas_id_fk" FOREIGN KEY ("pooja_id") REFERENCES "public"."poojas"("id") ON DELETE restrict ON UPDATE no action;