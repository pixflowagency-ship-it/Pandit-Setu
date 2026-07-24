import { Router } from 'express';
import { getProductsHandler } from '../controllers/products.controller.js';
const productsRouter = Router();
// GET /api/v1/products - fetch all active products
productsRouter.get('/', getProductsHandler);
export default productsRouter;
//# sourceMappingURL=products.routes.js.map