import type { RequestHandler } from "express";
import { sendSuccess } from "../utils/response.js";
import { AppError } from "../utils/api-error.js";
import {
  createProductOrder,
  listProductOrders,
  getProductOrderById,
  createOrderPayment,
  verifyOrderPayment,
} from "../services/product-orders.service.js";
import type {
  CreateProductOrderInput,
  ListProductOrdersQuery,
  VerifyOrderPaymentInput,
} from "../validators/product-orders.validator.js";

export const createProductOrderHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const input = req.body as CreateProductOrderInput;
  const order = await createProductOrder(req.user.id, input);

  sendSuccess(res, { order }, 201);
};

export const listProductOrdersHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const query = (req.query || {}) as unknown as ListProductOrdersQuery;
  const result = await listProductOrders(req.user.id, query);

  sendSuccess(res, result);
};

export const getProductOrderByIdHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const orderId = req.params.id as string;
  const isAdmin = req.user.role === "ADMIN";
  const order = await getProductOrderById(orderId, req.user.id, isAdmin);

  sendSuccess(res, { order });
};

export const createOrderPaymentHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const orderId = req.params.id as string;
  const rzpOrder = await createOrderPayment(orderId, req.user.id);

  sendSuccess(res, { paymentOrder: rzpOrder });
};

export const verifyOrderPaymentHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const orderId = req.params.id as string;
  const input = req.body as VerifyOrderPaymentInput;
  const order = await verifyOrderPayment(orderId, req.user.id, input);

  sendSuccess(res, { order });
};
