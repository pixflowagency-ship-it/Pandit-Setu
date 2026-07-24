import { z } from 'zod';
export declare const updateProfileSchema: z.ZodObject<{
    fullName: z.ZodOptional<z.ZodString>;
    email: z.ZodOptional<z.ZodString>;
    dob: z.ZodOptional<z.ZodString>;
    tob: z.ZodOptional<z.ZodString>;
    pob: z.ZodOptional<z.ZodString>;
    gotra: z.ZodOptional<z.ZodString>;
    zodiac: z.ZodOptional<z.ZodString>;
    city: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    dob?: string | undefined;
    tob?: string | undefined;
    pob?: string | undefined;
    gotra?: string | undefined;
    zodiac?: string | undefined;
    city?: string | undefined;
    email?: string | undefined;
    fullName?: string | undefined;
}, {
    dob?: string | undefined;
    tob?: string | undefined;
    pob?: string | undefined;
    gotra?: string | undefined;
    zodiac?: string | undefined;
    city?: string | undefined;
    email?: string | undefined;
    fullName?: string | undefined;
}>;
//# sourceMappingURL=users.validator.d.ts.map