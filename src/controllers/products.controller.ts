import type { Request, Response } from 'express';
import { db, products } from '../db/index.js';
import { eq } from 'drizzle-orm';
import { sendSuccess, sendError } from '../utils/response.js';

export const getProductsHandler = async (req: Request, res: Response) => {
  try {
    const rows = await db.query.products.findMany({ where: eq(products.isActive, true) });
    return sendSuccess(res, rows);
  } catch (err) {
    console.error('Error fetching products:', err);
    return sendError(res, 500, { code: 'SERVER_ERROR', message: 'Failed to fetch products' });
  }
};
