import { pgTable, uuid, boolean, text, numeric, timestamp, } from "drizzle-orm/pg-core";
import { verificationStageEnum } from "./enums.js";
import { users } from "./users.js";
import { geometryPoint } from "../custom-types/point.js";
export const panditProfiles = pgTable("pandit_profiles", {
    id: uuid("id").defaultRandom().primaryKey(),
    userId: uuid("user_id")
        .notNull()
        .unique()
        .references(() => users.id, { onDelete: "cascade" }),
    verificationStage: verificationStageEnum("verification_stage")
        .notNull()
        .default("PENDING"),
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
//# sourceMappingURL=pandit-profiles.js.map