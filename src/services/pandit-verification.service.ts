import fs from "fs";
import path from "path";
import crypto from "crypto";
import { eq, and } from "drizzle-orm";
import { db } from "../db/index.js";
import { pandits, panditDocuments } from "../db/schema/pandits.js";
import { AppError } from "../utils/api-error.js";
import { logger } from "../utils/logger.js";
import type { DocType } from "../db/schema/enums.js";

const STORAGE_ROOT = path.resolve(process.cwd(), "storage", "documents");

// Ensure secure storage directory exists
if (!fs.existsSync(STORAGE_ROOT)) {
  fs.mkdirSync(STORAGE_ROOT, { recursive: true, mode: 0o700 });
}

// Magic bytes validator for secure file verification
function validateMagicBytes(buffer: Buffer, mimeType: string): boolean {
  if (buffer.length < 4) return false;

  if (mimeType === "application/pdf") {
    // PDF magic bytes: %PDF (0x25 0x50 0x44 0x46)
    return buffer[0] === 0x25 && buffer[1] === 0x50 && buffer[2] === 0x44 && buffer[3] === 0x46;
  }

  if (mimeType === "image/png") {
    // PNG magic bytes: \x89PNG (0x89 0x50 0x4E 0x47)
    return buffer[0] === 0x89 && buffer[1] === 0x50 && buffer[2] === 0x4E && buffer[3] === 0x47;
  }

  if (mimeType === "image/jpeg" || mimeType === "image/jpg") {
    // JPEG magic bytes: 0xFF 0xD8 0xFF
    return buffer[0] === 0xFF && buffer[1] === 0xD8 && buffer[2] === 0xFF;
  }

  return false;
}

export async function getOnboardingStatus(userId: string) {
  const pandit = await db.query.pandits.findFirst({
    where: eq(pandits.userId, userId),
  });

  if (!pandit) {
    throw new AppError(404, "NOT_FOUND", "Pandit profile not found for this user");
  }

  const docs = await db.query.panditDocuments.findMany({
    where: eq(panditDocuments.panditId, pandit.id),
    orderBy: (docs, { desc }) => [desc(docs.createdAt)],
  });

  return {
    panditId: pandit.id,
    verificationStatus: pandit.verificationStatus,
    verificationStage: pandit.verificationStage || "STAGE_1_COMPLETE",
    isVerified: pandit.isVerified,
    rejectionReason: pandit.rejectionReason,
    profile: {
      experienceYears: pandit.experienceYears,
      vedicSpecialization: pandit.vedicSpecialization,
      languages: pandit.languages || [],
      bio: pandit.bio,
      serviceRadiusKm: pandit.serviceRadiusKm,
      latitude: pandit.latitude,
      longitude: pandit.longitude,
    },
    documents: docs.map((d) => ({
      id: d.id,
      docType: d.docType,
      fileName: d.fileName || `${d.docType.toLowerCase()}.pdf`,
      fileSize: d.fileSize,
      mimeType: d.mimeType,
      docNumber: d.docNumber ? `•••• ${d.docNumber.slice(-4)}` : null,
      status: d.status,
      rejectionReason: d.rejectionReason,
      createdAt: d.createdAt,
    })),
    videoVerification: {
      status: pandit.videoCallStatus || "PENDING",
      scheduledAt: pandit.videoScheduledAt,
      roomId: pandit.videoCallRoomId,
      verifierNotes: pandit.videoVerifierNotes,
    },
    canAccessDashboard: pandit.verificationStatus === "APPROVED" && pandit.isVerified === true,
  };
}

export async function updatePanditProfile(
  userId: string,
  data: {
    experienceYears?: number;
    vedicSpecialization?: string;
    languages?: string[];
    bio?: string;
    serviceRadiusKm?: number;
    latitude?: number;
    longitude?: number;
  }
) {
  const pandit = await db.query.pandits.findFirst({
    where: eq(pandits.userId, userId),
  });

  if (!pandit) {
    throw new AppError(404, "NOT_FOUND", "Pandit profile not found");
  }

  const nextStage =
    pandit.verificationStage === "STAGE_1_COMPLETE"
      ? "PROFILE_COMPLETE"
      : pandit.verificationStage;

  const [updated] = await db
    .update(pandits)
    .set({
      ...data,
      verificationStage: nextStage,
      updatedAt: new Date(),
    })
    .where(eq(pandits.id, pandit.id))
    .returning();

  return getOnboardingStatus(userId);
}

