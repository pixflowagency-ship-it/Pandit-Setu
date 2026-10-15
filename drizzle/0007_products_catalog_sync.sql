ALTER TABLE "products" ADD COLUMN IF NOT EXISTS "product_id" varchar(50) UNIQUE;
ALTER TABLE "products" ADD COLUMN IF NOT EXISTS "sub_category" varchar(150);
ALTER TABLE "products" ADD COLUMN IF NOT EXISTS "specification_type" varchar(100);
ALTER TABLE "products" ADD COLUMN IF NOT EXISTS "unit" varchar(50);
ALTER TABLE "products" ADD COLUMN IF NOT EXISTS "status" varchar(50) DEFAULT 'Active';
ALTER TABLE "products" ADD COLUMN IF NOT EXISTS "search_tags" text;
ALTER TABLE "products" ADD COLUMN IF NOT EXISTS "updated_at" timestamp with time zone DEFAULT now() NOT NULL;
ALTER TABLE "products" ALTER COLUMN "category" TYPE varchar(150);
