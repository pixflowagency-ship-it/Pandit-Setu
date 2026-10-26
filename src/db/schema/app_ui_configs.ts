import {
  pgTable,
  uuid,
  varchar,
  integer,
  text,
  timestamp,
  jsonb,
  pgEnum,
  index,
} from "drizzle-orm/pg-core";
import { users } from "./users.js";

export const appConfigStatusEnum = pgEnum("app_config_status", [
  "DRAFT",
  "PUBLISHED",
  "ARCHIVED",
]);

export interface AppUiConfigPayload {
  schemaVersion: number;
  theme: {
    primaryColor: string;
    accentColor: string;
    backgroundColor: string;
    surfaceColor: string;
  };
  sections: Array<{
    id: string;
    enabled: boolean;
    order: number;
    title: string;
    titleHi: string;
    subtitle?: string;
    subtitleHi?: string;
  }>;
  heroSlides: Array<{
    id: string;
    title: string;
    titleHi: string;
    subtitle: string;
    subtitleHi: string;
    tag: string;
    tagHi: string;
    imageUrl: string;
    actionType: "POOJA" | "SCREEN" | "EXTERNAL";
    actionTarget: string;
    slug?: string;
  }>;
  serviceGrid: Array<{
    id: string;
    title: string;
    titleHi: string;
    subtitle: string;
    subtitleHi: string;
    badge?: string;
    badgeHi?: string;
    icon: string;
    target: string;
    enabled: boolean;
    order: number;
  }>;
  lifeProblemsBanner: {
    enabled: boolean;
    title: string;
    titleHi: string;
    subtitle: string;
    subtitleHi: string;
    buttonText: string;
    buttonTextHi: string;
    target: string;
  };
}

export const appUiConfigs = pgTable(
  "app_ui_configs",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    version: integer("version").notNull(),
    status: appConfigStatusEnum("status").notNull().default("DRAFT"),
    config: jsonb("config").$type<AppUiConfigPayload>().notNull(),
    publishedBy: uuid("published_by").references(() => users.id),
    publishedAt: timestamp("published_at", { withTimezone: true }),
    changeSummary: text("change_summary"),
    createdAt: timestamp("created_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp("updated_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => [
    index("idx_app_ui_configs_status").on(table.status),
    index("idx_app_ui_configs_version").on(table.version),
  ]
);

export type AppUiConfig = typeof appUiConfigs.$inferSelect;
export type NewAppUiConfig = typeof appUiConfigs.$inferInsert;
