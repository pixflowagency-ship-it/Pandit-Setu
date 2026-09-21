import { z } from "zod";

export const nearbyQuerySchema = z
  .object({
    lat: z.coerce.number().min(-90).max(90),
    lng: z.coerce.number().min(-180).max(180),
    radiusKm: z.coerce.number().min(1).max(100).optional().default(15),
  })
  .strict();

export type NearbyQuery = z.infer<typeof nearbyQuerySchema>;

export const dutyStatusSchema = z
  .object({
    isAvailable: z.boolean(),
  })
  .strict();

export type DutyStatusInput = z.infer<typeof dutyStatusSchema>;

export const acceptBookingSchema = z
  .object({
    bookingId: z.string().uuid("bookingId must be a valid UUID"),
  })
  .strict();

export type AcceptBookingInput = z.infer<typeof acceptBookingSchema>;
