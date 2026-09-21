import { z } from "zod";

export const updateLocationSchema = z
  .object({
    lat: z.number().min(-90).max(90, "Invalid latitude"),
    lng: z.number().min(-180).max(180, "Invalid longitude"),
  })
  .strict();

export type UpdateLocationInput = z.infer<typeof updateLocationSchema>;
