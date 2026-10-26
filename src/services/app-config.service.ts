import { eq, desc } from "drizzle-orm";
import { db } from "../db/index.js";
import { appUiConfigs, type AppUiConfigPayload } from "../db/schema/app_ui_configs.js";
import { users } from "../db/schema/users.js";
import { AppError } from "../utils/api-error.js";
import { logger } from "../utils/logger.js";
import { getRedis } from "../config/redis.js";
import { appUiConfigPayloadSchema } from "../validators/app-config.validator.js";

const CACHE_KEY = "sarv:app_ui_config:active";
const CACHE_TTL_SECONDS = 300; // 5 minutes

export const DEFAULT_APP_CONFIG: AppUiConfigPayload = {
  schemaVersion: 1,
  theme: {
    primaryColor: "#E65100",
    accentColor: "#D97706",
    backgroundColor: "#FFF8EE",
    surfaceColor: "#FFFFFF",
  },
  sections: [
    { id: "hero_slideshow", enabled: true, order: 1, title: "Banners", titleHi: "बैनर" },
    { id: "six_box_grid", enabled: true, order: 2, title: "Our Sacred Services", titleHi: "हमारी पवित्र सेवाएं" },
    { id: "life_problems", enabled: true, order: 3, title: "Problems in Life?", titleHi: "जीवन में समस्याएं?" },
    { id: "upcoming_booking", enabled: true, order: 4, title: "Your Next Pooja", titleHi: "आपकी आगामी पूजा" },
    { id: "category_menu", enabled: true, order: 5, title: "Explore by Category", titleHi: "श्रेणी अनुसार खोजें" },
    { id: "panchang", enabled: true, order: 6, title: "Daily Vedic Panchang", titleHi: "दैनिक पंचांग" },
    { id: "rarest_items", enabled: true, order: 7, title: "Sacred Rarest Samagri", titleHi: "दुर्लभ पूजन सामग्री" },
    { id: "trending_rituals", enabled: true, order: 8, title: "Trending Rituals", titleHi: "लोकप्रिय अनुष्ठान" },
    { id: "blog", enabled: true, order: 9, title: "Vedic Wisdom & Insights", titleHi: "वैदिक ज्ञान" },
    { id: "trust_badges", enabled: true, order: 10, title: "Why SARV MANGAL", titleHi: "सर्व मंगल क्यों" },
  ],
  heroSlides: [
    {
      id: "slide-1",
      title: "Grand Navratri & Durga Puja 2026",
      titleHi: "भव्य शारदीय नवरात्रि एवं दुर्गा पूजा 2026",
      subtitle: "Book Authentic Vedic Chandi Path & Havan by Certified Acharyas",
      subtitleHi: "प्रमाणित आचार्यों द्वारा प्रामाणिक वैदिक चंडी पाठ एवं हवन",
      tag: "FESTIVAL SPECIAL",
      tagHi: "उत्सव विशेष",
      imageUrl: "https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=900",
      actionType: "POOJA",
      actionTarget: "67e77a47-8ffb-403a-bc64-c948ab5e2abc",
      slug: "navratri-pooja",
    },
    {
      id: "slide-2",
      title: "Shri Satyanarayan Vrat Katha",
      titleHi: "श्री सत्यनारायण व्रत कथा",
      subtitle: "Invite Infinite Health, Peace & Family Harmony",
      subtitleHi: "अनंत सुख, शांति एवं पारिवारिक समृद्धि का वास कराएं",
      tag: "MOST POPULAR",
      tagHi: "सर्वाधिक लोकप्रिय",
      imageUrl: "https://images.unsplash.com/photo-1605152276897-4f618f831968?w=900",
      actionType: "POOJA",
      actionTarget: "92086a65-41a9-4545-9588-6f35c8bb8b6b",
      slug: "satyanarayan-katha",
    },
    {
      id: "slide-3",
      title: "Griha Pravesh & Vastu Shanti",
      titleHi: "गृह प्रवेश एवं वास्तु शांति",
      subtitle: "Purify Your New Residence with Vedic Mantras & Havan",
      subtitleHi: "वैदिक मंत्रोच्चार एवं हवन द्वारा अपने नए आवास को शुद्ध करें",
      tag: "HOUSEWARMING",
      tagHi: "गृह प्रवेश",
      imageUrl: "https://images.unsplash.com/photo-1621252179027-94459d278660?w=900",
      actionType: "POOJA",
      actionTarget: "9ae802b2-95f9-4461-af5a-e7c32d6fb1af",
      slug: "griha-pravesh-pooja",
    },
    {
      id: "slide-4",
      title: "Mahamrityunjaya Healing Havan",
      titleHi: "महामृत्युंजय महा अनुष्ठान",
      subtitle: "Conquer Illness & Invoke Divine Life Energy of Bhagwan Shiva",
      subtitleHi: "रोग-निवारण एवं भगवान शिव की दिव्य प्राण-ऊर्जा प्राप्त करें",
      tag: "SACRED FIRE RITUAL",
      tagHi: "पवित्र अग्नि अनुष्ठान",
      imageUrl: "https://images.unsplash.com/photo-1604882737079-7dc3df3e09ac?w=900",
      actionType: "POOJA",
      actionTarget: "9484cd34-05de-4b00-9621-b190d075be33",
      slug: "mahamrityunjaya-jaap",
    },
  ],
  serviceGrid: [
    { id: "pooja", enabled: true, order: 1, title: "Vedic Poojas", titleHi: "वैदिक पूजा", subtitle: "Book Acharya", subtitleHi: "आचार्य बुक करें", badge: "POPULAR", badgeHi: "लोकप्रिय", icon: "auto_awesome", target: "/pooja-flow" },
    { id: "kundli", enabled: true, order: 2, title: "Handmade Kundli", titleHi: "हस्तनिर्मित कुंडली", subtitle: "By Astrologers", subtitleHi: "ज्योतिषियों द्वारा", badge: "CUSTOM", badgeHi: "विशेष", icon: "menu_book", target: "/kundli-flow" },
    { id: "consultation", enabled: true, order: 3, title: "Consultation", titleHi: "ज्योतिष परामर्श", subtitle: "Call / Video", subtitleHi: "कॉल / वीडियो", badge: "LIVE", badgeHi: "लाइव", icon: "phone_in_talk", target: "/consultation-flow" },
    { id: "samagri", enabled: true, order: 4, title: "Poojan Samagri", titleHi: "पूजन सामग्री", subtitle: "Pure & Vedic", subtitleHi: "शुद्ध व वैदिक", badge: "DELIVERY", badgeHi: "डिलीवरी", icon: "local_florist", target: "/shop" },
    { id: "temples", enabled: true, order: 5, title: "Nearest Temple", titleHi: "निकटतम मंदिर", subtitle: "Darshan & Nav", subtitleHi: "दर्शन व मार्ग", badge: "MAP", badgeHi: "मानचित्र", icon: "temple_hindu", target: "/nearest-temple" },
    { id: "tracking", enabled: true, order: 6, title: "Live Tracking", titleHi: "लाइव ट्रैकिंग", subtitle: "Pandit Location", subtitleHi: "पंडित जी की लोकेशन", badge: "GPS", badgeHi: "जीपीएस", icon: "explore", target: "/live-tracking" },
  ],
  lifeProblemsBanner: {
    enabled: true,
    title: "Problems in Life?",
    titleHi: "जीवन में कोई समस्या है?",
    subtitle: "Talk to Expert Astrologers & Get Vedic Remedies",
    subtitleHi: "विशेषज्ञ ज्योतिषियों से बात करें और वैदिक समाधान पाएं",
    buttonText: "Consult Now",
    buttonTextHi: "परामर्श लें",
    target: "/consultation-flow",
  },
};

