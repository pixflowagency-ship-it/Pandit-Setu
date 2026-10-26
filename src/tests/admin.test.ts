import { describe, it, expect, vi, beforeEach } from "vitest";
import request from "supertest";
import app from "../app.js";
import { signTestToken, yajmanToken, adminToken } from "./helpers/setup.js";

// Mock DB
const {
  mockFindFirst,
  mockFindMany,
  mockSelect,
  mockInsert,
  mockUpdate,
} = vi.hoisted(() => ({
  mockFindFirst: vi.fn(),
  mockFindMany: vi.fn(),
  mockSelect: vi.fn(),
  mockInsert: vi.fn(),
  mockUpdate: vi.fn(),
}));

vi.mock("../db/index.js", () => {
  const selectChain: any = {
    from: vi.fn().mockImplementation(() => selectChain),
    where: vi.fn().mockImplementation(() => selectChain),
    leftJoin: vi.fn().mockImplementation(() => selectChain),
    orderBy: vi.fn().mockImplementation(() => selectChain),
    limit: vi.fn().mockImplementation(() => selectChain),
    offset: vi.fn().mockImplementation(() => selectChain),
    then: vi.fn().mockImplementation((resolve) => resolve([{ count: 0 }])),
  };

  return {
    db: {
      query: {
        users: { findFirst: (...args: any[]) => mockFindFirst(...args), findMany: (...args: any[]) => mockFindMany(...args) },
        pandits: { findFirst: (...args: any[]) => mockFindFirst(...args), findMany: (...args: any[]) => mockFindMany(...args) },
        panditDocuments: { findFirst: (...args: any[]) => mockFindFirst(...args), findMany: (...args: any[]) => mockFindMany(...args) },
        subscriptions: { findFirst: (...args: any[]) => mockFindFirst(...args), findMany: (...args: any[]) => mockFindMany(...args) },
      },
      select: (...args: any[]) => {
        mockSelect(...args);
        return selectChain;
      },
      insert: (...args: any[]) => mockInsert(...args),
      update: (...args: any[]) => mockUpdate(...args),
    },
    users: { id: "users.id", name: "users.name", phone: "users.phone", email: "users.email", city: "users.city" },
    pandits: { id: "pandits.id", userId: "pandits.user_id", verificationStatus: "pandits.verification_status", createdAt: "pandits.created_at" },
    panditDocuments: { id: "pandit_documents.id", panditId: "pandit_documents.pandit_id", createdAt: "pandit_documents.created_at" },
    bookings: { id: "bookings.id" },
    subscriptions: { id: "subscriptions.id", userId: "subscriptions.user_id", status: "subscriptions.status", createdAt: "subscriptions.created_at" },
    productOrders: { id: "product_orders.id" },
  };
});

describe("Phase P2-C: Admin Verification & Desk Dashboard API", () => {
  const panditToken = signTestToken({
    id: "pandit-user-id",
    phone: "+919876543210",
    role: "PANDIT",
  });

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("401 – rejects unauthenticated access to admin endpoints", async () => {
    const res = await request(app).get("/api/v1/admin/stats");
    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
  });

  it("403 – forbids Yajman user from accessing admin stats", async () => {
    const res = await request(app)
      .get("/api/v1/admin/stats")
      .set("Authorization", `Bearer ${yajmanToken}`);

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
  });

  it("403 – forbids Pandit user from accessing admin pandit queue", async () => {
    const res = await request(app)
      .get("/api/v1/admin/pandits")
      .set("Authorization", `Bearer ${panditToken}`);

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
  });

  it("200 – permits authorized Admin to access /api/v1/admin/health", async () => {
    const res = await request(app)
      .get("/api/v1/admin/health")
      .set("Authorization", `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.status).toBe("ok");
  });

  it("200 – returns real stats structure with persistent consultation and kundli counts", async () => {
    const { getAdminStats } = await import("../services/admin.service.js");
    const stats = await getAdminStats();

    expect(stats).toHaveProperty("pandits");
    expect(stats.pandits).toHaveProperty("pending");
    expect(stats.pandits).toHaveProperty("approved");
    expect(stats.pandits).toHaveProperty("rejected");
    expect(stats).toHaveProperty("bookings");
    expect(stats).toHaveProperty("subscriptions");
    expect(stats).toHaveProperty("productOrders");
    expect(stats).toHaveProperty("consultations");
    expect(stats.consultations.persistentRecords).toBe(true);
    expect(stats.consultations).toHaveProperty("total");
    expect(stats.consultations).toHaveProperty("pending");
    expect(stats).toHaveProperty("kundliOrders");
    expect(stats.kundliOrders.persistentRecords).toBe(true);
    expect(stats.kundliOrders).toHaveProperty("total");
    expect(stats.kundliOrders).toHaveProperty("pending");
  });

  it("404 – returns 404 if pandit application not found", async () => {
    mockFindFirst.mockResolvedValueOnce(null);

    const res = await request(app)
      .get("/api/v1/admin/pandits/00000000-0000-0000-0000-000000000404")
      .set("Authorization", `Bearer ${adminToken}`);

    expect(res.status).toBe(404);
    expect(res.body.success).toBe(false);
  });

  it("400 – rejects pandit approval with invalid body schema", async () => {
    const res = await request(app)
      .patch("/api/v1/admin/pandits/00000000-0000-0000-0000-000000000001/approval")
      .set("Authorization", `Bearer ${adminToken}`)
      .send({ status: "MAYBE" }); // Invalid enum value

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it("400 – rejects document verification with invalid status", async () => {
    const res = await request(app)
      .patch("/api/v1/admin/documents/00000000-0000-0000-0000-000000000001/verify")
      .set("Authorization", `Bearer ${adminToken}`)
      .send({ status: "ACCEPTABLE" }); // Invalid status enum

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });
});
