import type { RequestHandler } from "express";
import type { ZodSchema } from "zod";
export declare function validateBody<T>(schema: ZodSchema<T>): RequestHandler;
export declare function asyncHandler(handler: RequestHandler): RequestHandler;
//# sourceMappingURL=async-handler.d.ts.map