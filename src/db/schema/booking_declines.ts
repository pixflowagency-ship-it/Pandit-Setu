import { pgTable, uuid, varchar, text, timestamp, uniqueIndex, index } from "drizzle-orm/pg-core";
import { bookings } from "./bookings.js";
import { users } from "./users.js";

export const declineReasonEnum = [
  "TOO_FAR",
  "BUSY",
  "SCHEDULE_CONFLICT",
  "OTHER",
] as const;

export type DeclineReason = (typeof declineReasonEnum)[number];

export const bookingDeclines = pgTable(
  "booking_declines",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    bookingId: uuid("booking_id")
      .notNull()
      .references(() => bookings.id, { onDelete: "cascade" }),
    panditId: uuid("pandit_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
    reason: varchar("reason", { length: 50 }).notNull().default("OTHER"),
    notes: text("notes"),
    createdAt: timestamp("created_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => {
    return {
      uniqueBookingPandit: uniqueIndex("idx_booking_declines_booking_pandit").on(
        table.bookingId,
        table.panditId
      ),
      bookingIdx: index("idx_booking_declines_booking_id").on(table.bookingId),
      panditIdx: index("idx_booking_declines_pandit_id").on(table.panditId),
    };
  }
);

export type BookingDecline = typeof bookingDeclines.$inferSelect;
export type NewBookingDecline = typeof bookingDeclines.$inferInsert;
