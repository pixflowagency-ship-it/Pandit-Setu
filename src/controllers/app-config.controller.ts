import { RequestHandler } from "express";
import { sendSuccess } from "../utils/response.js";
import { AppError } from "../utils/api-error.js";
import {
  getActiveAppConfig,
  getDraftAppConfig,
  saveDraftAppConfig,
  publishAppConfig,
  getAppConfigVersions,
  rollbackAppConfig,
} from "../services/app-config.service.js";
import {
  saveDraftAppConfigSchema,
  publishAppConfigSchema,
} from "../validators/app-config.validator.js";

/**
 * Public: Get active published App UI configuration
 */
export const getActiveAppConfigHandler: RequestHandler = async (_req, res) => {
  const result = await getActiveAppConfig();
  sendSuccess(res, result);
};

/**
 * Admin: Get current draft configuration
 */
export const getDraftAppConfigHandler: RequestHandler = async (_req, res) => {
  const result = await getDraftAppConfig();
  sendSuccess(res, result);
};

/**
 * Admin: Save or update draft configuration
 */
export const saveDraftAppConfigHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Admin authentication required");
  }

  const { config, changeSummary } = saveDraftAppConfigSchema.parse(req.body);
  const result = await saveDraftAppConfig(req.user.id, config, changeSummary);
  sendSuccess(res, result, 200);
};

/**
 * Admin: Publish current draft as a new version
 */
export const publishAppConfigHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Admin authentication required");
  }

  const { changeSummary } = publishAppConfigSchema.parse(req.body || {});
  const result = await publishAppConfig(req.user.id, changeSummary);
  sendSuccess(res, result, 200);
};

/**
 * Admin: Get configuration version history
 */
export const getAppConfigVersionsHandler: RequestHandler = async (req, res) => {
  const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 20;
  const result = await getAppConfigVersions(limit);
  sendSuccess(res, { versions: result });
};

/**
 * Admin: Rollback to a previous configuration version
 */
export const rollbackAppConfigHandler: RequestHandler = async (req, res) => {
  if (!req.user) {
    throw new AppError(401, "UNAUTHORIZED", "Admin authentication required");
  }

  const versionId = req.params.versionId as string;
  if (!versionId) {
    throw new AppError(400, "MISSING_VERSION_ID", "Target version ID required");
  }

  const result = await rollbackAppConfig(req.user.id, versionId);
  sendSuccess(res, result, 200);
};
