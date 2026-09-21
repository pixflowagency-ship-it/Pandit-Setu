import { describe, it, expect, vi } from "vitest";
import request from "supertest";

/* ------------------------------------------------------------------ *
 *  Mock the DB module                                                  *
 * ------------------------------------------------------------------ */
vi.mock("../db/index.js", () => {
  const mockPooja = { id: "j1", title: "Satyanarayan Pooja", slug: "satyanarayan", isActive: true };
  const countResult = [{ total: 1 }];

  const makeChain = (resolveValue: unknown) => {
    const chain: Record<string, unknown> = {};
    chain.from = vi.fn().mockReturnValue(chain);
    chain.where = vi.fn().mockReturnValue(chain);
    chain.limit = vi.fn().mockReturnValue(chain);
    chain.offset = vi.fn().mockReturnValue(chain);
    chain.then = (resolve: (v: unknown) => void) => resolve(resolveValue);
    return chain;
  };

  let callCount = 0;
  const mockDb = {
    select: vi.fn().mockImplementation(() => {
      callCount++;
      if (callCount % 2 === 1) {
        return makeChain([mockPooja]);
      }
      return makeChain(countResult);
    }),
    query: { users: { findFirst: vi.fn() } },
  };

  return {
    db: mockDb,
    users: {},
    products: {},
    poojas: { isActive: "is_active" },
    bookings: {},
  };
});

import app from "../app.js";

describe("GET /api/v1/poojas", () => {
  it("200 – returns paginated poojas", async () => {
    const res = await request(app).get("/api/v1/poojas?page=1&limit=10");

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty("pagination");
  });

  it("400 – rejects negative page", async () => {
    const res = await request(app).get("/api/v1/poojas?page=-1");

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("VALIDATION_ERROR");
  });

  it("400 – rejects limit > 50", async () => {
    const res = await request(app).get("/api/v1/poojas?limit=100");

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("VALIDATION_ERROR");
  });
});
