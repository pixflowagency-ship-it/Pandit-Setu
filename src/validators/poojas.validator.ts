import { paginationQuerySchema } from "../utils/pagination.js";

/** GET /poojas query params — only page + limit allowed. */
export const listPoojasQuerySchema = paginationQuerySchema;
