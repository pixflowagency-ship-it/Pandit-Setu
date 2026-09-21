import {
  pgTable,
  uuid,
  timestamp,
  varchar,
} from "drizzle-orm/pg-core";
import { users } from "./users.js";
import { subscriptionStatusEnum } from "./enums.js";

export const subscriptions = pgTable("subscriptions", {
  id: uuid("id").defaultRandom().primaryKey(),
  userId: uuid("user_id")
    .notNull()
    .references(() => users.id, { onDelete: "restrict" }),
  razorpaySubscriptionId: varchar("razorpay_subscription_id", { length: 255 }).unique(),
  planId: varchar("plan_id", { length: 255 }).notNull(),
  status: subscriptionStatusEnum("status").notNull().default("CREATED"),
  currentPeriodEnd: timestamp("current_period_end", { withTimezone: true }),
  createdAt: timestamp("created_at", { withTimezone: true })
    .notNull()
    .defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true })
    .notNull()
    .defaultNow()
    .$onUpdate(() => new Date()),
});

export type Subscription = typeof subscriptions.$inferSelect;
export type NewSubscription = typeof subscriptions.$inferInsert;
