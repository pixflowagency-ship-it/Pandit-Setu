import type { RequestHandler } from "express";
import type { UserRole } from "../db/schema/enums.js";
export declare function requireRole(allowedRoles: UserRole[]): RequestHandler;
//# sourceMappingURL=require-role.d.ts.map