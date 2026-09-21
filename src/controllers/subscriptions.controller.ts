import type { RequestHandler } from "express";
import { sendSuccess } from "../utils/response.js";
import { AppError } from "../utils/api-error.js";
import { createRazorpaySubscription } from "../services/payments.service.js";

export const createSubscriptionHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Authentication required");
  }

  const { planId } = req.body as { planId: string };
  
  const subscription = await createRazorpaySubscription(req.user.id, planId);

  sendSuccess(res, { subscription });
};
