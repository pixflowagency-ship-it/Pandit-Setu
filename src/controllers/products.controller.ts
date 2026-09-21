import type { RequestHandler } from "express";
import { db, products } from "../db/index.js";
import { eq, count } from "drizzle-orm";
import { sendSuccess } from "../utils/response.js";
import {
  paginationMeta,
  paginatedResponse,
  type PaginationQuery,
} from "../utils/pagination.js";

export const getProductsHandler: RequestHandler = async (req, res) => {
  const query = req.validatedQuery as PaginationQuery;
  const { page, limit, offset } = paginationMeta(query);

  const [items, [{ total }]] = await Promise.all([
    db
      .select()
      .from(products)
      .where(eq(products.isActive, true))
      .limit(limit)
      .offset(offset),
    db
      .select({ total: count() })
      .from(products)
      .where(eq(products.isActive, true)),
  ]);

  sendSuccess(res, paginatedResponse(items, total, page, limit));
};
