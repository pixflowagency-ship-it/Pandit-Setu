import { z } from "zod";

export const adminListPanditsQuerySchema = z.object({
  status: z.enum(["PENDING", "APPROVED", "REJECTED", "ALL"]).optional().default("ALL"),
  page: z.coerce.number().int().min(1).optional().default(1),
  limit: z.coerce.number().int().min(1).max(100).optional().default(20),
});

export const adminListSubscriptionsQuerySchema = z.object({
  status: z
    .enum(["CREATED", "AUTHENTICATED", "ACTIVE", "PENDING", "HALTED", "CANCELLED", "COMPLETED", "EXPIRED", "ALL"])
    .optional()
    .default("ALL"),
  page: z.coerce.number().int().min(1).optional().default(1),
  limit: z.coerce.number().int().min(1).max(100).optional().default(20),
});

export const adminLoginSchema = z.object({
  email: z.string().email("A valid administrator email is required"),
  password: z.string().min(8, "Password must be at least 8 characters"),
});

