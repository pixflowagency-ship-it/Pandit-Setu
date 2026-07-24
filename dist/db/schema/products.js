import { pgTable, uuid, varchar, text, numeric, boolean, timestamp } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
export const products = pgTable('products', {
    id: uuid('id').defaultRandom().primaryKey(),
    name: varchar('name', { length: 255 }).notNull(),
    description: text('description'),
    price: numeric('price', { precision: 10, scale: 2 }).notNull(),
    category: varchar('category', { length: 100 }).notNull(), // e.g., 'pooja_kits', 'essentials'
    badge: varchar('badge', { length: 100 }), // e.g., 'Bestseller'
    samagri: text('samagri').array().notNull().default(sql `'{}'::text[]`), // array of strings
    imageUrl: text('image_url'),
    isActive: boolean('is_active').notNull().default(true),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});
//# sourceMappingURL=products.js.map