export async function uploadPanditDocument(
  userId: string,
  input: {
    docType: DocType;
    fileName: string;
    mimeType: string;
    fileDataBase64: string;
    docNumber?: string;
  }
) {
  const pandit = await db.query.pandits.findFirst({
    where: eq(pandits.userId, userId),
  });

  if (!pandit) {
    throw new AppError(404, "NOT_FOUND", "Pandit profile not found");
  }

  const allowedMimes = ["application/pdf", "image/jpeg", "image/png", "image/jpg"];
  if (!allowedMimes.includes(input.mimeType.toLowerCase())) {
    throw new AppError(
      400,
      "INVALID_FILE_TYPE",
      "Only PDF, PNG, and JPEG documents are accepted for verification."
    );
  }

  // Decode base64
  let fileBuffer: Buffer;
  try {
    const cleanBase64 = input.fileDataBase64.replace(/^data:[^;]+;base64,/, "");
    fileBuffer = Buffer.from(cleanBase64, "base64");
  } catch (err) {
    throw new AppError(400, "INVALID_FILE_DATA", "Failed to decode base64 document data");
  }

  // Validate size (max 5 MB)
  const maxSize = 5 * 1024 * 1024;
  if (fileBuffer.length > maxSize) {
    throw new AppError(400, "FILE_TOO_LARGE", "Document file size exceeds maximum limit of 5MB");
  }

  if (fileBuffer.length < 100) {
    throw new AppError(400, "INVALID_FILE", "File is empty or corrupted");
  }

  // Validate magic bytes
  const isValidContent = validateMagicBytes(fileBuffer, input.mimeType.toLowerCase());
  if (!isValidContent) {
    throw new AppError(
      400,
      "CONTENT_VALIDATION_FAILED",
      "File content does not match the stated format (PDF/JPEG/PNG signature verification failed)"
    );
  }

  // Secure isolated directory per Pandit
  const panditDir = path.join(STORAGE_ROOT, pandit.id);
  if (!fs.existsSync(panditDir)) {
    fs.mkdirSync(panditDir, { recursive: true, mode: 0o700 });
  }

  const fileExt = input.mimeType === "application/pdf" ? ".pdf" : input.mimeType.includes("png") ? ".png" : ".jpg";
  const safeUniqueKey = `${input.docType.toLowerCase()}_${Date.now()}_${crypto.randomBytes(6).toString("hex")}${fileExt}`;
  const filePath = path.join(panditDir, safeUniqueKey);

  // Write file securely
  fs.writeFileSync(filePath, fileBuffer, { mode: 0o600 });

  // Store metadata in database with status PENDING
  const [createdDoc] = await db
    .insert(panditDocuments)
    .values({
      panditId: pandit.id,
      docType: input.docType,
      docUrl: safeUniqueKey, // Private storage key, NOT a public URL
      docNumber: input.docNumber?.trim() || null,
      fileName: input.fileName.trim().slice(0, 250),
      fileSize: fileBuffer.length,
      mimeType: input.mimeType.toLowerCase(),
      status: "PENDING",
    })
    .returning();

  logger.info({ panditId: pandit.id, docType: input.docType }, "Verification document uploaded securely");

  return {
    id: createdDoc.id,
    docType: createdDoc.docType,
    fileName: createdDoc.fileName,
    fileSize: createdDoc.fileSize,
    mimeType: createdDoc.mimeType,
    status: createdDoc.status,
    createdAt: createdDoc.createdAt,
  };
}

