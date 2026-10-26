import { Router } from "express";
import { verifyToken } from "../middleware/verify-token.js";
import { asyncHandler, validateBody } from "../middleware/async-handler.js";
import { apiLimiter, strictLimiter } from "../middleware/rate-limit.js";
import {
  createConsultationSchema,
  cancelConsultationSchema,
  verifyConsultationPaymentSchema,
} from "../validators/consultations.validator.js";
import {
  createConsultationHandler,
  getMyConsultationsHandler,
  getConsultationByIdHandler,
  cancelConsultationHandler,
  createConsultationPaymentOrderHandler,
  verifyConsultationPaymentHandler,
} from "../controllers/consultations.controller.js";

const consultationsRouter = Router();

consultationsRouter.use(verifyToken);

consultationsRouter.post(
  "/",
  strictLimiter,
  validateBody(createConsultationSchema),
  asyncHandler(createConsultationHandler)
);

consultationsRouter.get(
  "/",
  apiLimiter,
  asyncHandler(getMyConsultationsHandler)
);

consultationsRouter.get(
  "/:id",
  apiLimiter,
  asyncHandler(getConsultationByIdHandler)
);

consultationsRouter.post(
  "/:id/cancel",
  strictLimiter,
  validateBody(cancelConsultationSchema),
  asyncHandler(cancelConsultationHandler)
);

consultationsRouter.patch(
  "/:id/cancel",
  strictLimiter,
  validateBody(cancelConsultationSchema),
  asyncHandler(cancelConsultationHandler)
);

consultationsRouter.post(
  "/:id/payment/order",
  strictLimiter,
  asyncHandler(createConsultationPaymentOrderHandler)
);

consultationsRouter.post(
  "/:id/payment/verify",
  strictLimiter,
  validateBody(verifyConsultationPaymentSchema),
  asyncHandler(verifyConsultationPaymentHandler)
);

export default consultationsRouter;
