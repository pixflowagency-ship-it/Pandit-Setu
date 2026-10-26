import { RequestHandler } from "express";
import { createReadStream } from "fs";
import { sendSuccess } from "../utils/response.js";
import { AppError } from "../utils/api-error.js";
import {
  getAdminStats,
  getAdminPanditApplications,
  getAdminPanditDetail,
  getAdminSubscriptions,
  adminApprovePandit,
  adminVerifyDocument,
  adminVerifyVideo,
  adminReviewMantraRecording,
  getPanditDocumentStream,
  getPanditMantraStream,
  getAllMantrasAdmin,
  adminCreateMantra,
  adminUpdateMantra,
  adminDeleteMantra,
} from "../services/admin.service.js";
import {
  adminListPanditsQuerySchema,
  adminListSubscriptionsQuerySchema,
} from "../validators/admin.validator.js";
import {
  createMantraSchema,
  updateMantraSchema,
} from "../validators/pandits.validator.js";

export const getAdminStatsHandler: RequestHandler = async (_req, res) => {
  const stats = await getAdminStats();
  sendSuccess(res, stats);
};

export const getAdminPanditsHandler: RequestHandler = async (req, res) => {
  const query = adminListPanditsQuerySchema.parse(req.query);
  const result = await getAdminPanditApplications(query);
  sendSuccess(res, result);
};

export const getAdminPanditDetailHandler: RequestHandler = async (req, res) => {
  const panditId = req.params.panditId as string;
  const result = await getAdminPanditDetail(panditId);
  sendSuccess(res, result);
};

export const getAdminSubscriptionsHandler: RequestHandler = async (req, res) => {
  const query = adminListSubscriptionsQuerySchema.parse(req.query);
  const result = await getAdminSubscriptions(query);
  sendSuccess(res, result);
};

export const adminApprovePanditHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const panditId = req.params.panditId as string;
  const { status, rejectionReason } = req.body as {
    status: "APPROVED" | "REJECTED";
    rejectionReason?: string;
  };

  const result = await adminApprovePandit(req.user.id, panditId, status, rejectionReason);
  sendSuccess(res, result);
};

export const adminVerifyDocumentHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const documentId = req.params.documentId as string;
  const { status, rejectionReason } = req.body as {
    status: "VERIFIED" | "REJECTED";
    rejectionReason?: string;
  };

  const result = await adminVerifyDocument(req.user.id, documentId, status, rejectionReason);
  sendSuccess(res, result);
};

export const adminVerifyVideoHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const panditId = req.params.panditId as string;
  const { status, notes } = req.body as {
    status: "COMPLETED" | "MISSED";
    notes?: string;
  };

  const result = await adminVerifyVideo(req.user.id, panditId, status, notes);
  sendSuccess(res, result);
};

export const adminDownloadDocumentHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const documentId = req.params.documentId as string;
  const { filePath, mimeType, fileName } = await getPanditDocumentStream(
    req.user.id,
    "ADMIN",
    documentId
  );

  res.setHeader("Content-Type", mimeType);
  res.setHeader("Content-Disposition", `inline; filename="${fileName}"`);

  const stream = createReadStream(filePath);
  stream.pipe(res);
};

export const adminReviewMantraRecordingHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const panditId = req.params.panditId as string;
  const recordingId = req.params.recordingId as string;
  const { status, notes, rejectionReason } = req.body as {
    status: "APPROVED" | "REJECTED" | "RESUBMISSION_REQUIRED";
    notes?: string;
    rejectionReason?: string;
  };

  const result = await adminReviewMantraRecording(
    req.user.id,
    panditId,
    recordingId,
    status,
    notes,
    rejectionReason
  );
  sendSuccess(res, result);
};

export const adminStreamMantraRecordingHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const panditId = req.params.panditId as string;
  const recordingId = req.params.recordingId as string;

  const { filePath, mimeType, fileName, fileSize } = await getPanditMantraStream(
    req.user.id,
    "ADMIN",
    panditId,
    recordingId
  );

  const effectiveSize = fileSize || 0;
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

export const getAdminMantrasHandler: RequestHandler = async (_req, res) => {
  const mantras = await getAllMantrasAdmin();
  sendSuccess(res, mantras);
};

export const createAdminMantraHandler: RequestHandler = async (req, res) => {
  const parsed = createMantraSchema.parse(req.body);
  const created = await adminCreateMantra(parsed);
  sendSuccess(res, created, 201);
};

export const updateAdminMantraHandler: RequestHandler = async (req, res) => {
  const mantraId = req.params.mantraId as string;
  const parsed = updateMantraSchema.parse(req.body);
  const updated = await adminUpdateMantra(mantraId, parsed);
  sendSuccess(res, updated);
};

export const deleteAdminMantraHandler: RequestHandler = async (req, res) => {
  const mantraId = req.params.mantraId as string;
  const result = await adminDeleteMantra(mantraId);
  sendSuccess(res, result);
};