/**
 * Invalidate Redis cache for active app config
 */
async function invalidateCache(): Promise<void> {
  try {
    const client = await getRedis();
    if (client) {
      await client.del(CACHE_KEY);
    }
  } catch (err: any) {
    logger.warn({ err: err.message }, "Redis cache invalidation skipped for app UI config");
  }
}

/**
 * Retrieve active published App UI configuration
 */
export async function getActiveAppConfig(): Promise<{
  id: string | null;
  version: number;
  publishedAt: Date | null;
  config: AppUiConfigPayload;
}> {
  // Check cache first
  try {
    const client = await getRedis();
    if (client) {
      const cached = await client.get(CACHE_KEY);
      if (cached) {
        return JSON.parse(cached);
      }
    }
  } catch (err: any) {
    // Non-fatal cache failure
  }

  try {
    const published = await db.query.appUiConfigs.findFirst({
      where: eq(appUiConfigs.status, "PUBLISHED"),
      orderBy: [desc(appUiConfigs.version)],
    });

    if (published) {
      const result = {
        id: published.id,
        version: published.version,
        publishedAt: published.publishedAt,
        config: published.config,
      };

      try {
        const client = await getRedis();
        if (client) {
          await client.set(CACHE_KEY, JSON.stringify(result), "EX", CACHE_TTL_SECONDS);
        }
      } catch (_) {}

      return result;
    }
  } catch (err: any) {
    logger.warn({ err: err.message }, "Database query failed for active app config, falling back to built-in default");
  }


  return {
    id: null,
    version: 1,
    publishedAt: new Date(),
    config: DEFAULT_APP_CONFIG,
  };
}