export async function getPanditDocumentStream(userId: string, userRole: string, documentId: string) {
  const doc = await db.query.panditDocuments.findFirst({
    where: eq(panditDocuments.id, documentId),
  });

  if (!doc) {
    throw new AppError(404, "NOT_FOUND", "Document not found");
  }

  const pandit = await db.query.pandits.findFirst({
    where: eq(pandits.id, doc.panditId),
  });

  if (!pandit) {
    throw new AppError(404, "NOT_FOUND", "Pandit associated with document not found");
  }

  // Strictly enforce that only the owner or an ADMIN can access this private document
  if (userRole !== "ADMIN" && pandit.userId !== userId) {
    throw new AppError(403, "FORBIDDEN", "Access denied to private document of another Pandit");
  }

  const filePath = path.join(STORAGE_ROOT, pandit.id, doc.docUrl);
  if (!fs.existsSync(filePath)) {
    throw new AppError(404, "NOT_FOUND", "Document file not found on server storage");
  }

  return {
    filePath,
    mimeType: doc.mimeType || "application/octet-stream",
    fileName: doc.fileName || `${doc.docType.toLowerCase()}.pdf`,
  };
}

export async function deletePanditDocument(userId: string, documentId: string) {
  const pandit = await db.query.pandits.findFirst({
    where: eq(pandits.userId, userId),
  });

  if (!pandit) {
    throw new AppError(404, "NOT_FOUND", "Pandit profile not found");
  }

  const doc = await db.query.panditDocuments.findFirst({
    where: and(eq(panditDocuments.id, documentId), eq(panditDocuments.panditId, pandit.id)),
  });

  if (!doc) {
    throw new AppError(404, "NOT_FOUND", "Document not found or access denied");
  }

  // Remove physical file
  const filePath = path.join(STORAGE_ROOT, pandit.id, doc.docUrl);
  if (fs.existsSync(filePath)) {
    try {
      fs.unlinkSync(filePath);
    } catch (e) {
      logger.warn({ e, filePath }, "Could not unlink document file");
    }
  }

  await db.delete(panditDocuments).where(eq(panditDocuments.id, doc.id));

  return { success: true, message: "Document removed successfully" };
}

export async function submitDocumentsForReview(userId: string) {
  const pandit = await db.query.pandits.findFirst({
    where: eq(pandits.userId, userId),
  });

  if (!pandit) {
    throw new AppError(404, "NOT_FOUND", "Pandit profile not found");
  }

  // Strictly enforce that profile details cannot be skipped
  if (pandit.verificationStage === "STAGE_1_COMPLETE" || !pandit.bio || !pandit.experienceYears) {
    throw new AppError(
      400,
      "PROFILE_INCOMPLETE",
      "Please complete your Pandit professional profile before submitting documents for review."
    );
  }

  const docs = await db.query.panditDocuments.findMany({
    where: eq(panditDocuments.panditId, pandit.id),
  });

  const docTypes = new Set(docs.map((d) => d.docType));
  if (!docTypes.has("AADHAAR") || !docTypes.has("PAN")) {
    throw new AppError(
      400,
      "MISSING_REQUIRED_DOCUMENTS",
      "Both Aadhaar Card and PAN Card are mandatory before submitting for review."
    );
  }

  await db
    .update(pandits)
    .set({
      verificationStage: "DOCUMENTS_UNDER_REVIEW",
      updatedAt: new Date(),
    })
    .where(eq(pandits.id, pandit.id));

  return getOnboardingStatus(userId);
}

