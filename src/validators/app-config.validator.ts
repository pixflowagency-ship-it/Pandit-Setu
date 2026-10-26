import { z } from "zod";

const hexColorRegex = /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/;

export const appUiThemeSchema = z.object({
  primaryColor: z.string().regex(hexColorRegex, "Invalid hex color format (e.g., #E65100)"),
  accentColor: z.string().regex(hexColorRegex, "Invalid hex color format (e.g., #D97706)"),
  backgroundColor: z.string().regex(hexColorRegex, "Invalid hex color format (e.g., #FFF8EE)"),
  surfaceColor: z.string().regex(hexColorRegex, "Invalid hex color format (e.g., #FFFFFF)"),
});

export const appUiSectionSchema = z.object({
  id: z.string().min(1, "Section ID is required"),
  enabled: z.boolean().default(true),
  order: z.number().int().min(1),
  title: z.string().min(1, "English title is required"),
  titleHi: z.string().min(1, "Hindi title is required"),
  subtitle: z.string().optional(),
  subtitleHi: z.string().optional(),
});

export const appUiHeroSlideSchema = z.object({
  id: z.string().min(1),
  title: z.string().min(1, "Slide title is required"),
  titleHi: z.string().min(1, "Hindi slide title is required"),
  subtitle: z.string().default(""),
  subtitleHi: z.string().default(""),
  tag: z.string().default(""),
  tagHi: z.string().default(""),
  imageUrl: z.string().url("Valid image URL is required"),
  actionType: z.enum(["POOJA", "SCREEN", "EXTERNAL"]).default("POOJA"),
  actionTarget: z.string().min(1, "Action target is required"),
  slug: z.string().optional(),
});

export const appUiServiceGridItemSchema = z.object({
  id: z.string().min(1),
  title: z.string().min(1),
  titleHi: z.string().min(1),
  subtitle: z.string().default(""),
  subtitleHi: z.string().default(""),
  badge: z.string().optional(),
  badgeHi: z.string().optional(),
  icon: z.string().min(1),
  target: z.string().min(1),
  enabled: z.boolean().default(true),
  order: z.number().int().min(1),
});

export const appUiLifeProblemsBannerSchema = z.object({
  enabled: z.boolean().default(true),
  title: z.string().min(1),
  titleHi: z.string().min(1),
  subtitle: z.string().default(""),
  subtitleHi: z.string().default(""),
  buttonText: z.string().min(1),
  buttonTextHi: z.string().min(1),
  target: z.string().min(1),
});

export const appUiConfigPayloadSchema = z.object({
  schemaVersion: z.number().int().min(1).default(1),
  theme: appUiThemeSchema,
  sections: z.array(appUiSectionSchema).min(1, "At least one section required"),
  heroSlides: z.array(appUiHeroSlideSchema).min(1, "At least one hero slide required"),
  serviceGrid: z.array(appUiServiceGridItemSchema).min(1, "At least one service item required"),
  lifeProblemsBanner: appUiLifeProblemsBannerSchema,
});

export const saveDraftAppConfigSchema = z.object({
  config: appUiConfigPayloadSchema,
  changeSummary: z.string().max(500).optional(),
});

export const publishAppConfigSchema = z.object({
  changeSummary: z.string().max(500).optional(),
});

export type AppUiConfigPayloadInput = z.infer<typeof appUiConfigPayloadSchema>;
