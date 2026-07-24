import { AppError } from "../utils/api-error.js";
export function validateBody(schema) {
    return (req, _res, next) => {
        const result = schema.safeParse(req.body);
        if (!result.success) {
            next(new AppError(400, "VALIDATION_ERROR", "Request validation failed", {
                fields: result.error.flatten().fieldErrors,
            }));
            return;
        }
        req.body = result.data;
        next();
    };
}
export function asyncHandler(handler) {
    return (req, res, next) => {
        Promise.resolve(handler(req, res, next)).catch(next);
    };
}
//# sourceMappingURL=async-handler.js.map