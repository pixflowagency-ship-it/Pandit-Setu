import { Router } from "express";
import { verifyToken, requireRole, requireApprovedPandit } from "../middleware/verify-token.js";
import { asyncHandler, validateBody, validateQuery } from "../middleware/async-handler.js";
import {
  getNearbyPanditsHandler,
  updateDutyStatusHandler,
  acceptBookingHandler,
  declineBookingHandler,
  getPanditDashboardHandler,
  applyForPanditHandler,
  getOnboardingStatusHandler,
  updatePanditProfileHandler,
  uploadPanditDocumentHandler,
  downloadPanditDocumentHandler,
  deletePanditDocumentHandler,
  submitDocumentsForReviewHandler,
  scheduleVideoVerificationHandler,
  adminVerifyDocumentHandler,
  adminVerifyVideoHandler,
  adminApprovePanditHandler,
} from "../controllers/pandits.controller.js";
import {
  nearbyQuerySchema,
  dutyStatusSchema,
  acceptBookingSchema,
  declineBookingSchema,
  updatePanditProfileSchema,
  uploadDocumentSchema,
  scheduleVideoVerificationSchema,
  adminVerifyDocumentSchema,
  adminVerifyVideoSchema,
  adminApprovePanditSchema,
} from "../validators/pandits.validator.js";
import { strictLimiter, nearbyLimiter, apiLimiter } from "../middleware/rate-limit.js";

const panditsRouter = Router();

// 1. Operational routes strictly protected by requireApprovedPandit
panditsRouter.get(
  "/dashboard",
  apiLimiter,
  verifyToken,
  requireApprovedPandit,
  asyncHandler(getPanditDashboardHandler)
);

panditsRouter.patch(
  "/duty-status",
  strictLimiter,
  verifyToken,
  requireApprovedPandit,
  validateBody(dutyStatusSchema),
  asyncHandler(updateDutyStatusHandler)
);

panditsRouter.post(
  "/accept-booking",
  strictLimiter,
  verifyToken,
  requireApprovedPandit,
  validateBody(acceptBookingSchema),
  asyncHandler(acceptBookingHandler)
);

panditsRouter.post(
  "/decline-booking",
  strictLimiter,
  verifyToken,
  requireApprovedPandit,
  validateBody(declineBookingSchema),
  asyncHandler(declineBookingHandler)
);

// 2. Nearby query (accessible to authenticated devotees/yajmans)
panditsRouter.get(
  "/nearby",
  nearbyLimiter,
  verifyToken,
  validateQuery(nearbyQuerySchema),
  asyncHandler(getNearbyPanditsHandler)
);

// 3. Application endpoint for Yajman to apply for Pandit role
panditsRouter.post(
  "/apply",
  strictLimiter,
  verifyToken,
  asyncHandler(applyForPanditHandler)
);

// 4. Pandit Onboarding & Verification lifecycle (requires Pandit role token)
panditsRouter.get(
  "/me/onboarding-status",
  apiLimiter,
  verifyToken,
  requireRole(["PANDIT"]),
  asyncHandler(getOnboardingStatusHandler)
);

panditsRouter.put(
  "/me/profile",
  strictLimiter,
  verifyToken,
  requireRole(["PANDIT"]),
  validateBody(updatePanditProfileSchema),
  asyncHandler(updatePanditProfileHandler)
);

panditsRouter.post(
  "/me/documents",
  strictLimiter,
  verifyToken,
  requireRole(["PANDIT"]),
  validateBody(uploadDocumentSchema),
  asyncHandler(uploadPanditDocumentHandler)
);

panditsRouter.get(
  "/me/documents/:id/download",
  verifyToken,
  asyncHandler(downloadPanditDocumentHandler)
);

panditsRouter.delete(
  "/me/documents/:id",
  strictLimiter,
  verifyToken,
  requireRole(["PANDIT"]),
  asyncHandler(deletePanditDocumentHandler)
);

panditsRouter.post(
  "/me/submit-for-review",
  strictLimiter,
  verifyToken,
  requireRole(["PANDIT"]),
  asyncHandler(submitDocumentsForReviewHandler)
);

panditsRouter.post(
  "/me/video-verification/schedule",
  strictLimiter,
  verifyToken,
  requireRole(["PANDIT"]),
  validateBody(scheduleVideoVerificationSchema),
  asyncHandler(scheduleVideoVerificationHandler)
);

// 5. Reviewer / Admin verification routes (strictly require ADMIN role)
panditsRouter.patch(
  "/admin/documents/:documentId/verify",
  strictLimiter,
  verifyToken,
  requireRole(["ADMIN"]),
  validateBody(adminVerifyDocumentSchema),
  asyncHandler(adminVerifyDocumentHandler)
);

panditsRouter.patch(
  "/admin/:panditId/video-verify",
  strictLimiter,
  verifyToken,
  requireRole(["ADMIN"]),
  validateBody(adminVerifyVideoSchema),
  asyncHandler(adminVerifyVideoHandler)
);

panditsRouter.patch(
  "/admin/:panditId/approval",
  strictLimiter,
  verifyToken,
  requireRole(["ADMIN"]),
  validateBody(adminApprovePanditSchema),
  asyncHandler(adminApprovePanditHandler)
);

export default panditsRouter;

