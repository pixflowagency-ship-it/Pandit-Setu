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
//# sourceMappingURL=enums.js.map