/**
 * Retrieve draft App UI configuration for admins
 */
export async function getDraftAppConfig(): Promise<{
  id: string | null;
  version: number;
  isNewDraft: boolean;
  config: AppUiConfigPayload;
  updatedAt: Date | null;
}> {
  try {
    const draft = await db.query.appUiConfigs.findFirst({
      where: eq(appUiConfigs.status, "DRAFT"),
      orderBy: [desc(appUiConfigs.updatedAt)],
    });

    if (draft) {
      return {
        id: draft.id,
        version: draft.version,
        isNewDraft: false,
        config: draft.config,
        updatedAt: draft.updatedAt,
      };
    }
  } catch (err: any) {
    logger.warn({ err: err.message }, "Could not fetch draft config from DB");
  }

  // If no draft exists, base draft on the active published config
  const active = await getActiveAppConfig();
  return {
    id: null,
    version: active.version,
    isNewDraft: true,
    config: active.config,
    updatedAt: null,
  };
}

/**
 * Save or update draft configuration
 */
export async function saveDraftAppConfig(
  adminId: string,
  configPayload: AppUiConfigPayload,
  changeSummary?: string
): Promise<{ success: boolean; id: string; version: number }> {
  // Validate schema
  const parsed = appUiConfigPayloadSchema.parse(configPayload);

  // Check for existing draft
  const existingDraft = await db.query.appUiConfigs.findFirst({
    where: eq(appUiConfigs.status, "DRAFT"),
  });

  const active = await getActiveAppConfig();
  const nextVersion = active.version + 1;

  if (existingDraft) {
    const [updated] = await db
      .update(appUiConfigs)
      .set({
        config: parsed,
        changeSummary: changeSummary || existingDraft.changeSummary,
        updatedAt: new Date(),
      })
      .where(eq(appUiConfigs.id, existingDraft.id))
      .returning();

    return {
      success: true,
      id: updated.id,
      version: updated.version,
    };
  }

  // Create new draft
  const [created] = await db
    .insert(appUiConfigs)
    .values({
      version: nextVersion,
      status: "DRAFT",
      config: parsed,
      changeSummary: changeSummary || "Draft configuration changes",
      publishedBy: adminId,
    })
    .returning();

  return {
    success: true,
    id: created.id,
    version: created.version,
  };
}

/**
 * Atomically publish draft configuration
 */
