import {
  pgTable,
  uuid,
  integer,
  text,
  boolean,
  numeric,
  doublePrecision,
  timestamp,
  jsonb,
  varchar,
  primaryKey,
  index,
} from "drizzle-orm/pg-core";
import { users } from "./users.js";
import { poojas } from "./poojas.js";
import { verificationStatusEnum, docTypeEnum, docStatusEnum, verificationStageEnum } from "./enums.js";
import { geometryPoint } from "../custom-types/point.js";

export const pandits = pgTable("pandits", {
  id: uuid("id").defaultRandom().primaryKey(),
  userId: uuid("user_id")
    .notNull()
    .unique()
    .references(() => users.id, { onDelete: "cascade" }),
  experienceYears: integer("experience_years"),
  vedicSpecialization: text("vedic_specialization"),
  languages: jsonb("languages").$type<string[]>(),
  bio: text("bio"),
  isVerified: boolean("is_verified").notNull().default(false),
  verificationStatus: verificationStatusEnum("verification_status")
    .notNull()
    .default("PENDING"),
  verificationStage: varchar("verification_stage", { length: 50 })
    .notNull()
    .default("STAGE_1_COMPLETE"),
  rejectionReason: text("rejection_reason"),
  videoCallStatus: varchar("video_call_status", { length: 50 })
    .notNull()
    .default("PENDING"),
  videoScheduledAt: timestamp("video_scheduled_at", { withTimezone: true }),
  videoCallRoomId: text("video_call_room_id"),
  videoVerifierId: uuid("video_verifier_id"),
  videoVerifierNotes: text("video_verifier_notes"),
  verificationMethod: varchar("verification_method", { length: 50 })
    .default("MANTRA_VIDEO"),
  mantraRecordingStatus: varchar("mantra_recording_status", { length: 50 })
    .default("NOT_SUBMITTED"),
  approvedAt: timestamp("approved_at", { withTimezone: true }),
  approvedBy: uuid("approved_by"),
  serviceRadiusKm: integer("service_radius_km").notNull().default(15),
  latitude: doublePrecision("latitude"),
  longitude: doublePrecision("longitude"),
  location: geometryPoint("location"),
  isAvailable: boolean("is_available").notNull().default(true),
  rating: numeric("rating", { precision: 3, scale: 2 })
    .notNull()
    .default("5.00"),
  createdAt: timestamp("created_at", { withTimezone: true })
    .notNull()
    .defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true })
    .notNull()
    .defaultNow()
    .$onUpdate(() => new Date()),
}, (table) => {
  return {
    locationIdx: index("idx_pandits_location_gist").using("gist", table.location),
  };
});

export type Bandit = typeof pandits.$inferSelect;
export type NewPandit = typeof pandits.$inferInsert;

export const panditDocuments = pgTable("pandit_documents", {
  id: uuid("id").defaultRandom().primaryKey(),
  panditId: uuid("pandit_id")
    .notNull()
    .references(() => pandits.id, { onDelete: "cascade" }),
  docType: docTypeEnum("doc_type").notNull(),
  docUrl: text("doc_url").notNull(),
  docNumber: varchar("doc_number", { length: 100 }),
  fileName: varchar("file_name", { length: 255 }),
  fileSize: integer("file_size"),
  mimeType: varchar("mime_type", { length: 100 }),
  rejectionReason: text("rejection_reason"),
  status: docStatusEnum("status")
    .notNull()
    .default("PENDING"),
  createdAt: timestamp("created_at", { withTimezone: true })
    .notNull()
    .defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true })
    .notNull()
    .defaultNow()
    .$onUpdate(() => new Date()),
});

export type BanditDocument = typeof panditDocuments.$inferSelect;
export type NewPanditDocument = typeof panditDocuments.$inferInsert;

