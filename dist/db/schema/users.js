import { pgTable, uuid, varchar, text, timestamp, } from "drizzle-orm/pg-core";
import { userRoleEnum } from "./enums.js";
export const users = pgTable("users", {
    id: uuid("id").defaultRandom().primaryKey(),
    phone: varchar("phone", { length: 15 }).notNull().unique(),
    name: varchar("full_name", { length: 255 }).notNull(),
    // New profile fields
    dob: varchar("dob", { length: 10 }), // ISO date string (YYYY-MM-DD)
    tob: varchar("tob", { length: 8 }), // ISO time string (HH:MM:SS)
    pob: varchar("pob", { length: 255 }), // Place of birth
    gotra: varchar("gotra", { length: 255 }),
    zodiac: varchar("zodiac", { length: 255 }),
    city: varchar("city", { length: 255 }),
    email: varchar("email", { length: 255 }),
    profilePictureUrl: text("profile_picture_url"),
    role: userRoleEnum("role").notNull().default("YAJMAN"),
    createdAt: timestamp("created_at", { withTimezone: true })
        .notNull()
        .defaultNow(),
    updatedAt: timestamp("updated_at", { withTimezone: true })
        .notNull()
        .defaultNow()
        .$onUpdate(() => new Date()),
});
//# sourceMappingURL=users.js.map