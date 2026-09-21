import type { RequestHandler } from "express";
import { db, poojas } from "../db/index.js";
import { eq, count } from "drizzle-orm";
import { sendSuccess } from "../utils/response.js";
import {
  paginationMeta,
  paginatedResponse,
  type PaginationQuery,
} from "../utils/pagination.js";

export const listPoojasHandler: RequestHandler = async (req, res) => {
  const query = req.validatedQuery as PaginationQuery;
  const { page, limit, offset } = paginationMeta(query);

  const [items, [{ total }]] = await Promise.all([
    db
      .select()
      .from(poojas)
      .where(eq(poojas.isActive, true))
      .limit(limit)
      .offset(offset),
    db.select({ total: count() }).from(poojas).where(eq(poojas.isActive, true)),
  ]);

  sendSuccess(res, paginatedResponse(items, total, page, limit));
};
