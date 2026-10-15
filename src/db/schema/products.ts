import { pgTable, uuid, varchar, text, numeric, boolean, timestamp } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';

export const products = pgTable('products', {
  id: uuid('id').defaultRandom().primaryKey(),
  productId: varchar('product_id', { length: 50 }).unique(),
  name: varchar('name', { length: 255 }).notNull(),
  category: varchar('category', { length: 150 }).notNull(),
  subCategory: varchar('sub_category', { length: 150 }),
  specificationType: varchar('specification_type', { length: 100 }),
  unit: varchar('unit', { length: 50 }),
  price: numeric('price', { precision: 10, scale: 2 }).notNull().default('150.00'),
  description: text('description'),
  imageUrl: text('image_url'),
  status: varchar('status', { length: 50 }).default('Active'),
  searchTags: text('search_tags'),
  badge: varchar('badge', { length: 100 }),
  samagri: text('samagri').array().notNull().default(sql`'{}'::text[]`),
  isActive: boolean('is_active').notNull().default(true),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export type Product = typeof products.$inferSelect;
export type NewProduct = typeof products.$inferInsert;
