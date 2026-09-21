import { z } from "zod";

export const nearbyTemplesSchema = z
  .object({
    lat: z.coerce.number().min(-90).max(90),
    lng: z.coerce.number().min(-180).max(180),
    radiusKm: z.coerce.number().min(1).max(50).optional().default(5),
  })
  .strict();

export type NearbyTemplesQuery = z.infer<typeof nearbyTemplesSchema>;
