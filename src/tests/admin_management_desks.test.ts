import { describe, it, expect, vi } from "vitest";
import request from "supertest";
import app from "../app.js";
import { adminToken, yajmanToken } from "./helpers/setup.js";

// Hoisted mock state
const { mockData } = vi.hoisted(() => {
  const dummyUsers = [
    {
      id: "u-1",
      name: "Ramesh Sharma",
      phone: "9876543210",
      email: "ramesh@example.com",
      city: "Varanasi",
      role: "YAJMAN",
      createdAt: new Date(),
    },
    {
      id: "u-2",
      name: "Acharya Vidyadhar",
      phone: "9876543211",
      email: "vidyadhar@example.com",
      city: "Haridwar",
      role: "PANDIT",
      createdAt: new Date(),
    },
  ];

  const dummyBookings = [
    {
      id: "b-1",
      yajmanId: "u-1",
      panditId: "u-2",
      poojaId: "p-1",
      mode: "OFFLINE",
      bookingTime: new Date(),
      venueAddress: "Ghat Road, Varanasi",
      totalAmount: "5100.00",
      status: "PENDING",
      paymentStatus: "PAID",
      customNotes: "Test notes",
      createdAt: new Date(),
      poojaTitle: "Griha Pravesh",
      yajmanName: "Ramesh Sharma",
      yajmanPhone: "9876543210",
    },
  ];

  const dummyPoojas = [
    {
      id: "p-1",
      title: "Griha Pravesh Pooja",
      slug: "griha-pravesh-pooja",
      description: "Purifies residence",
      category: "Ghar & Jeevan",
      duration: "2-3 Hours",
      requiredPandits: "2",
      basePrice: "5100.00",
      samagriPrice: "1275.00",
      durationMinutes: 180,
      imageUrl: "https://images.unsplash.com/photo-1621252179027-94459d278660?w=500",
      isActive: true,
      createdAt: new Date(),
    },
  ];

  return {
    mockData: {
      dummyUsers,
      dummyBookings,
      dummyPoojas,
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
  const makeChain = (resolveValue: any) => {
    const chain: Record<string, any> = {};
    chain.from = vi.fn().mockReturnValue(chain);
    chain.where = vi.fn().mockReturnValue(chain);
    chain.leftJoin = vi.fn().mockReturnValue(chain);
    chain.orderBy = vi.fn().mockReturnValue(chain);
    chain.limit = vi.fn().mockReturnValue(chain);
    chain.offset = vi.fn().mockReturnValue(chain);
    chain.then = (resolve: (v: any) => void) => resolve(resolveValue);
    return chain;
  };

  return {
    db: {
      query: {
        users: {
          findFirst: vi.fn(() => mockData.dummyUsers[0]),
        },
        pandits: {
          findFirst: vi.fn(() => ({
            id: "pandit-1",
            userId: "u-2",
            experienceYears: 12,
            vedicSpecialization: "Rigveda",
            verificationStatus: "APPROVED",
          })),
        },
        bookings: {
          findFirst: vi.fn(() => mockData.dummyBookings[0]),
        },
        poojas: {
          findFirst: vi.fn(() => mockData.dummyPoojas[0]),
        },
      },
      select: vi.fn((fields?: any) => {
        if (fields && ("count" in fields || "total" in fields)) {
          return makeChain([{ count: 2 }]);
        }
        if (fields && ("id" in fields && "yajmanId" in fields)) {
          return makeChain(mockData.dummyBookings);
        }
        return makeChain(mockData.dummyPoojas);
      }),
      insert: vi.fn(() => ({
        values: vi.fn((vals) => ({
          returning: vi.fn(() => [{ ...vals, id: "created-id" }]),
        })),
      })),
      update: vi.fn(() => ({
        set: vi.fn((vals) => ({
          where: vi.fn(() => ({
            returning: vi.fn(() => [{ ...mockData.dummyBookings[0], ...vals }]),
          })),
        })),
      })),
    },
  };
});

describe("Phase 5: Admin Management Desks (Users, Bookings, Poojas)", () => {
  describe("Users Desk", () => {
    it("401 – rejects unauthenticated user list request", async () => {
      const res = await request(app).get("/api/v1/admin/users");
      expect(res.status).toBe(401);
    });

    it("403 – rejects non-admin token", async () => {
      const res = await request(app)
        .get("/api/v1/admin/users")
        .set("Authorization", `Bearer ${yajmanToken}`);
      expect(res.status).toBe(403);
    });

    it("200 – returns paginated users for admin", async () => {
      const res = await request(app)
        .get("/api/v1/admin/users?role=ALL&page=1&limit=20")
        .set("Authorization", `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data.items)).toBe(true);
      expect(res.body.data.pagination).toBeDefined();
    });

    it("200 – returns user detail with activity", async () => {
      const res = await request(app)
        .get("/api/v1/admin/users/u-1")
        .set("Authorization", `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.user).toBeDefined();
    });
  });

  describe("Bookings Desk", () => {
    it("200 – returns bookings list for admin", async () => {
      const res = await request(app)
        .get("/api/v1/admin/bookings?status=ALL&page=1&limit=20")
        .set("Authorization", `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data.items)).toBe(true);
    });

    it("200 – updates booking status with admin notes", async () => {
      const res = await request(app)
        .patch("/api/v1/admin/bookings/b-1/status")
        .set("Authorization", `Bearer ${adminToken}`)
        .send({ status: "CONFIRMED", notes: "Manual verification confirmed by Pandit Coordinator" });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });
  });

  describe("Poojas Catalogue Desk", () => {
    it("200 – returns poojas catalogue for admin", async () => {
      const res = await request(app)
        .get("/api/v1/admin/poojas")
        .set("Authorization", `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data.items)).toBe(true);
    });

    it("201 – creates new pooja ritual", async () => {
      const newPooja = {
        title: "Navchandi Maha Yagya",
        slug: "navchandi-maha-yagya",
        description: "Grand Vedic Fire ritual",
        category: "Maha Anushthan",
        duration: "5-6 Hours",
        requiredPandits: "5",
        basePrice: 21000,
        samagriPrice: 5100,
        durationMinutes: 360,
        imageUrl: "https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=500",
        isActive: true,
      };

      const res = await request(app)
        .post("/api/v1/admin/poojas")
        .set("Authorization", `Bearer ${adminToken}`)
        .send(newPooja);

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
    });

    it("200 – updates existing pooja ritual", async () => {
      const res = await request(app)
        .patch("/api/v1/admin/poojas/p-1")
        .set("Authorization", `Bearer ${adminToken}`)
        .send({ basePrice: 5500, isActive: true });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });
  });
});
