import { z } from "zod";

const MAX_LIMIT = 50;
const DEFAULT_LIMIT = 20;
const DEFAULT_PAGE = 1;

/** GET /products query params with filtering and pagination. */
export const listProductsQuerySchema = z
  .object({
    page: z.coerce.number().int().min(1).default(DEFAULT_PAGE),
    limit: z.coerce.number().int().min(1).max(MAX_LIMIT).default(DEFAULT_LIMIT),
    category: z.string().optional(),
    subCategory: z.string().optional(),
    search: z.string().optional(),
    status: z.string().optional(),
  })
  .strict();

export type ListProductsQuery = z.infer<typeof listProductsQuerySchema>;

/** GET /products/:id route params. */
export const getProductByIdParamsSchema = z.object({
  id: z.string().min(1),
});

export type GetProductByIdParams = z.infer<typeof getProductByIdParamsSchema>;
