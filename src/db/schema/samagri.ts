import {
  pgTable,
  uuid,
  varchar,
  text,
  numeric,
  integer,
  boolean,
  timestamp,
} from "drizzle-orm/pg-core";

export const samagriItems = pgTable("samagri_items", {
  id: uuid("id").defaultRandom().primaryKey(),
  sNo: integer("s_no"),
  category: varchar("category", { length: 150 }),
  name: varchar("name", { length: 255 }).notNull(),
  nameEnglish: varchar("name_english", { length: 255 }),
  quantity: numeric("quantity", { precision: 10, scale: 2 }),
  unit: varchar("unit", { length: 50 }).default("pcs"),
  requiredAvailable: varchar("required_available", { length: 50 }).default("Required"),
  remarks: text("remarks"),
  description: text("description"),
  price: numeric("price", { precision: 10, scale: 2 }).default("0.00"),
  stockQuantity: integer("stock_quantity").default(0),
  imageUrl: text("image_url"),
  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at", { withTimezone: true })
    .notNull()
    .defaultNow(),
});

export type SamagriItem = typeof samagriItems.$inferSelect;
export type NewSamagriItem = typeof samagriItems.$inferInsert;
