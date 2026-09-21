import { pgEnum } from "drizzle-orm/pg-core";

export const userRoleEnum = pgEnum("user_role", [
  "YAJMAN",
  "PANDIT",
  "ADMIN",
]);

export const verificationStageEnum = pgEnum("verification_stage", [
  "STAGE_1_COMPLETE",
  "DOCS_SUBMITTED",
  "VERIFIED",
  "REJECTED",
]);

export const bookingStatusEnum = pgEnum("booking_status", [
  "PENDING",
  "CONFIRMED",
  "IN_PROGRESS",
  "COMPLETED",
  "CANCELLED",
]);

export const bookingModeEnum = pgEnum("booking_mode", [
  "IN_PERSON",
  "ONLINE",
]);

export const verificationStatusEnum = pgEnum("verification_status", [
  "PENDING",
  "APPROVED",
  "REJECTED",
]);

export const docTypeEnum = pgEnum("doc_type", [
  "AADHAAR",
  "PAN",
  "DEGREE_CERTIFICATE",
  "OTHER",
]);

export const docStatusEnum = pgEnum("doc_status", [
  "PENDING",
  "VERIFIED",
  "REJECTED",
]);

export const paymentStatusEnum = pgEnum("payment_status", [
  "PENDING",
  "PAID",
  "FAILED",
]);

export const subscriptionStatusEnum = pgEnum("subscription_status", [
  "CREATED",
  "AUTHENTICATED",
  "ACTIVE",
  "PENDING",
  "HALTED",
  "CANCELLED",
  "COMPLETED",
  "EXPIRED",
]);

export type UserRole = (typeof userRoleEnum.enumValues)[number];
export type VerificationStage =
  (typeof verificationStageEnum.enumValues)[number];
export type BookingStatus = (typeof bookingStatusEnum.enumValues)[number];
export type BookingMode = (typeof bookingModeEnum.enumValues)[number];
export type VerificationStatus = (typeof verificationStatusEnum.enumValues)[number];
export type DocType = (typeof docTypeEnum.enumValues)[number];
export type DocStatus = (typeof docStatusEnum.enumValues)[number];
