import type { JwtPayload } from "./auth.js";

declare global {
  namespace Express {
    interface Request {
      user?: JwtPayload;
      rawToken?: string;
      validatedQuery?: unknown;
      validatedParams?: unknown;
    }
  }
}

export {};
