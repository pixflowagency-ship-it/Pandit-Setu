import type { Request, Response } from 'express';
/**
 * GET /api/v1/products
 * Returns all active products.
 */
export declare const getProductsHandler: (req: Request, res: Response) => Promise<Response<import("../types/auth.js").ApiErrorResponse, Record<string, any>> | Response<import("../types/auth.js").ApiSuccessResponse<{
    id: string;
    name: string;
    createdAt: Date;
    description: string | null;
    imageUrl: string | null;
    isActive: boolean;
    price: string;
    category: string;
    badge: string | null;
    samagri: string[];
}[]>, Record<string, any>>>;
//# sourceMappingURL=products.controller.d.ts.map