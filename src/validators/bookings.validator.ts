import { z } from "zod";

const baseFields = {
  poojaId: z.string().uuid("poojaId must be a valid UUID"),
  bookingTime: z.string().datetime({ message: "bookingTime must be an ISO 8601 datetime" }),
  customNotes: z.string().max(1000).optional(),
};

const inPersonSchema = z
  .object({
    ...baseFields,
    mode: z.literal("IN_PERSON"),
    venueAddress: z.string().min(5, "Venue address must be at least 5 characters"),
    lat: z.number().min(-90).max(90),
    lng: z.number().min(-180).max(180),
    samagriIncluded: z.boolean(),
  })
  .strict();

const onlineSchema = z
  .object({
    ...baseFields,
    mode: z.literal("ONLINE"),
    samagriIncluded: z.boolean().optional(), // ignored — forced to true server-side
  })
  .strict();

export const createBookingSchema = z.discriminatedUnion("mode", [
  inPersonSchema,
  onlineSchema,
]);

export type CreateBookingInput = z.infer<typeof createBookingSchema>;

export const listBookingsQuerySchema = z
  .object({
    cursor: z.string().datetime().optional(),
    limit: z
      .string()
      .regex(/^\d+$/)
      .transform(Number)
      .refine((n) => n > 0 && n <= 20, { message: "limit must be between 1 and 20" })
      .optional()
      .default("20"),
  })
  .strict();

export type ListBookingsQuery = z.infer<typeof listBookingsQuerySchema>;

export const getBookingParamsSchema = z
  .object({
    id: z.string().uuid("id must be a valid UUID"),
  })
  .strict();

export const updateBookingStatusSchema = z
  .object({
    expectedStatus: z.enum(["PENDING", "CONFIRMED", "IN_PROGRESS", "COMPLETED", "CANCELLED"]),
    newStatus: z.enum(["PENDING", "CONFIRMED", "IN_PROGRESS", "COMPLETED", "CANCELLED"]),
  })
  .strict();

export type UpdateBookingStatusInput = z.infer<typeof updateBookingStatusSchema>;
