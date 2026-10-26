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

export const adminListUsersQuerySchema = z.object({
  search: z.string().optional(),
  role: z.enum(["YAJMAN", "PANDIT", "ADMIN", "ALL"]).optional().default("ALL"),
  page: z.coerce.number().int().min(1).optional().default(1),
  limit: z.coerce.number().int().min(1).max(100).optional().default(20),
});

export const adminListBookingsQuerySchema = z.object({
  status: z
    .enum(["PENDING", "ACCEPTED", "CONFIRMED", "IN_PROGRESS", "COMPLETED", "CANCELLED", "ALL"])
    .optional()
    .default("ALL"),
  page: z.coerce.number().int().min(1).optional().default(1),
  limit: z.coerce.number().int().min(1).max(100).optional().default(20),
});

export const adminUpdateBookingStatusSchema = z.object({
  status: z.enum(["PENDING", "ACCEPTED", "CONFIRMED", "IN_PROGRESS", "COMPLETED", "CANCELLED"]),
  notes: z.string().optional(),
});

export const adminListPoojasQuerySchema = z.object({
  category: z.string().optional(),
  page: z.coerce.number().int().min(1).optional().default(1),
  limit: z.coerce.number().int().min(1).max(100).optional().default(20),
});

export const adminCreatePoojaSchema = z.object({
  title: z.string().min(2, "Title must be at least 2 characters"),
  slug: z.string().min(2, "Slug must be at least 2 characters"),
  description: z.string().optional(),
  category: z.string().optional(),
  duration: z.string().optional(),
  requiredPandits: z.string().optional().default("1"),
  basePrice: z.coerce.number().min(0, "Base price must be positive"),
  samagriPrice: z.coerce.number().min(0, "Samagri price must be positive").default(0),
  durationMinutes: z.coerce.number().int().min(10, "Duration minutes must be at least 10"),
  imageUrl: z.string().url().optional(),
  isActive: z.boolean().default(true),
});

export const adminUpdatePoojaSchema = adminCreatePoojaSchema.partial();

