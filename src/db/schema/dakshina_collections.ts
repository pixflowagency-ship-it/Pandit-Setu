import {
  pgTable,
  uuid,
  numeric,
  varchar,
  text,
  timestamp,
} from "drizzle-orm/pg-core";
import { paymentStatusEnum } from "./enums.js";
import { bookings } from "./bookings.js";
import { users } from "./users.js";

export const dakshinaCollections = pgTable("dakshina_collections", {
  id: uuid("id").defaultRandom().primaryKey(),
  bookingId: uuid("booking_id")
    .notNull()
    .references(() => bookings.id, { onDelete: "cascade" }),
  panditId: uuid("pandit_id")
    .notNull()
    .references(() => users.id, { onDelete: "restrict" }),
  amount: numeric("amount", { precision: 10, scale: 2 }).notNull(),
  currency: varchar("currency", { length: 10 }).notNull().default("INR"),
  paymentMethod: varchar("payment_method", { length: 20 }).notNull(), // 'CASH' | 'ONLINE'
  paymentStatus: paymentStatusEnum("payment_status")
    .notNull()
    .default("PENDING"), // 'PENDING' | 'PAID' | 'FAILED'
  razorpayOrderId: varchar("razorpay_order_id", { length: 255 }),
  razorpayPaymentId: varchar("razorpay_payment_id", { length: 255 }),
  razorpaySignature: text("razorpay_signature"),
  collectedAt: timestamp("collected_at", { withTimezone: true }),
  notes: text("notes"),
  createdAt: timestamp("created_at", { withTimezone: true })
    .notNull()
    .defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true })
    .notNull()
    .defaultNow()
    .$onUpdate(() => new Date()),
});

export type DakshinaCollection = typeof dakshinaCollections.$inferSelect;
export type NewDakshinaCollection = typeof dakshinaCollections.$inferInsert;
