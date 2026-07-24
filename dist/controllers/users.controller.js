import { db, users } from '../db/index.js';
import { eq } from 'drizzle-orm';
import { sendSuccess, sendError } from '../utils/response.js';
import { AppError } from '../utils/api-error.js';
import { updateProfileSchema } from '../validators/users.validator.js';
/**
 * GET /api/v1/users/profile
 * Returns the authenticated user's profile.
 */
export const getProfileHandler = async (req, res) => {
    const userId = req.user?.id;
    if (!userId) {
        return sendError(res, 401, { code: 'UNAUTHORIZED', message: 'User not authenticated' });
    }
    const user = await db.query.users.findFirst({ where: eq(users.id, userId) });
    if (!user) {
        return sendError(res, 404, { code: 'USER_NOT_FOUND', message: 'User not found' });
    }
    const { id, phone, name, role, dob, tob, pob, gotra, zodiac, city, email } = user;
    return sendSuccess(res, { id, phone, fullName: name, role, dob, tob, pob, gotra, zodiac, city, email });
};
/**
 * PUT /api/v1/users/profile
 * Updates allowed profile fields for the authenticated user.
 */
export const updateProfileHandler = async (req, res) => {
    const userId = req.user?.id;
    if (!userId) {
        return sendError(res, 401, { code: 'UNAUTHORIZED', message: 'User not authenticated' });
    }
    const parsed = updateProfileSchema.safeParse(req.body);
    if (!parsed.success) {
        return sendError(res, 400, { code: 'INVALID_BODY', message: 'Invalid request data', details: parsed.error.format() });
    }
    const { fullName, email, dob, tob, pob, gotra, zodiac, city } = parsed.data;
    const updateObj = {};
    if (fullName)
        updateObj.name = fullName.trim();
    if (email)
        updateObj.email = email.trim();
    if (dob)
        updateObj.dob = dob;
    if (tob)
        updateObj.tob = tob;
    if (pob)
        updateObj.pob = pob;
    if (gotra)
        updateObj.gotra = gotra;
    if (zodiac)
        updateObj.zodiac = zodiac;
    if (city)
        updateObj.city = city;
    if (Object.keys(updateObj).length === 0) {
        throw new AppError(400, 'NO_FIELDS', 'No updatable fields provided');
    }
    const [updatedUser] = await db
        .update(users)
        .set(updateObj)
        .where(eq(users.id, userId))
        .returning();
    return sendSuccess(res, { message: 'Profile updated', user: updatedUser });
};
//# sourceMappingURL=users.controller.js.map