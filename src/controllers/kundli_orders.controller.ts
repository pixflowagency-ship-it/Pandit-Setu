import { RequestHandler } from "express";
import { AppError } from "../utils/api-error.js";
import { sendSuccess } from "../utils/response.js";
import {
  createKundliOrder,
  getUserKundliOrders,
  getKundliOrderById,
  cancelKundliOrder,
  adminGetKundliOrders,
  adminDecisionKundliOrder,
  adminAssignPanditToKundli,
  adminUpdateKundliStatus,
  createKundliPaymentOrder,
  verifyKundliPayment,
} from "../services/kundli_orders.service.js";
import {
  listKundliOrdersQuerySchema,
} from "../validators/kundli_orders.validator.js";

export const createKundliOrderHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const result = await createKundliOrder(req.user.id, req.body);
  sendSuccess(res, result, 201);
};

export const getMyKundliOrdersHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const page = req.query.page ? parseInt(req.query.page as string, 10) : 1;
  const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 20;

  const result = await getUserKundliOrders(req.user.id, { page, limit });
  sendSuccess(res, result);
};

export const getKundliOrderByIdHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const orderId = req.params.id as string;
  const result = await getKundliOrderById(req.user.id, req.user.role, orderId);
  sendSuccess(res, result);
};

export const cancelKundliOrderHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const orderId = req.params.id as string;
  const { cancellationReason } = req.body as { cancellationReason: string };
  const result = await cancelKundliOrder(req.user.id, orderId, cancellationReason);
  sendSuccess(res, result);
};

export const createKundliPaymentOrderHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const orderId = req.params.id as string;
  const result = await createKundliPaymentOrder(req.user.id, orderId);
  sendSuccess(res, result);
};

export const verifyKundliPaymentHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const orderId = req.params.id as string;
  const result = await verifyKundliPayment(req.user.id, orderId, req.body);
  sendSuccess(res, result);
};

// Admin Handlers
export const adminGetKundliOrdersHandler: RequestHandler = async (req, res) => {
  const query = listKundliOrdersQuerySchema.parse(req.query);
  const result = await adminGetKundliOrders(query);
  sendSuccess(res, result);
};

export const adminDecisionKundliOrderHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const orderId = req.params.id as string;
  const { decision, reason } = req.body as {
    decision: "ACCEPT" | "REJECT";
    reason?: string | null;
  };

  const result = await adminDecisionKundliOrder(req.user.id, orderId, decision, reason);
  sendSuccess(res, result);
};

export const adminAssignPanditToKundliHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const orderId = req.params.id as string;
  const { panditId } = req.body as { panditId: string };

  const result = await adminAssignPanditToKundli(req.user.id, orderId, panditId);
  sendSuccess(res, result);
};

export const adminUpdateKundliStatusHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const orderId = req.params.id as string;
  const result = await adminUpdateKundliStatus(req.user.id, orderId, req.body);
  sendSuccess(res, result);
};
