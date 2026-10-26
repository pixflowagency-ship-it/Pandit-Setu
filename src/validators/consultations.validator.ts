import { z } from "zod";

export const createConsultationSchema = z
  .object({
    type: z.enum(["ONLINE", "OFFLINE"]),
    timing: z.enum(["IMMEDIATE", "SCHEDULED"]),
    medium: z.enum(["PHONE", "VIDEO", "IN_PERSON"]),
    topic: z.string().min(2).max(500),
    durationMinutes: z.number().int().refine((val) => [15, 30, 60].includes(val), {
      message: "Duration must be 15, 30, or 60 minutes",
    }),
    devoteeName: z.string().min(2).max(255),
    devoteePhone: z.string().min(10).max(20),
    requestedDate: z.string().datetime().optional().nullable(),
    requestedTimeSlot: z.string().max(50).optional().nullable(),
    venueAddress: z.string().max(1000).optional().nullable(),
    kendraName: z.string().max(255).optional().nullable(),
    notes: z.string().max(2000).optional().nullable(),
  })
  .strict();

export const adminScheduleConsultationSchema = z
  .object({
    scheduledDateTime: z.string().datetime(),
    notes: z.string().max(1000).optional().nullable(),
  })
  .strict();

export const adminAssignConsultationSchema = z
  .object({
    panditId: z.string().uuid(),
  })
  .strict();

export const adminUpdateConsultationStatusSchema = z
  .object({
    status: z.enum([
      "REQUESTED",
      "UNDER_REVIEW",
      "SCHEDULED",
      "CONFIRMED",
      "IN_PROGRESS",
      "COMPLETED",
      "CANCELLED",
      "REJECTED",
    ]),
    reason: z.string().max(1000).optional().nullable(),
  })
  .strict();

export const cancelConsultationSchema = z
  .object({
    cancellationReason: z.string().min(2).max(1000),
  })
  .strict();

export const verifyConsultationPaymentSchema = z
  .object({
    razorpayOrderId: z.string().min(1),
    razorpayPaymentId: z.string().min(1),
    razorpaySignature: z.string().min(1),
  })
  .strict();

export const listConsultationsQuerySchema = z.object({
  type: z.enum(["ONLINE", "OFFLINE", "ALL"]).optional().default("ALL"),
  status: z.string().optional().default("ALL"),
  page: z.coerce.number().int().min(1).optional().default(1),
  limit: z.coerce.number().int().min(1).max(100).optional().default(20),
});
