import jwt from "jsonwebtoken";
import { env } from "../config/env.js";
import { AppError } from "../utils/api-error.js";
export function signToken(payload) {
    const options = {
        expiresIn: env.jwtExpiresIn,
    };
    return jwt.sign(payload, env.jwtSecret, options);
}
export function verifyToken(token) {
    try {
        const decoded = jwt.verify(token, env.jwtSecret);
        if (typeof decoded !== "object" ||
            decoded === null ||
            !("id" in decoded) ||
            !("phone" in decoded) ||
            !("role" in decoded)) {
            throw new AppError(401, "INVALID_TOKEN", "Token payload is malformed");
        }
        return {
            id: String(decoded.id),
            phone: String(decoded.phone),
            role: decoded.role,
        };
    }
    catch (error) {
        if (error instanceof AppError) {
            throw error;
        }
        if (error instanceof jwt.TokenExpiredError) {
            throw new AppError(401, "TOKEN_EXPIRED", "Authentication token has expired");
        }
        if (error instanceof jwt.JsonWebTokenError) {
            throw new AppError(401, "INVALID_TOKEN", "Authentication token is invalid");
        }
        throw new AppError(401, "AUTH_FAILED", "Authentication failed");
    }
}
//# sourceMappingURL=jwt.service.js.map