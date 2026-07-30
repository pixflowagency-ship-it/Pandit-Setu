import { Router } from 'express';
import { getProductsHandler } from '../controllers/products.controller.js';
const productsRouter = Router();
productsRouter.get('/', getProductsHandler);
export default productsRouter;
//# sourceMappingURL=products.routes.js.map