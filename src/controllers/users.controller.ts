import type { RequestHandler } from "express";
import { db, users } from "../db/index.js";
import { eq } from "drizzle-orm";
import { sendSuccess } from "../utils/response.js";
import { AppError } from "../utils/api-error.js";
import type { UpdateProfileInput } from "../validators/users.validator.js";

export const getProfileHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "User not authenticated");
  }

  const user = await db.query.users.findFirst({
    where: eq(users.id, req.user.id),
  });

  if (!user) {
    throw new AppError(404, "USER_NOT_FOUND", "User not found");
  }

  sendSuccess(res, {
    id: user.id,
    phone: user.phone,
    fullName: user.name,
    role: user.role,
    dob: user.dob,
    tob: user.tob,
    pob: user.pob,
    gotra: user.gotra,
    zodiac: user.zodiac,
    city: user.city,
    email: user.email,
  });
};

export const updateProfileHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "User not authenticated");
  }

  const { fullName, email, dob, tob, pob, gotra, zodiac, city } =
    req.body as UpdateProfileInput;

  const updateObj: Partial<Record<string, string>> = {};
  if (fullName) updateObj.name = fullName.trim();
  if (email) updateObj.email = email.trim();
  if (dob) updateObj.dob = dob;
  if (tob) updateObj.tob = tob;
  if (pob) updateObj.pob = pob;
  if (gotra) updateObj.gotra = gotra;
  if (zodiac) updateObj.zodiac = zodiac;
  if (city) updateObj.city = city;

  if (Object.keys(updateObj).length === 0) {
    throw new AppError(400, "NO_FIELDS", "No updatable fields provided");
  }

  const [updatedUser] = await db
    .update(users)
    .set(updateObj)
    .where(eq(users.id, req.user.id))
    .returning();

  sendSuccess(res, { message: "Profile updated", user: updatedUser });
};

export const updateFcmTokenHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const { token } = req.body as { token: string };

  const [updatedUser] = await db
    .update(users)
    .set({
      fcmToken: token,
      updatedAt: new Date(),
    })
    .where(eq(users.id, req.user.id))
    .returning();

  if (!updatedUser) {
    throw new AppError(404, "NOT_FOUND", "User not found");
  }

  sendSuccess(res, { message: "FCM token updated successfully" });
};
