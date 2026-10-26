import { RequestHandler } from "express";
import { AppError } from "../utils/api-error.js";
import { sendSuccess } from "../utils/response.js";
import {
  createConsultation,
  getUserConsultations,
  getConsultationById,
  cancelConsultation,
  adminGetConsultations,
  adminScheduleConsultation,
  adminAssignPandit,
  adminUpdateConsultationStatus,
  createConsultationPaymentOrder,
  verifyConsultationPayment,
} from "../services/consultations.service.js";
import {
  listConsultationsQuerySchema,
} from "../validators/consultations.validator.js";

export const createConsultationHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const result = await createConsultation(req.user.id, req.body);
  sendSuccess(res, result, 201);
};

export const getMyConsultationsHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const page = req.query.page ? parseInt(req.query.page as string, 10) : 1;
  const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 20;

  const result = await getUserConsultations(req.user.id, { page, limit });
  sendSuccess(res, result);
};

export const getConsultationByIdHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const consultationId = req.params.id as string;
  const result = await getConsultationById(req.user.id, req.user.role, consultationId);
  sendSuccess(res, result);
};

export const cancelConsultationHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const consultationId = req.params.id as string;
  const { cancellationReason } = req.body as { cancellationReason: string };
  const result = await cancelConsultation(req.user.id, consultationId, cancellationReason);
  sendSuccess(res, result);
};

export const createConsultationPaymentOrderHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const consultationId = req.params.id as string;
  const result = await createConsultationPaymentOrder(req.user.id, consultationId);
  sendSuccess(res, result);
};

export const verifyConsultationPaymentHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const consultationId = req.params.id as string;
  const result = await verifyConsultationPayment(req.user.id, consultationId, req.body);
  sendSuccess(res, result);
};

// Admin Handlers
export const adminGetConsultationsHandler: RequestHandler = async (req, res) => {
  const query = listConsultationsQuerySchema.parse(req.query);
  const result = await adminGetConsultations(query);
  sendSuccess(res, result);
};

export const adminScheduleConsultationHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const consultationId = req.params.id as string;
  const { scheduledDateTime, notes } = req.body as {
    scheduledDateTime: string;
    notes?: string | null;
  };

  const result = await adminScheduleConsultation(
    req.user.id,
    consultationId,
    scheduledDateTime,
    notes
  );
  sendSuccess(res, result);
};

export const adminAssignPanditHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const consultationId = req.params.id as string;
  const { panditId } = req.body as { panditId: string };

  const result = await adminAssignPandit(req.user.id, consultationId, panditId);
  sendSuccess(res, result);
};

export const adminUpdateConsultationStatusHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const consultationId = req.params.id as string;
  const { status, reason } = req.body as {
    status: any;
    reason?: string | null;
  };

  const result = await adminUpdateConsultationStatus(
    req.user.id,
    consultationId,
    status,
    reason
  );
  sendSuccess(res, result);
};
