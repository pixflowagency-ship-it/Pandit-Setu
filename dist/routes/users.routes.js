import { Router } from 'express';
import { verifyToken } from '../middleware/verify-token.js';
import { asyncHandler } from '../middleware/async-handler.js';
import { getProfileHandler, updateProfileHandler } from '../controllers/users.controller.js';
export const usersRouter = Router();
usersRouter.get('/profile', verifyToken, asyncHandler(getProfileHandler));
usersRouter.put('/profile', verifyToken, asyncHandler(updateProfileHandler));
//# sourceMappingURL=users.routes.js.map