export async function publishAppConfig(
  adminId: string,
  changeSummary?: string
): Promise<{ success: boolean; version: number; publishedAt: Date }> {
  const draft = await db.query.appUiConfigs.findFirst({
    where: eq(appUiConfigs.status, "DRAFT"),
  });

  if (!draft) {
    throw new AppError(400, "NO_DRAFT_FOUND", "No pending draft configuration found to publish. Save draft changes first.");
  }

  // Validate the draft config
  const validatedConfig = appUiConfigPayloadSchema.parse(draft.config);

  const publishedAt = new Date();

  // Find max version to increment
  const latestVersionRes = await db
    .select({ version: appUiConfigs.version })
    .from(appUiConfigs)
    .orderBy(desc(appUiConfigs.version))
    .limit(1);

  const nextVersion = (latestVersionRes[0]?.version ?? 0) + 1;

  await db.transaction(async (tx) => {
    // 1. Mark existing published as ARCHIVED
    await tx
      .update(appUiConfigs)
      .set({ status: "ARCHIVED" })
      .where(eq(appUiConfigs.status, "PUBLISHED"));

    // 2. Mark this draft as PUBLISHED
    await tx
      .update(appUiConfigs)
      .set({
        version: nextVersion,
        status: "PUBLISHED",
        config: validatedConfig,
        publishedBy: adminId,
        publishedAt,
        changeSummary: changeSummary || draft.changeSummary || `Version ${nextVersion} published`,
        updatedAt: publishedAt,
      })
      .where(eq(appUiConfigs.id, draft.id));
  });

  // Invalidate cache
  await invalidateCache();

  logger.info(
    { version: nextVersion, adminId, changeSummary },
    "App UI configuration published successfully"
  );

  return {
    success: true,
    version: nextVersion,
    publishedAt,
  };
}

/**
 * List configuration version history
 */
export async function getAppConfigVersions(limit: number = 20): Promise<Array<{
  id: string;
  version: number;
  status: string;
  changeSummary: string | null;
  publishedAt: Date | null;
  publishedBy: string | null;
  createdAt: Date;
}>> {
  const rows = await db
    .select({
      config: appUiConfigs,
      publisherName: users.name,
      publisherEmail: users.email,
    })
    .from(appUiConfigs)
    .leftJoin(users, eq(appUiConfigs.publishedBy, users.id))
    .orderBy(desc(appUiConfigs.version), desc(appUiConfigs.createdAt))
    .limit(limit);

  return rows.map((r) => ({
    id: r.config.id,
    version: r.config.version,
    status: r.config.status,
    changeSummary: r.config.changeSummary,
    publishedAt: r.config.publishedAt,
    publishedBy: r.publisherName || r.publisherEmail || "Admin",
    createdAt: r.config.createdAt,
  }));
}

/**
 * Rollback to a specific past version
 */
export async function rollbackAppConfig(
  adminId: string,
  targetVersionId: string
): Promise<{ success: boolean; version: number; rolledBackFromVersion: number }> {
  const target = await db.query.appUiConfigs.findFirst({
    where: eq(appUiConfigs.id, targetVersionId),
  });

  if (!target) {
    throw new AppError(404, "VERSION_NOT_FOUND", "Target configuration version not found");
  }

  // Validate the target's config
  const validatedConfig = appUiConfigPayloadSchema.parse(target.config);

  const latestVersionRes = await db
    .select({ version: appUiConfigs.version })
    .from(appUiConfigs)
    .orderBy(desc(appUiConfigs.version))
    .limit(1);

  const nextVersion = (latestVersionRes[0]?.version ?? 0) + 1;
  const publishedAt = new Date();
  const summary = `Rolled back to Version ${target.version}: ${target.changeSummary || "Restored layout"}`;

  await db.transaction(async (tx) => {
    // 1. Mark existing published as ARCHIVED
    await tx
      .update(appUiConfigs)
      .set({ status: "ARCHIVED" })
      .where(eq(appUiConfigs.status, "PUBLISHED"));

    // 2. Insert new PUBLISHED version holding target config
    await tx.insert(appUiConfigs).values({
      version: nextVersion,
      status: "PUBLISHED",
      config: validatedConfig,
      publishedBy: adminId,
      publishedAt,
      changeSummary: summary,
      createdAt: publishedAt,
      updatedAt: publishedAt,
    });
  });

  await invalidateCache();

  logger.info(
    { newVersion: nextVersion, rolledBackFrom: target.version, adminId },
    "App UI configuration rolled back successfully"
  );

  return {
    success: true,
    version: nextVersion,
    rolledBackFromVersion: target.version,
  };
}
