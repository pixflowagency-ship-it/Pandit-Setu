import {
  pgTable,
  uuid,
  varchar,
  text,
  numeric,
  timestamp,
  pgEnum,
  index,
} from "drizzle-orm/pg-core";
import { users } from "./users.js";
import { pandits } from "./pandits.js";
import { paymentStatusEnum } from "./enums.js";

export const kundliOrderStatusEnum = pgEnum("kundli_order_status", [
  "REQUESTED",
  "UNDER_REVIEW",
  "ACCEPTED",
  "PAYMENT_PENDING",
  "PAID",
  "ASSIGNED",
  "PREPARING",
  "READY",
  "DISPATCHED",
  "DELIVERED",
  "CANCELLED",
  "REJECTED",
]);

export const kundliOrders = pgTable(
  "kundli_orders",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    orderNumber: varchar("order_number", { length: 50 }).notNull().unique(),
    userId: uuid("user_id")
      .notNull()
      .references(() => users.id, { onDelete: "restrict" }),
    assignedPanditId: uuid("assigned_pandit_id").references(() => pandits.id, {
      onDelete: "set null",
    }),
    status: kundliOrderStatusEnum("status").notNull().default("REQUESTED"),
    paymentStatus: paymentStatusEnum("payment_status")
      .notNull()
      .default("PENDING"),
    amount: numeric("amount", { precision: 10, scale: 2 })
      .notNull()
      .default("1501.00"),
    currency: varchar("currency", { length: 10 }).notNull().default("INR"),

    devoteeName: varchar("devotee_name", { length: 255 }).notNull(),
    devoteePhone: varchar("devotee_phone", { length: 20 }).notNull(),
    gender: varchar("gender", { length: 20 }).notNull().default("Male"),
    dob: varchar("dob", { length: 50 }).notNull(),
    tob: varchar("tob", { length: 50 }).notNull(),
    pob: text("pob").notNull(),
    birthAccuracy: varchar("birth_accuracy", { length: 50 })
      .notNull()
      .default("accurate"),
    gotra: varchar("gotra", { length: 100 }),
    language: varchar("language", { length: 50 }).notNull().default("Hindi"),
    deliveryAddress: text("delivery_address").notNull(),
    specialNotes: text("special_notes"),

    rejectionReason: text("rejection_reason"),
    cancellationReason: text("cancellation_reason"),
    dispatchTrackingNumber: varchar("dispatch_tracking_number", { length: 100 }),
    courierPartner: varchar("courier_partner", { length: 100 }),

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
    userIdIdx: index("idx_kundli_orders_user_id").on(table.userId),
    assignedPanditIdIdx: index("idx_kundli_orders_assigned_pandit_id").on(
      table.assignedPanditId
    ),
    statusIdx: index("idx_kundli_orders_status").on(table.status),
    orderNumberIdx: index("idx_kundli_orders_number").on(table.orderNumber),
  })
);

export type KundliOrder = typeof kundliOrders.$inferSelect;
export type NewKundliOrder = typeof kundliOrders.$inferInsert;
