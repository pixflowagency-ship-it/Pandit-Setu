import { eq } from "drizzle-orm";
import { db, users, pandits } from "../db/index.js";
import { AppError } from "../utils/api-error.js";
import {
  createOtp,
  getOtpExpirySeconds,
  normalizePhone,
  verifyOtp,
} from "./otp.service.js";
import { sendSmsOtp } from "./sms.service.js";
import { signToken } from "./jwt.service.js";
import { env } from "../config/env.js";
import { logger } from "../utils/logger.js";
import type { SendOtpResponse, VerifyOtpResponse } from "../types/auth.js";

export async function sendOtp(phone: string): Promise<SendOtpResponse> {
  const normalizedPhone = normalizePhone(phone);
  const otp = await createOtp(normalizedPhone);

  logger.info({ phone: normalizedPhone }, "OTP generated");

  await sendSmsOtp(normalizedPhone, otp);

  const response: SendOtpResponse = {
    message: "OTP sent successfully",
    expiresInSeconds: getOtpExpirySeconds(),
  };

  if (env.nodeEnv !== "production") {
    response.mockOtp = otp;
  }

  return response;
}

export async function verifyOtpAndLogin(
  phone: string,
  otp: string,
  name?: string,
  role: "YAJMAN" | "PANDIT" = "YAJMAN",
): Promise<VerifyOtpResponse> {
  const normalizedPhone = normalizePhone(phone);

  const isValid = await verifyOtp(normalizedPhone, otp);
  if (!isValid) {
    throw new AppError(
      401,
      "INVALID_OTP",
      "The OTP provided is invalid or has expired",
    );
  }

  const existingUser = await db.query.users.findFirst({
    where: eq(users.phone, normalizedPhone),
  });

  let user = existingUser;

  if (!user) {
    const finalName = name?.trim() || (role === "PANDIT" ? "Vedic Acharya" : "");
    if (!finalName) {
      throw new AppError(
        400,
        "NAME_REQUIRED",
        "Name is required for new user registration",
      );
    }

    const [createdUser] = await db
      .insert(users)
      .values({
        phone: normalizedPhone,
        name: finalName,
        role: role,
      })
      .returning();

    user = createdUser;

    if (role === "PANDIT") {
      const [initialPandit] = await db
        .insert(pandits)
        .values({
          userId: createdUser.id,
          vedicSpecialization: "Vedic Rituals & Karmakand",
          experienceYears: 1,
          verificationStatus: "PENDING",
          verificationStage: "STAGE_1_COMPLETE",
          isVerified: false,
        })
        .returning();

      const token = signToken({
        id: user.id,
        phone: user.phone,
        role: "PANDIT",
      });

      return {
        token,
        isPandit: true,
        user: {
          id: user.id,
          phone: user.phone,
          name: user.name,
          fullName: user.name,
          role: "PANDIT",
          dob: user.dob,
          tob: user.tob,
          pob: user.pob,
          gotra: user.gotra,
          zodiac: user.zodiac,
          city: user.city,
          email: user.email,
        },
        pandit: {
          id: initialPandit.id,
          verificationStatus: initialPandit.verificationStatus,
          verificationStage: initialPandit.verificationStage,
          isVerified: initialPandit.isVerified,
        },
      };
    }
  }

  // User exists - check Pandit profile existence
  const existingPandit = await db.query.pandits.findFirst({
    where: eq(pandits.userId, user.id),
  });

  if (role === "PANDIT") {
    // If user exists but has no pandit profile (Case A & E: Yajman trying to login to Pandit portal)
    if (!existingPandit) {
      const token = signToken({
        id: user.id,
        phone: user.phone,
        role: "YAJMAN",
      });

      return {
        token,
        isPandit: false,
        requiresApplication: true,
        user: {
          id: user.id,
          phone: user.phone,
          name: user.name,
          fullName: user.name,
          role: "YAJMAN",
          dob: user.dob,
          tob: user.tob,
          pob: user.pob,
          gotra: user.gotra,
          zodiac: user.zodiac,
          city: user.city,
          email: user.email,
        },
      };
    }

    // Existing Pandit logging in (Case B)
    const token = signToken({
      id: user.id,
      phone: user.phone,
      role: "PANDIT",
    });

    return {
      token,
      isPandit: true,
      user: {
        id: user.id,
        phone: user.phone,
        name: user.name,
        fullName: user.name,
        role: "PANDIT",
        dob: user.dob,
        tob: user.tob,
        pob: user.pob,
        gotra: user.gotra,
        zodiac: user.zodiac,
        city: user.city,
        email: user.email,
      },
      pandit: {
        id: existingPandit.id,
        verificationStatus: existingPandit.verificationStatus,
        verificationStage: existingPandit.verificationStage,
        isVerified: existingPandit.isVerified,
      },
    };
  }

  // Yajman / Admin Portal Login Context (Case C & E)
  const roleToIssue = user.role === "ADMIN" ? "ADMIN" : "YAJMAN";
  const token = signToken({
    id: user.id,
    phone: user.phone,
    role: roleToIssue,
  });

  return {
    token,
    hasPanditProfile: !!existingPandit,
    user: {
      id: user.id,
      phone: user.phone,
      name: user.name,
      fullName: user.name,
      role: roleToIssue,
      dob: user.dob,
      tob: user.tob,
      pob: user.pob,
      gotra: user.gotra,
      zodiac: user.zodiac,
      city: user.city,
      email: user.email,
    },
  };
}

export async function applyForPandit(userId: string) {
  const user = await db.query.users.findFirst({
    where: eq(users.id, userId),
  });

  if (!user) {
    throw new AppError(404, "NOT_FOUND", "User identity not found");
  }

  let pandit = await db.query.pandits.findFirst({
    where: eq(pandits.userId, userId),
  });

  if (!pandit) {
    const [newPandit] = await db
      .insert(pandits)
      .values({
        userId: user.id,
        vedicSpecialization: "Vedic Rituals & Karmakand",
        experienceYears: 1,
        verificationStatus: "PENDING",
        verificationStage: "STAGE_1_COMPLETE",
        isVerified: false,
      })
      .returning();

    pandit = newPandit;
  }

  const token = signToken({
    id: user.id,
    phone: user.phone,
    role: "PANDIT",
  });

  return {
    token,
    pandit: {
      id: pandit.id,
      verificationStatus: pandit.verificationStatus,
      verificationStage: pandit.verificationStage,
      isVerified: pandit.isVerified,
    },
  };
}
