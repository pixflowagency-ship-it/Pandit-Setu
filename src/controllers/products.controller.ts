import type { RequestHandler } from "express";
import { db, products } from "../db/index.js";
import { eq, and, or, ilike, count, asc } from "drizzle-orm";
import { sendSuccess, sendError } from "../utils/response.js";
import {
  paginationMeta,
  paginatedResponse,
} from "../utils/pagination.js";
import type { ListProductsQuery } from "../validators/products.validator.js";

export const getProductsHandler: RequestHandler = async (req, res) => {
  const query = (req.validatedQuery || {}) as ListProductsQuery;
  const { page, limit, offset } = paginationMeta({
    page: query.page ?? 1,
    limit: query.limit ?? 20,
  });

  const conditions = [eq(products.isActive, true)];

  if (query.category && query.category !== "All") {
    conditions.push(ilike(products.category, `%${query.category.trim()}%`));
  }

  if (query.subCategory) {
    conditions.push(ilike(products.subCategory, `%${query.subCategory.trim()}%`));
  }

  if (query.search && query.search.trim()) {
    const term = `%${query.search.trim()}%`;
    conditions.push(
      or(
        ilike(products.name, term),
        ilike(products.description, term),
        ilike(products.searchTags, term),
        ilike(products.productId, term),
      )!,
    );
  }

  const whereClause = conditions.length === 1 ? conditions[0] : and(...conditions);

  const [items, [{ total }]] = await Promise.all([
    db
      .select()
      .from(products)
      .where(whereClause)
      .limit(limit)
      .offset(offset),
    db
      .select({ total: count() })
      .from(products)
      .where(whereClause),
  ]);

  sendSuccess(res, paginatedResponse(items, total, page, limit));
};

export const getProductByIdHandler: RequestHandler = async (req, res) => {
  const rawId = (req.validatedParams as { id?: string } | undefined)?.id || req.params.id;
  const id = Array.isArray(rawId) ? rawId[0] : String(rawId);

  const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id);
  const condition = isUuid ? eq(products.id, id) : eq(products.productId, id);

  const item = await db.query.products.findFirst({
    where: and(condition, eq(products.isActive, true)),
  });

  if (!item) {
    return sendError(res, 404, {
      code: "NOT_FOUND",
      message: `Product with identifier '${id}' not found`,
    });
  }

  sendSuccess(res, item);
};
