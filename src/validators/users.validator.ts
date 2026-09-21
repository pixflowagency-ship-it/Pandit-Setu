import { z } from "zod";

export const updateProfileSchema = z.object({
  fullName: z.string().min(1).optional(),
  email: z.string().email().optional(),
  dob: z.string().optional(),
  tob: z.string().optional(),
  pob: z.string().optional(),
  gotra: z.string().optional(),
  zodiac: z.string().optional(),
  city: z.string().optional(),
}).strict();

export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;

export const fcmTokenSchema = z
  .object({
    token: z.string().max(255, "Token is too long").min(1, "Token is required"),
  })
  .strict();
