import {
  pgTable,
  uuid,
  numeric,
  boolean,
  text,
  varchar,
  timestamp,
} from "drizzle-orm/pg-core";
import { bookingStatusEnum } from "./enums.js";
import { users } from "./users.js";
import { poojas } from "./poojas.js";
import { geometryPoint } from "../custom-types/point.js";

export const bookings = pgTable("bookings", {
  id: uuid("id").defaultRandom().primaryKey(),
  yajmanId: uuid("yajman_id")
    .notNull()
    .references(() => users.id, { onDelete: "restrict" }),
  panditId: uuid("pandit_id")
    .notNull()
    .references(() => users.id, { onDelete: "restrict" }),
  poojaId: uuid("pooja_id")
    .notNull()
    .references(() => poojas.id, { onDelete: "restrict" }),
  bookingTime: timestamp("booking_time", { withTimezone: true }).notNull(),
  venueLocation: geometryPoint("venue_location"),
  venueAddress: text("venue_address"),
  samagriIncluded: boolean("samagri_included").notNull().default(false),
  paymentStatus: varchar("payment_status", { length: 50 }),
  customNotes: text("custom_notes"),
  totalAmount: numeric("total_amount", { precision: 10, scale: 2 }).notNull(),
  status: bookingStatusEnum("status").notNull().default("PENDING"),
  createdAt: timestamp("created_at", { withTimezone: true })
    .notNull()
    .defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true })
    .notNull()
    .defaultNow()
    .$onUpdate(() => new Date()),
});

export type Booking = typeof bookings.$inferSelect;
export type NewBooking = typeof bookings.$inferInsert;
