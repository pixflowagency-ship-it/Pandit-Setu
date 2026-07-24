import type { Request, Response } from 'express';
/**
 * GET /api/v1/users/profile
 * Returns the authenticated user's profile.
 */
export declare const getProfileHandler: (req: Request, res: Response) => Promise<Response<import("../types/auth.js").ApiErrorResponse, Record<string, any>> | Response<import("../types/auth.js").ApiSuccessResponse<{
    id: any;
    phone: any;
    fullName: any;
    role: any;
    dob: any;
    tob: any;
    pob: any;
    gotra: any;
    zodiac: any;
    city: any;
    email: any;
}>, Record<string, any>>>;
/**
 * PUT /api/v1/users/profile
 * Updates allowed profile fields for the authenticated user.
 */
export declare const updateProfileHandler: (req: Request, res: Response) => Promise<Response<import("../types/auth.js").ApiErrorResponse, Record<string, any>> | Response<import("../types/auth.js").ApiSuccessResponse<{
    message: string;
    user: {
        id: string;
        phone: string;
        name: string;
        dob: string | null;
        tob: string | null;
        pob: string | null;
        gotra: string | null;
        zodiac: string | null;
        city: string | null;
        email: string | null;
        profilePictureUrl: string | null;
        role: "YAJMAN" | "PANDIT" | "ADMIN";
        createdAt: Date;
        updatedAt: Date;
    };
}>, Record<string, any>>>;
//# sourceMappingURL=users.controller.d.ts.map