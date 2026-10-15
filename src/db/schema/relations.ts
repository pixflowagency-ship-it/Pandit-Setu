import { relations } from "drizzle-orm";
import { bookings } from "./bookings.js";
import { poojas } from "./poojas.js";
import { users } from "./users.js";
import { pandits } from "./pandits.js";
import { bookingDeclines } from "./booking_declines.js";
import { dakshinaCollections } from "./dakshina_collections.js";
import { productOrders, productOrderItems } from "./product_orders.js";
import { products } from "./products.js";

export const bookingsRelations = relations(bookings, ({ one, many }) => ({
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
  declines: many(bookingDeclines),
  dakshinaCollection: one(dakshinaCollections),
}));

export const usersRelations = relations(users, ({ many, one }) => ({
  yajmanBookings: many(bookings, { relationName: "yajman_bookings" }),
  panditBookings: many(bookings, { relationName: "pandit_bookings" }),
  panditProfile: one(pandits, {
    fields: [users.id],
    references: [pandits.userId],
  }),
  bookingDeclines: many(bookingDeclines),
  productOrders: many(productOrders),
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

export const bookingDeclinesRelations = relations(bookingDeclines, ({ one }) => ({
  booking: one(bookings, {
    fields: [bookingDeclines.bookingId],
    references: [bookings.id],
  }),
  panditUser: one(users, {
    fields: [bookingDeclines.panditId],
    references: [users.id],
  }),
}));

export const dakshinaCollectionsRelations = relations(dakshinaCollections, ({ one }) => ({
  booking: one(bookings, {
    fields: [dakshinaCollections.bookingId],
    references: [bookings.id],
  }),
  pandit: one(users, {
    fields: [dakshinaCollections.panditId],
    references: [users.id],
  }),
}));

export const productOrdersRelations = relations(productOrders, ({ one, many }) => ({
  customer: one(users, {
    fields: [productOrders.customerId],
    references: [users.id],
  }),
  items: many(productOrderItems),
}));

export const productOrderItemsRelations = relations(productOrderItems, ({ one }) => ({
  order: one(productOrders, {
    fields: [productOrderItems.orderId],
    references: [productOrders.id],
  }),
  product: one(products, {
    fields: [productOrderItems.productId],
    references: [products.id],
  }),
}));

export const productsRelations = relations(products, ({ many }) => ({
  orderItems: many(productOrderItems),
}));

