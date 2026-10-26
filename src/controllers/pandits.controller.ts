import type { RequestHandler } from "express";
import { sendSuccess } from "../utils/response.js";
import { AppError } from "../utils/api-error.js";
import { getNearbyPandits, updateDutyStatus, acceptBooking, declineBooking, getPanditDashboard } from "../services/pandits.service.js";

export const getNearbyPanditsHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const query = req.validatedQuery as { lat: number; lng: number; radiusKm: number };
  
  const pandits = await getNearbyPandits(query.lat, query.lng, query.radiusKm);

  sendSuccess(res, { pandits });
};

export const updateDutyStatusHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const body = req.body as { isAvailable: boolean; lat?: number; lng?: number };
  
  const pandit = await updateDutyStatus(req.user.id, body.isAvailable, body.lat, body.lng);

  sendSuccess(res, { pandit });
};

export const acceptBookingHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const body = req.body as { bookingId: string };
  
  const booking = await acceptBooking(req.user.id, body.bookingId);

  sendSuccess(res, { booking });
};

export const declineBookingHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const body = req.body as { bookingId: string; reason?: "TOO_FAR" | "BUSY" | "SCHEDULE_CONFLICT" | "OTHER"; notes?: string };
  
  const decline = await declineBooking(req.user.id, body.bookingId, body.reason, body.notes);

  sendSuccess(res, { decline });
};

export const getPanditDashboardHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }
  
  const dashboard = await getPanditDashboard(req.user.id);

  sendSuccess(res, { dashboard });
};

export const applyForPanditHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const { applyForPandit } = await import("../services/auth.service.js");
  const result = await applyForPandit(req.user.id);

  sendSuccess(res, result);
};

export const getOnboardingStatusHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const { getOnboardingStatus } = await import("../services/pandit-verification.service.js");
  const status = await getOnboardingStatus(req.user.id);

  sendSuccess(res, status);
};

export const updatePanditProfileHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const { updatePanditProfile } = await import("../services/pandit-verification.service.js");
  const status = await updatePanditProfile(req.user.id, req.body);

  sendSuccess(res, status);
};

export const uploadPanditDocumentHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const { uploadPanditDocument } = await import("../services/pandit-verification.service.js");
  const doc = await uploadPanditDocument(req.user.id, req.body);

  sendSuccess(res, doc, 201);
};

export const downloadPanditDocumentHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const documentId = req.params.id as string;
  const { getPanditDocumentStream } = await import("../services/pandit-verification.service.js");
  const { filePath, mimeType, fileName } = await getPanditDocumentStream(
    req.user.id,
    req.user.role,
    documentId
  );

  res.setHeader("Content-Type", mimeType);
  res.setHeader("Content-Disposition", `inline; filename="${fileName}"`);

  const { createReadStream } = await import("fs");
  const stream = createReadStream(filePath);
  stream.pipe(res);
};

export const deletePanditDocumentHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const documentId = req.params.id as string;
  const { deletePanditDocument } = await import("../services/pandit-verification.service.js");
  const result = await deletePanditDocument(req.user.id, documentId);

  sendSuccess(res, result);
};

export const submitDocumentsForReviewHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const { submitDocumentsForReview } = await import("../services/pandit-verification.service.js");
  const status = await submitDocumentsForReview(req.user.id);

  sendSuccess(res, status);
};

export const scheduleVideoVerificationHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const { scheduleVideoVerification } = await import("../services/pandit-verification.service.js");
  const result = await scheduleVideoVerification(req.user.id, req.body);

  sendSuccess(res, result);
};

export const adminVerifyDocumentHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const documentId = req.params.documentId as string;
  const { status, rejectionReason } = req.body as { status: "VERIFIED" | "REJECTED"; rejectionReason?: string };
  const { adminVerifyDocument } = await import("../services/pandit-verification.service.js");
  const result = await adminVerifyDocument(req.user.id, documentId, status, rejectionReason);

  sendSuccess(res, result);
};

export const adminVerifyVideoHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const panditId = req.params.panditId as string;
  const { status, notes } = req.body as { status: "COMPLETED" | "MISSED"; notes?: string };
  const { adminVerifyVideo } = await import("../services/pandit-verification.service.js");
  const result = await adminVerifyVideo(req.user.id, panditId, status, notes);

  sendSuccess(res, result);
};

export const adminApprovePanditHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const panditId = req.params.panditId as string;
  const { status, rejectionReason } = req.body as { status: "APPROVED" | "REJECTED"; rejectionReason?: string };
  const { adminApprovePandit } = await import("../services/pandit-verification.service.js");
  const result = await adminApprovePandit(req.user.id, panditId, status, rejectionReason);

  sendSuccess(res, result);
};

export const recordPanditTelemetryHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const { recordPanditTelemetry } = await import("../services/tracking.service.js");
  const result = await recordPanditTelemetry(req.user.id, req.body);

  sendSuccess(res, result);
};

export const getApprovedMantrasHandler: RequestHandler = async (_req, res) => {
  const { getApprovedMantras } = await import("../services/pandit-verification.service.js");
  const mantras = await getApprovedMantras();
  sendSuccess(res, { mantras });
};

export const setVerificationMethodHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const { setVerificationMethod } = await import("../services/pandit-verification.service.js");
  const result = await setVerificationMethod(req.user.id, req.body.method);

  sendSuccess(res, result);
};

export const uploadMantraRecordingHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const { uploadMantraRecording } = await import("../services/pandit-verification.service.js");
  const recording = await uploadMantraRecording(req.user.id, req.body);

  sendSuccess(res, { recording }, 201);
};

export const getPanditMantraRecordingsHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const { getPanditMantraRecordings } = await import("../services/pandit-verification.service.js");
  const recordings = await getPanditMantraRecordings(req.user.id);

  sendSuccess(res, { recordings });
};

export const streamPanditMantraRecordingHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const recordingId = req.params.recordingId as string;
  const { db } = await import("../db/index.js");
  const { pandits } = await import("../db/schema/pandits.js");
  const { eq } = await import("drizzle-orm");

  const pandit = await db.query.pandits.findFirst({
    where: eq(pandits.userId, req.user.id),
  });

  if (!pandit) {
    throw new AppError(404, "NOT_FOUND", "Pandit profile not found");
  }

  const { getPanditMantraStream } = await import("../services/pandit-verification.service.js");
  const { filePath, mimeType, fileName, fileSize } = await getPanditMantraStream(
    req.user.id,
    req.user.role,
    pandit.id,
    recordingId
  );

  const effectiveSize = fileSize || 0;
  const { createReadStream } = await import("fs");
  const range = req.headers.range;

  if (range) {
    const parts = range.replace(/bytes=/, "").split("-");
    const start = parseInt(parts[0], 10);
    const end = parts[1] ? parseInt(parts[1], 10) : effectiveSize - 1;
    const chunksize = end - start + 1;
    const file = createReadStream(filePath, { start, end });
    res.writeHead(206, {
      "Content-Range": `bytes ${start}-${end}/${effectiveSize}`,
      "Accept-Ranges": "bytes",
      "Content-Length": chunksize,
      "Content-Type": mimeType,
    });
    file.pipe(res);
  } else {
    res.writeHead(200, {
      "Content-Length": effectiveSize,
      "Content-Type": mimeType,
      "Content-Disposition": `inline; filename="${fileName}"`,
      "Accept-Ranges": "bytes",
    });
    createReadStream(filePath).pipe(res);
  }
};


