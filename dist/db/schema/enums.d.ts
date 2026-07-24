export declare const userRoleEnum: import("drizzle-orm/pg-core").PgEnum<["YAJMAN", "PANDIT", "ADMIN"]>;
export declare const verificationStageEnum: import("drizzle-orm/pg-core").PgEnum<["STAGE_1_COMPLETE", "DOCS_SUBMITTED", "VERIFIED", "REJECTED"]>;
export declare const bookingStatusEnum: import("drizzle-orm/pg-core").PgEnum<["PENDING", "CONFIRMED", "IN_PROGRESS", "COMPLETED", "CANCELLED"]>;
export declare const verificationStatusEnum: import("drizzle-orm/pg-core").PgEnum<["PENDING", "APPROVED", "REJECTED"]>;
export declare const docTypeEnum: import("drizzle-orm/pg-core").PgEnum<["AADHAAR", "PAN", "DEGREE_CERTIFICATE", "OTHER"]>;
export declare const docStatusEnum: import("drizzle-orm/pg-core").PgEnum<["PENDING", "VERIFIED", "REJECTED"]>;
export type UserRole = (typeof userRoleEnum.enumValues)[number];
export type VerificationStage = (typeof verificationStageEnum.enumValues)[number];
export type BookingStatus = (typeof bookingStatusEnum.enumValues)[number];
export type VerificationStatus = (typeof verificationStatusEnum.enumValues)[number];
export type DocType = (typeof docTypeEnum.enumValues)[number];
export type DocStatus = (typeof docStatusEnum.enumValues)[number];
//# sourceMappingURL=enums.d.ts.map