export const panditMantraRecordings = pgTable("pandit_mantra_recordings", {
  id: uuid("id").defaultRandom().primaryKey(),
  panditId: uuid("pandit_id")
    .notNull()
    .references(() => pandits.id, { onDelete: "cascade" }),
  mantraId: varchar("mantra_id", { length: 50 }).notNull(),
  mantraTitle: varchar("mantra_title", { length: 255 }).notNull(),
  mediaUrl: text("media_url").notNull(),
  fileName: varchar("file_name", { length: 255 }),
  fileSize: integer("file_size"),
  mimeType: varchar("mime_type", { length: 100 }),
  durationSeconds: integer("duration_seconds").default(0),
  status: varchar("status", { length: 50 }).notNull().default("PENDING"),
  rejectionReason: text("rejection_reason"),
  reviewerId: uuid("reviewer_id"),
  reviewerNotes: text("reviewer_notes"),
  reviewedAt: timestamp("reviewed_at", { withTimezone: true }),
  createdAt: timestamp("created_at", { withTimezone: true })
    .notNull()
    .defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true })
    .notNull()
    .defaultNow()
    .$onUpdate(() => new Date()),
});

export type PanditMantraRecording = typeof panditMantraRecordings.$inferSelect;
export type NewPanditMantraRecording = typeof panditMantraRecordings.$inferInsert;

export const panditServices = pgTable("pandit_services", {
  panditId: uuid("pandit_id")
    .notNull()
    .references(() => pandits.id, { onDelete: "cascade" }),
  poojaId: uuid("pooja_id")
    .notNull()
    .references(() => poojas.id, { onDelete: "cascade" }),
  customPrice: numeric("custom_price", { precision: 10, scale: 2 }),
  createdAt: timestamp("created_at", { withTimezone: true })
    .notNull()
    .defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true })
    .notNull()
    .defaultNow()
    .$onUpdate(() => new Date()),
}, (table) => {
  return {
    pk: primaryKey({ columns: [table.panditId, table.poojaId] }),
  };
});

export type BanditService = typeof panditServices.$inferSelect;
export type NewPanditService = typeof panditServices.$inferInsert;

export const panditProfiles = pgTable("pandit_profiles", {
  id: uuid("id").defaultRandom().primaryKey(),
  userId: uuid("user_id")
    .notNull()
    .unique()
    .references(() => users.id, { onDelete: "cascade" }),
  verificationStage: verificationStageEnum("verification_stage")
    .notNull()
    .default("STAGE_1_COMPLETE"),
  isOnline: boolean("is_online").notNull().default(false),
  bio: text("bio"),
  rating: numeric("rating", { precision: 3, scale: 2 })
    .notNull()
    .default("0.00"),
  location: geometryPoint("location"),
  createdAt: timestamp("created_at", { withTimezone: true })
    .notNull()
    .defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true })
    .notNull()
    .defaultNow()
    .$onUpdate(() => new Date()),
});

export type PanditProfile = typeof panditProfiles.$inferSelect;
export type NewPanditProfile = typeof panditProfiles.$inferInsert;

export const approvedMantras = pgTable("approved_mantras", {
  id: varchar("id", { length: 64 }).primaryKey(),
  title: varchar("title", { length: 255 }).notNull(),
  sanskritText: text("sanskrit_text").notNull(),
  transliteration: text("transliteration"),
  meaning: text("meaning"),
  pronunciationGuidance: text("pronunciation_guidance"),
  minDurationSeconds: integer("min_duration_seconds").notNull().default(10),
  maxDurationSeconds: integer("max_duration_seconds").notNull().default(120),
  isActive: boolean("is_active").notNull().default(true),
  displayOrder: integer("display_order").notNull().default(0),
  createdAt: timestamp("created_at", { withTimezone: true })
    .notNull()
    .defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true })
    .notNull()
    .defaultNow()
    .$onUpdate(() => new Date()),
});

export type ApprovedMantra = typeof approvedMantras.$inferSelect;
export type NewApprovedMantra = typeof approvedMantras.$inferInsert;
