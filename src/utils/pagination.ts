import { z } from "zod";

const MAX_LIMIT = 50;
const DEFAULT_LIMIT = 20;
const DEFAULT_PAGE = 1;

/** Reusable Zod schema for pagination query parameters. */
export const paginationQuerySchema = z
  .object({
    page: z.coerce.number().int().min(1).default(DEFAULT_PAGE),
    limit: z.coerce.number().int().min(1).max(MAX_LIMIT).default(DEFAULT_LIMIT),
  })
  .strict();

export type PaginationQuery = z.infer<typeof paginationQuerySchema>;

/** Derive offset from validated page + limit. */
export function paginationMeta(query: PaginationQuery) {
  const { page, limit } = query;
  return { page, limit, offset: (page - 1) * limit };
}

/** Standard shape returned from any paginated endpoint. */
export function paginatedResponse<T>(
  items: T[],
  total: number,
  page: number,
  limit: number,
) {
  return {
    items,
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    },
  };
}
