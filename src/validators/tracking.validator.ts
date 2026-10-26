import { z } from "zod";

export const updateLocationSchema = z
  .object({
    lat: z.number().min(-90, "Latitude must be between -90 and 90").max(90, "Latitude must be between -90 and 90"),
    lng: z.number().min(-180, "Longitude must be between -180 and 180").max(180, "Longitude must be between -180 and 180"),
  })
  .strict();

export type UpdateLocationInput = z.infer<typeof updateLocationSchema>;

export const panditTelemetrySchema = z
  .object({
    lat: z.number().min(-90, "Latitude must be between -90 and 90").max(90, "Latitude must be between -90 and 90"),
    lng: z.number().min(-180, "Longitude must be between -180 and 180").max(180, "Longitude must be between -180 and 180"),
    accuracy: z.number().positive("Accuracy must be positive").max(1000, "Accuracy too low (must be <= 1000m)").optional(),
    heading: z.number().min(0).max(360).optional(),
    speed: z.number().min(0).optional(),
    timestamp: z.union([z.string(), z.number()]).optional(),
  })
  .strict();

export type PanditTelemetryInput = z.infer<typeof panditTelemetrySchema>;
