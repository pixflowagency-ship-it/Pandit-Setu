import { pgTable, uuid, integer, text, boolean, numeric, doublePrecision, timestamp, jsonb, primaryKey, } from "drizzle-orm/pg-core";
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
    languages: jsonb("languages").$type(),
    bio: text("bio"),
    isVerified: boolean("is_verified").notNull().default(false),
    verificationStatus: verificationStatusEnum("verification_status")
        .notNull()
        .default("PENDING"),
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
});
export const panditDocuments = pgTable("pandit_documents", {
    id: uuid("id").defaultRandom().primaryKey(),
    panditId: uuid("pandit_id")
        .notNull()
        .references(() => pandits.id, { onDelete: "cascade" }),
    docType: docTypeEnum("doc_type").notNull(),
    docUrl: text("doc_url").notNull(),
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
//# sourceMappingURL=pandits.js.map