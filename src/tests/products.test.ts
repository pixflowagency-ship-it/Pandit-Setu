import { describe, it, expect, vi } from "vitest";
import request from "supertest";

/* ------------------------------------------------------------------ *
 *  Mock the DB module                                                  *
 * ------------------------------------------------------------------ */
vi.mock("../db/index.js", () => {
  const mockRow = { id: "p1", name: "Samagri Kit", price: "499.00", isActive: true };
  const countResult = [{ total: 1 }];

  // Build a chainable mock that handles both data and count queries
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
      // Odd calls = data query, even calls = count query
      if (callCount % 2 === 1) {
        return makeChain([mockRow]);
      }
      return makeChain(countResult);
    }),
    query: { users: { findFirst: vi.fn() } },
  };

  return {
    db: mockDb,
    users: {},
    products: { isActive: "is_active" },
    poojas: {},
    bookings: {},
  };
});

import app from "../app.js";

describe("GET /api/v1/products", () => {
  it("200 – returns paginated products", async () => {
    const res = await request(app).get("/api/v1/products?page=1&limit=5");

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty("pagination");
    expect(res.body.data.pagination.limit).toBeLessThanOrEqual(50);
  });

  it("200 – uses default pagination when no params", async () => {
    const res = await request(app).get("/api/v1/products");

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  it("400 – rejects limit > 50", async () => {
    const res = await request(app).get("/api/v1/products?limit=999");

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("VALIDATION_ERROR");
  });

  it("400 – rejects unknown query param (.strict)", async () => {
    const res = await request(app).get("/api/v1/products?sort=price");

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("VALIDATION_ERROR");
  });
});
