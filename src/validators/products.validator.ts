import { paginationQuerySchema } from "../utils/pagination.js";

/** GET /products query params — only page + limit allowed. */
export const listProductsQuerySchema = paginationQuerySchema;
