import { relations } from "drizzle-orm";
import { bookings } from "./bookings.js";
import { poojas } from "./poojas.js";
import { users } from "./users.js";
import { pandits } from "./pandits.js";

export const bookingsRelations = relations(bookings, ({ one }) => ({
  yajman: one(users, {
    fields: [bookings.yajmanId],
    references: [users.id],
    relationName: "yajman_bookings",
  }),
  pandit: one(users, {
    fields: [bookings.panditId],
    references: [users.id],
    relationName: "pandit_bookings",
  }),
  pooja: one(poojas, {
    fields: [bookings.poojaId],
    references: [poojas.id],
  }),
}));

export const usersRelations = relations(users, ({ many, one }) => ({
  yajmanBookings: many(bookings, { relationName: "yajman_bookings" }),
  panditBookings: many(bookings, { relationName: "pandit_bookings" }),
  panditProfile: one(pandits, {
    fields: [users.id],
    references: [pandits.userId],
  }),
}));

export const panditsRelations = relations(pandits, ({ one }) => ({
  user: one(users, {
    fields: [pandits.userId],
    references: [users.id],
  }),
}));

export const poojasRelations = relations(poojas, ({ many }) => ({
  bookings: many(bookings),
}));
