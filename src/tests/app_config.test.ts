import { describe, it, expect, vi } from "vitest";
import request from "supertest";
import app from "../app.js";
import { adminToken, yajmanToken } from "./helpers/setup.js";

// Hoisted mock state to avoid referencing outer scope in vi.mock
const { mockState } = vi.hoisted(() => {
  const defaultLayout = {
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
    ],
    heroSlides: [
      {
        id: "slide-1",
        title: "Grand Navratri & Durga Puja 2026",
        titleHi: "भव्य शारदीय नवरात्रि 2026",
        subtitle: "Authentic Vedic Chandi Path",
        subtitleHi: "वैदिक चंडी पाठ",
        tag: "FESTIVAL SPECIAL",
        tagHi: "उत्सव विशेष",
        imageUrl: "https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=900",
        actionType: "POOJA",
        actionTarget: "67e77a47-8ffb-403a-bc64-c948ab5e2abc",
        slug: "navratri-pooja",
      },
    ],
    serviceGrid: [
      {
        id: "grid-1",
        title: "Book Pooja",
        titleHi: "पूजा बुक करें",
        subtitle: "Book Acharya",
        subtitleHi: "आचार्य बुक करें",
        badge: "POPULAR",
        badgeHi: "लोकप्रिय",
        icon: "temple_hindu",
        target: "/poojas",
        enabled: true,
        order: 1,
      },
    ],
    lifeProblemsBanner: {
      enabled: true,
      title: "Facing Struggles in Life?",
      titleHi: "जीवन में समस्याएं?",
      subtitle: "Consult Verified Vedic Astrologers",
      subtitleHi: "वैदिक आचार्यों से परामर्श लें",
      buttonText: "Consult Now",
      buttonTextHi: "परामर्श लें",
      target: "/consultations",
    },
  };

  const publishedRecord = {
    id: "pub-uuid-1",
    version: 1,
    status: "PUBLISHED",
    config: defaultLayout,
    publishedBy: "00000000-0000-0000-0000-000000000099",
    publishedAt: new Date(),
    changeSummary: "Initial version",
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  const draftRecord = {
    id: "draft-uuid-1",
    version: 2,
    status: "DRAFT",
    config: defaultLayout,
    publishedBy: "00000000-0000-0000-0000-000000000099",
    publishedAt: null,
    changeSummary: "Work in progress",
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  return {
    mockState: {
      defaultLayout,
      publishedRecord,
      draftRecord,
    },
  };
});

// Mock Redis connection
vi.mock("../config/redis.js", () => ({
  getRedis: vi.fn(async () => null),
  connectRedis: vi.fn(async () => null),
}));

// Mock DB queries for isolated unit/integration tests
vi.mock("../db/index.js", () => {
  return {
    db: {
      query: {
        appUiConfigs: {
          findFirst: vi.fn(() => mockState.draftRecord || mockState.publishedRecord),
        },
      },
      select: vi.fn(() => ({
        from: vi.fn(() => ({
          orderBy: vi.fn(() => ({
            limit: vi.fn(() => [{ version: 1 }]),
          })),
          leftJoin: vi.fn(() => ({
            orderBy: vi.fn(() => ({
              limit: vi.fn(() => [
                {
                  config: mockState.publishedRecord,
                  publisherName: "Super Admin",
                  publisherEmail: "admin@sarvmangal.com",
                },
              ]),
            })),
          })),
        })),
      })),
      insert: vi.fn(() => ({
        values: vi.fn((vals) => ({
          returning: vi.fn(() => [{ ...vals, id: "new-draft-uuid", version: 2 }]),
        })),
      })),
      update: vi.fn(() => ({
        set: vi.fn((vals) => ({
          where: vi.fn(() => ({
            returning: vi.fn(() => [{ ...vals, id: "updated-uuid", version: 2 }]),
          })),
        })),
      })),
      transaction: vi.fn(async (cb) => {
        return cb({
          update: vi.fn(() => ({
            set: vi.fn(() => ({
              where: vi.fn(),
            })),
          })),
          insert: vi.fn(() => ({
            values: vi.fn(() => ({
              returning: vi.fn(() => [{ id: "rollback-uuid", version: 3 }]),
            })),
          })),
        });
      }),
    },
  };
});

describe("Phase 6: App UI Configuration & CMS Remote Endpoints", () => {
  describe("GET /api/v1/app-config (Public)", () => {
    it("200 – returns active published App UI layout with schema-valid sections and theme", async () => {
      const res = await request(app).get("/api/v1/app-config");

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toBeDefined();
      expect(res.body.data.config).toBeDefined();
      expect(res.body.data.config.theme).toBeDefined();
      expect(res.body.data.config.theme.primaryColor).toMatch(/^#[0-9A-Fa-f]{6}$/);
      expect(Array.isArray(res.body.data.config.sections)).toBe(true);
      expect(Array.isArray(res.body.data.config.heroSlides)).toBe(true);
      expect(Array.isArray(res.body.data.config.serviceGrid)).toBe(true);
      expect(res.body.data.config.lifeProblemsBanner).toBeDefined();
    });
  });

  describe("GET /api/v1/admin/app-config/draft", () => {
    it("401 – rejects unauthenticated access", async () => {
      const res = await request(app).get("/api/v1/admin/app-config/draft");
      expect(res.status).toBe(401);
    });

    it("403 – rejects non-admin users", async () => {
      const res = await request(app)
        .get("/api/v1/admin/app-config/draft")
        .set("Authorization", `Bearer ${yajmanToken}`);
      expect(res.status).toBe(403);
    });

    it("200 – returns draft configuration for authorized admin", async () => {
      const res = await request(app)
        .get("/api/v1/admin/app-config/draft")
        .set("Authorization", `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.config).toBeDefined();
    });
  });

  describe("PUT /api/v1/admin/app-config/draft", () => {
    it("400 – rejects draft payload with invalid theme hex color format", async () => {
      const invalidConfig = {
        ...mockState.defaultLayout,
        theme: {
          ...mockState.defaultLayout.theme,
          primaryColor: "not-a-hex-color",
        },
      };

      const res = await request(app)
        .put("/api/v1/admin/app-config/draft")
        .set("Authorization", `Bearer ${adminToken}`)
        .send({ config: invalidConfig, changeSummary: "Invalid color test" });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it("200 – successfully saves valid draft configuration", async () => {
      const validConfig = {
        ...mockState.defaultLayout,
        sections: [
          { id: "hero_slideshow", enabled: true, order: 1, title: "Grand Banners", titleHi: "भव्य बैनर" },
          { id: "six_box_grid", enabled: true, order: 2, title: "Vedic Services", titleHi: "वैदिक सेवाएं" },
        ],
      };

      const res = await request(app)
        .put("/api/v1/admin/app-config/draft")
        .set("Authorization", `Bearer ${adminToken}`)
        .send({ config: validConfig, changeSummary: "Reordered sections" });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });
  });

  describe("POST /api/v1/admin/app-config/publish", () => {
    it("200 – atomically publishes draft configuration", async () => {
      const res = await request(app)
        .post("/api/v1/admin/app-config/publish")
        .set("Authorization", `Bearer ${adminToken}`)
        .send({ changeSummary: "Diwali 2026 Home Refresh" });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.version).toBeDefined();
    });
  });

  describe("GET /api/v1/admin/app-config/versions", () => {
    it("200 – returns version history list with audit metadata", async () => {
      const res = await request(app)
        .get("/api/v1/admin/app-config/versions")
        .set("Authorization", `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data.versions)).toBe(true);
    });
  });

  describe("POST /api/v1/admin/app-config/rollback/:versionId", () => {
    it("200 – rolls back configuration to a designated prior version", async () => {
      const res = await request(app)
        .post("/api/v1/admin/app-config/rollback/pub-uuid-1")
        .set("Authorization", `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });
  });
});
