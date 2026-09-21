import type { RequestHandler } from "express";
import { sendSuccess } from "../utils/response.js";
import { AppError } from "../utils/api-error.js";
import { createRazorpayOrder, verifyPaymentSignature, handleWebhookEvent } from "../services/payments.service.js";

export const createOrderHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const body = req.body as { bookingId: string };
  
  const order = await createRazorpayOrder(req.user.id, body.bookingId);

  sendSuccess(res, { order });
};

export const verifyPaymentHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const { orderId, paymentId, signature } = req.body as { orderId: string; paymentId: string; signature: string };
  
  const booking = await verifyPaymentSignature(req.user.id, orderId, paymentId, signature);

  sendSuccess(res, { booking });
};

export const webhookHandler: RequestHandler = async (req, res) => {
  const signature = req.headers["x-razorpay-signature"] as string;
  if (!signature) {
    throw new AppError(401, "UNAUTHORIZED", "Missing signature");
  }

  // req.body is a raw Buffer because of express.raw()
  const rawBody = req.body;
  
  if (!Buffer.isBuffer(rawBody)) {
    throw new AppError(400, "BAD_REQUEST", "Body must be raw buffer");
  }

  const event = JSON.parse(rawBody.toString("utf-8"));

  await handleWebhookEvent(event, signature, rawBody);

  res.status(200).json({ status: "ok" });
};
