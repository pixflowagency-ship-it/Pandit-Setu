import { describe, it, expect, vi, beforeEach } from "vitest";
import request from "supertest";
import { yajmanToken } from "./helpers/setup.js";

/* ------------------------------------------------------------------ *
 *  Mock the DB module                                                  *
 * ------------------------------------------------------------------ */
const mockFindFirst = vi.fn();
const mockUpdate = vi.fn();
const mockSet = vi.fn();
const mockWhere = vi.fn();
const mockReturning = vi.fn();

vi.mock("../db/index.js", () => {
  const mockDb = {
    query: {
      users: { findFirst: (...args: unknown[]) => mockFindFirst(...args) },
    },
    update: (...args: unknown[]) => {
      mockUpdate(...args);
      return {
        set: (...a: unknown[]) => {
          mockSet(...a);
          return {
            where: (...w: unknown[]) => {
              mockWhere(...w);
              return { returning: () => mockReturning() };
            },
          };
        },
      };
    },
  };
  return { db: mockDb, users: { id: "id", phone: "phone" }, poojas: {}, products: {}, bookings: {} };
});

import app from "../app.js";

const PROFILE_USER = {
  id: "00000000-0000-0000-0000-000000000001",
  phone: "+919876543210",
  name: "Test User",
  role: "YAJMAN",
  dob: null,
  tob: null,
  pob: null,
  gotra: null,
  zodiac: null,
  city: null,
  email: null,
};

describe("GET /api/v1/users/profile", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("200 – returns profile for authenticated user", async () => {
    mockFindFirst.mockResolvedValue(PROFILE_USER);

    const res = await request(app)
      .get("/api/v1/users/profile")
      .set("Authorization", `Bearer ${yajmanToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty("fullName", "Test User");
  });

  it("401 – rejects request without token", async () => {
    const res = await request(app).get("/api/v1/users/profile");

    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe("MISSING_TOKEN");
  });
});

describe("PUT /api/v1/users/profile", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("200 – updates profile with valid fields", async () => {
    mockReturning.mockResolvedValue([{ ...PROFILE_USER, name: "New Name" }]);

    const res = await request(app)
      .put("/api/v1/users/profile")
      .set("Authorization", `Bearer ${yajmanToken}`)
      .send({ fullName: "New Name" });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  it("400 – rejects unknown fields (.strict)", async () => {
    const res = await request(app)
      .put("/api/v1/users/profile")
      .set("Authorization", `Bearer ${yajmanToken}`)
      .send({ fullName: "Test", role: "ADMIN" });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("VALIDATION_ERROR");
  });

  it("401 – rejects without token", async () => {
    const res = await request(app)
      .put("/api/v1/users/profile")
      .send({ fullName: "Test" });

    expect(res.status).toBe(401);
  });
});
