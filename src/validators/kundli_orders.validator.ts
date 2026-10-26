import { z } from "zod";

export const createKundliOrderSchema = z
  .object({
    devoteeName: z.string().min(2).max(255),
    devoteePhone: z.string().min(10).max(20),
    gender: z.string().max(20).optional().default("Male"),
    dob: z.string().min(4).max(50),
    tob: z.string().min(2).max(50),
    pob: z.string().min(2).max(500),
    birthAccuracy: z.string().max(50).optional().default("accurate"),
    gotra: z.string().max(100).optional().nullable(),
    language: z.string().max(50).optional().default("Hindi"),
    deliveryAddress: z.string().min(5).max(1000),
    kundliType: z.string().max(100).optional().default("Patrika"),
    concernCategory: z.string().max(255).optional().nullable(),
    specialNotes: z.string().max(2000).optional().nullable(),
  })
  .strict();

export const adminDecisionKundliOrderSchema = z
  .object({
    decision: z.enum(["ACCEPT", "REJECT"]),
    reason: z.string().max(1000).optional().nullable(),
  })
  .strict();

export const adminAssignKundliOrderSchema = z
  .object({
    panditId: z.string().uuid(),
  })
  .strict();

export const adminUpdateKundliStatusSchema = z
  .object({
    status: z.enum([
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
    ]),
    dispatchTrackingNumber: z.string().max(100).optional().nullable(),
    courierPartner: z.string().max(100).optional().nullable(),
    notes: z.string().max(1000).optional().nullable(),
  })
  .strict();

export const cancelKundliOrderSchema = z
  .object({
    cancellationReason: z.string().min(2).max(1000),
  })
  .strict();

export const verifyKundliPaymentSchema = z
  .object({
    razorpayOrderId: z.string().min(1),
    razorpayPaymentId: z.string().min(1),
    razorpaySignature: z.string().min(1),
  })
  .strict();

export const listKundliOrdersQuerySchema = z.object({
  status: z.string().optional().default("ALL"),
  page: z.coerce.number().int().min(1).optional().default(1),
  limit: z.coerce.number().int().min(1).max(100).optional().default(20),
});
