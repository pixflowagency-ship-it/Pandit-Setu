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

