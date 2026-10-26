import {
  pgTable,
  uuid,
  varchar,
  text,
  numeric,
  integer,
  timestamp,
  pgEnum,
  index,
} from "drizzle-orm/pg-core";
import { users } from "./users.js";
import { pandits } from "./pandits.js";
import { paymentStatusEnum } from "./enums.js";

export const consultationTypeEnum = pgEnum("consultation_type", [
  "ONLINE",
  "OFFLINE",
]);

export const consultationTimingEnum = pgEnum("consultation_timing", [
  "IMMEDIATE",
  "SCHEDULED",
]);

export const consultationMediumEnum = pgEnum("consultation_medium", [
  "PHONE",
  "VIDEO",
  "IN_PERSON",
]);

export const consultationStatusEnum = pgEnum("consultation_status", [
  "REQUESTED",
  "UNDER_REVIEW",
  "SCHEDULED",
  "CONFIRMED",
  "IN_PROGRESS",
  "COMPLETED",
  "CANCELLED",
  "REJECTED",
]);

export const consultations = pgTable(
  "consultations",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    consultationNumber: varchar("consultation_number", { length: 50 })
      .notNull()
      .unique(),
    userId: uuid("user_id")
      .notNull()
      .references(() => users.id, { onDelete: "restrict" }),
    assignedPanditId: uuid("assigned_pandit_id").references(() => pandits.id, {
      onDelete: "set null",
    }),
    type: consultationTypeEnum("type").notNull(),
    timing: consultationTimingEnum("timing").notNull(),
    medium: consultationMediumEnum("medium").notNull(),
    topic: text("topic").notNull(),
    durationMinutes: integer("duration_minutes").notNull().default(15),
    amount: numeric("amount", { precision: 10, scale: 2 }).notNull(),
    currency: varchar("currency", { length: 10 }).notNull().default("INR"),
    status: consultationStatusEnum("status").notNull().default("REQUESTED"),
    paymentStatus: paymentStatusEnum("payment_status")
      .notNull()
      .default("PENDING"),

    devoteeName: varchar("devotee_name", { length: 255 }).notNull(),
    devoteePhone: varchar("devotee_phone", { length: 20 }).notNull(),

    requestedDate: timestamp("requested_date", { withTimezone: true }),
    requestedTimeSlot: varchar("requested_time_slot", { length: 50 }),
    scheduledDateTime: timestamp("scheduled_date_time", { withTimezone: true }),

    venueAddress: text("venue_address"),
    kendraName: varchar("kendra_name", { length: 255 }),
    notes: text("notes"),
    rejectionReason: text("rejection_reason"),
    cancellationReason: text("cancellation_reason"),

    razorpayOrderId: varchar("razorpay_order_id", { length: 255 }),
    razorpayPaymentId: varchar("razorpay_payment_id", { length: 255 }),
    razorpaySignature: text("razorpay_signature"),
    paidAt: timestamp("paid_at", { withTimezone: true }),

    createdAt: timestamp("created_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp("updated_at", { withTimezone: true })
      .notNull()
      .defaultNow()
      .$onUpdate(() => new Date()),
  },
  (table) => ({
    userIdIdx: index("idx_consultations_user_id").on(table.userId),
    assignedPanditIdIdx: index("idx_consultations_assigned_pandit_id").on(
      table.assignedPanditId
    ),
    statusIdx: index("idx_consultations_status").on(table.status),
    consultationNumberIdx: index("idx_consultations_number").on(
      table.consultationNumber
    ),
  })
);

export type Consultation = typeof consultations.$inferSelect;
export type NewConsultation = typeof consultations.$inferInsert;