export async function scheduleVideoVerification(
  userId: string,
  data: { scheduledAt: string; preferredLanguage?: string }
) {
  const pandit = await db.query.pandits.findFirst({
    where: eq(pandits.userId, userId),
  });

  if (!pandit) {
    throw new AppError(404, "NOT_FOUND", "Pandit profile not found");
  }

  const scheduledDate = new Date(data.scheduledAt);
  if (isNaN(scheduledDate.getTime()) || scheduledDate.getTime() < Date.now()) {
    throw new AppError(400, "INVALID_DATETIME", "Please select a valid future date and time for verification.");
  }

  const roomId = `sarvmangal_verify_${pandit.id.replace(/-/g, "").slice(0, 12)}`;

  // Check if real Agora video provider credentials are ready
  let videoToken: string | null = null;
  let providerConfigured = false;

  if (process.env.AGORA_APP_ID && process.env.AGORA_APP_CERTIFICATE) {
    try {
      const { generateRtcToken } = await import("./agora.service.js");
      const { RtcRole } = await import("agora-token");
      const expireTime = Math.floor(scheduledDate.getTime() / 1000) + 7200; // 2 hour window
      videoToken = generateRtcToken(roomId, RtcRole.PUBLISHER, expireTime);
      providerConfigured = true;
    } catch (e) {
      logger.warn({ e }, "Agora token generation bypassed (provider credentials incomplete)");
    }
  }

  await db
    .update(pandits)
    .set({
      videoScheduledAt: scheduledDate,
      videoCallStatus: "SCHEDULED",
      videoCallRoomId: roomId,
      verificationStage: "VIDEO_VERIFICATION_SCHEDULED",
      updatedAt: new Date(),
    })
    .where(eq(pandits.id, pandit.id));

  return {
    scheduledAt: scheduledDate.toISOString(),
    status: "SCHEDULED",
    roomId,
    videoToken,
    providerConfigured,
    instructions: providerConfigured
      ? "Please be ready 5 minutes before scheduled time with original documents in a well-lit room."
      : "Your video verification slot has been booked. Live video SDK configuration is pending server credentials. A Sarv Mangal Acharya Coordinator will reach out via verified video bridge.",
  };
}

// Authorized Reviewer / Admin Actions
export async function adminVerifyDocument(
  reviewerId: string,
  documentId: string,
  status: "VERIFIED" | "REJECTED",
  rejectionReason?: string
) {
  const [updated] = await db
    .update(panditDocuments)
    .set({
      status,
      rejectionReason: status === "REJECTED" ? rejectionReason : null,
      updatedAt: new Date(),
    })
    .where(eq(panditDocuments.id, documentId))
    .returning();

  if (!updated) {
    throw new AppError(404, "NOT_FOUND", "Document not found");
  }

  return updated;
}

export async function adminVerifyVideo(
  reviewerId: string,
  panditId: string,
  status: "COMPLETED" | "MISSED",
  notes?: string
) {
  const pandit = await db.query.pandits.findFirst({
    where: eq(pandits.id, panditId),
  });

  if (!pandit) {
    throw new AppError(404, "NOT_FOUND", "Pandit not found");
  }

  const [updated] = await db
    .update(pandits)
    .set({
      videoCallStatus: status,
      videoVerifierId: reviewerId,
      videoVerifierNotes: notes || null,
      verificationStage: status === "COMPLETED" ? "VIDEO_VERIFICATION_COMPLETED" : "VIDEO_VERIFICATION_PENDING",
      updatedAt: new Date(),
    })
    .where(eq(pandits.id, panditId))
    .returning();

  return updated;
}

export async function adminApprovePandit(
  reviewerId: string,
  panditId: string,
  status: "APPROVED" | "REJECTED",
  rejectionReason?: string
) {
  const pandit = await db.query.pandits.findFirst({
    where: eq(pandits.id, panditId),
  });

  if (!pandit) {
    throw new AppError(404, "NOT_FOUND", "Pandit not found");
  }

  const isApproved = status === "APPROVED";

  // Prevent premature approval of an application that hasn't submitted documents/video
  if (isApproved && (pandit.verificationStage === "STAGE_1_COMPLETE" || pandit.verificationStage === "PROFILE_COMPLETE")) {
    throw new AppError(
      400,
      "INVALID_STATE_TRANSITION",
      "Cannot approve Pandit application before verification documents and review are completed."
    );
  }

  const [updated] = await db
    .update(pandits)
    .set({
      verificationStatus: status,
      isVerified: isApproved,
      verificationStage: isApproved ? "APPROVED" : "REJECTED",
      rejectionReason: isApproved ? null : rejectionReason || "Application requirements not fulfilled",
      approvedAt: isApproved ? new Date() : null,
      approvedBy: isApproved ? reviewerId : null,
      updatedAt: new Date(),
    })
    .where(eq(pandits.id, panditId))
    .returning();

  logger.info({ panditId, reviewerId, status }, "Pandit verification approval state changed by admin reviewer");

  return updated;
}
