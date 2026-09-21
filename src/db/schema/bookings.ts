import {
  pgTable,
  uuid,
  numeric,
  boolean,
  text,
  varchar,
  timestamp,
} from "drizzle-orm/pg-core";
import { bookingStatusEnum, bookingModeEnum, paymentStatusEnum } from "./enums.js";
import { users } from "./users.js";
import { poojas } from "./poojas.js";
import { geometryPoint } from "../custom-types/point.js";

export const bookings = pgTable("bookings", {
  id: uuid("id").defaultRandom().primaryKey(),
  yajmanId: uuid("yajman_id")
    .notNull()
    .references(() => users.id, { onDelete: "restrict" }),
  panditId: uuid("pandit_id")
    .references(() => users.id, { onDelete: "restrict" }),
  poojaId: uuid("pooja_id")
    .notNull()
    .references(() => poojas.id, { onDelete: "restrict" }),
  mode: bookingModeEnum("mode").notNull(),
  bookingTime: timestamp("booking_time", { withTimezone: true }).notNull(),
  venueLocation: geometryPoint("venue_location"),
  venueAddress: text("venue_address"),
  samagriIncluded: boolean("samagri_included").notNull().default(false),
  customNotes: text("custom_notes"),
  totalAmount: numeric("total_amount", { precision: 10, scale: 2 }).notNull(),
  status: bookingStatusEnum("status").notNull().default("PENDING"),
  idempotencyKeyHash: varchar("idempotency_key_hash", { length: 64 }).unique(),
  createdAt: timestamp("created_at", { withTimezone: true })
    .notNull()
    .defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true })
    .notNull()
    .defaultNow()
    .$onUpdate(() => new Date()),
  razorpayOrderId: varchar("razorpay_order_id", { length: 255 }),
  paymentId: varchar("payment_id", { length: 255 }),
  paymentStatus: paymentStatusEnum("payment_status")
    .notNull()
    .default("PENDING"),
});

export type Booking = typeof bookings.$inferSelect;
export type NewBooking = typeof bookings.$inferInsert;
