import { Router } from "express";
import { verifyToken } from "../middleware/verify-token.js";
import { requireRole } from "../middleware/require-role.js";
import { asyncHandler, validateBody } from "../middleware/async-handler.js";
import { apiLimiter, strictLimiter } from "../middleware/rate-limit.js";
import {
  adminApprovePanditSchema,
  adminVerifyDocumentSchema,
  adminVerifyVideoSchema,
  adminReviewMantraRecordingSchema,
} from "../validators/pandits.validator.js";
import {
  adminScheduleConsultationSchema,
  adminAssignConsultationSchema,
  adminUpdateConsultationStatusSchema,
} from "../validators/consultations.validator.js";
import {
  adminDecisionKundliOrderSchema,
  adminAssignKundliOrderSchema,
  adminUpdateKundliStatusSchema,
} from "../validators/kundli_orders.validator.js";
import {
  getAdminStatsHandler,
  getAdminPanditsHandler,
  getAdminPanditDetailHandler,
  getAdminSubscriptionsHandler,
  adminApprovePanditHandler,
  adminVerifyDocumentHandler,
  adminVerifyVideoHandler,
  adminDownloadDocumentHandler,
  adminReviewMantraRecordingHandler,
  adminStreamMantraRecordingHandler,
  getAdminMantrasHandler,
  createAdminMantraHandler,
  updateAdminMantraHandler,
  deleteAdminMantraHandler,
} from "../controllers/admin.controller.js";
import {
  adminGetConsultationsHandler,
  adminScheduleConsultationHandler,
  adminAssignPanditHandler,
  adminUpdateConsultationStatusHandler,
} from "../controllers/consultations.controller.js";
import {
  adminGetKundliOrdersHandler,
  adminDecisionKundliOrderHandler,
  adminAssignPanditToKundliHandler,
  adminUpdateKundliStatusHandler,
} from "../controllers/kundli_orders.controller.js";
import {
  adminListPanditsQuerySchema,
  adminListSubscriptionsQuerySchema,
  adminLoginSchema,
} from "../validators/admin.validator.js";
import {
  adminLoginHandler,
  adminMeHandler,
  adminLogoutHandler,
} from "../controllers/admin-auth.controller.js";
import { sendSuccess } from "../utils/response.js";

const adminRouter = Router();

// Dedicated Admin Login endpoint (public, strict rate limited)
adminRouter.post(
  "/auth/login",
  strictLimiter,
  validateBody(adminLoginSchema),
  asyncHandler(adminLoginHandler)
);

// Enforce authentication & ADMIN role guard on all protected admin routes
adminRouter.use(verifyToken, requireRole(["ADMIN"]));

// Admin identity verification & session management
adminRouter.get("/auth/me", apiLimiter, asyncHandler(adminMeHandler));
adminRouter.post("/auth/logout", apiLimiter, asyncHandler(adminLogoutHandler));

// Admin operational health check
adminRouter.get(
  "/health",
  apiLimiter,
  asyncHandler((_req, res) => {
    sendSuccess(res, { status: "ok" });
  })
);


// Admin dashboard operational metrics
adminRouter.get("/stats", apiLimiter, asyncHandler(getAdminStatsHandler));

// Pandit verification queue and detail
adminRouter.get("/pandits", apiLimiter, asyncHandler(getAdminPanditsHandler));
adminRouter.get("/pandits/:panditId", apiLimiter, asyncHandler(getAdminPanditDetailHandler));

// Pandit verification review actions
adminRouter.patch(
  "/pandits/:panditId/approval",
  strictLimiter,
  validateBody(adminApprovePanditSchema),
  asyncHandler(adminApprovePanditHandler)
);

adminRouter.patch(
  "/documents/:documentId/verify",
  strictLimiter,
  validateBody(adminVerifyDocumentSchema),
  asyncHandler(adminVerifyDocumentHandler)
);

adminRouter.patch(
  "/pandits/:panditId/video-verify",
  strictLimiter,
  validateBody(adminVerifyVideoSchema),
  asyncHandler(adminVerifyVideoHandler)
);

adminRouter.patch(
  "/pandits/:panditId/mantra-recordings/:recordingId/review",
  strictLimiter,
  validateBody(adminReviewMantraRecordingSchema),
  asyncHandler(adminReviewMantraRecordingHandler)
);

adminRouter.get(
  "/pandits/:panditId/mantra-recordings/:recordingId/stream",
  strictLimiter,
  asyncHandler(adminStreamMantraRecordingHandler)
);

adminRouter.get(
  "/documents/:documentId/download",
  strictLimiter,
  asyncHandler(adminDownloadDocumentHandler)
);

// Admin Approved Mantras Management
adminRouter.get("/mantras", apiLimiter, asyncHandler(getAdminMantrasHandler));
adminRouter.post("/mantras", strictLimiter, asyncHandler(createAdminMantraHandler));
adminRouter.patch("/mantras/:mantraId", strictLimiter, asyncHandler(updateAdminMantraHandler));
adminRouter.delete("/mantras/:mantraId", strictLimiter, asyncHandler(deleteAdminMantraHandler));

// Admin subscription oversight
adminRouter.get("/subscriptions", apiLimiter, asyncHandler(getAdminSubscriptionsHandler));

// Admin Consultation Desk queue & management
adminRouter.get("/consultations", apiLimiter, asyncHandler(adminGetConsultationsHandler));
adminRouter.patch(
  "/consultations/:id/schedule",
  strictLimiter,
  validateBody(adminScheduleConsultationSchema),
  asyncHandler(adminScheduleConsultationHandler)
);
adminRouter.patch(
  "/consultations/:id/assignment",
  strictLimiter,
  validateBody(adminAssignConsultationSchema),
  asyncHandler(adminAssignPanditHandler)
);
adminRouter.patch(
  "/consultations/:id/status",
  strictLimiter,
  validateBody(adminUpdateConsultationStatusSchema),
  asyncHandler(adminUpdateConsultationStatusHandler)
);

// Admin Kundli Orders queue & management
adminRouter.get("/kundli-orders", apiLimiter, asyncHandler(adminGetKundliOrdersHandler));
adminRouter.patch(
  "/kundli-orders/:id/decision",
  strictLimiter,
  validateBody(adminDecisionKundliOrderSchema),
  asyncHandler(adminDecisionKundliOrderHandler)
);
adminRouter.patch(
  "/kundli-orders/:id/assignment",
  strictLimiter,
  validateBody(adminAssignKundliOrderSchema),
  asyncHandler(adminAssignPanditToKundliHandler)
);
adminRouter.patch(
  "/kundli-orders/:id/status",
  strictLimiter,
  validateBody(adminUpdateKundliStatusSchema),
  asyncHandler(adminUpdateKundliStatusHandler)
);

export default adminRouter;
