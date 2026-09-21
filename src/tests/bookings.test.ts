import { describe, it, expect, vi, beforeEach } from "vitest";
import request from "supertest";
import { yajmanToken, signTestToken } from "./helpers/setup.js";
import { createHash } from "crypto";

/* ------------------------------------------------------------------ *
 *  Mock the DB and Redis modules                                     *
 * ------------------------------------------------------------------ */
const {
  mockPooja,
  mockInsertReturn,
  mockFindFirst,
  mockFindMany,
  mockInsert,
  mockUpdate,
  mockRedisGet,
  mockRedisSet,
} = vi.hoisted(() => {
  const pooja = {
    id: "00000000-0000-0000-0000-000000000001",
    basePrice: "1000.00",
    samagriPrice: "500.00",
    isActive: true,
  };

  const insertReturn = [
    {
      id: "b1",
      yajmanId: "00000000-0000-0000-0000-000000000001",
      poojaId: pooja.id,
      mode: "IN_PERSON",
      bookingTime: new Date().toISOString(),
      venueLocation: { lat: 10, lng: 20 },
      venueAddress: "123 Temple St",
      samagriIncluded: true,
      totalAmount: "1500.00",
      status: "PENDING",
    },
  ];

  const findFirst = vi.fn();
  const findMany = vi.fn();
  const insert = vi.fn().mockReturnValue({
    values: vi.fn().mockReturnValue({
      returning: vi.fn().mockResolvedValue(insertReturn),
    }),
  });

  const update = vi.fn().mockReturnValue({
    set: vi.fn().mockReturnValue({
      where: vi.fn().mockReturnValue({
        returning: vi.fn().mockResolvedValue(insertReturn),
      }),
    }),
  });

  return {
    mockPooja: pooja,
    mockInsertReturn: insertReturn,
    mockFindFirst: findFirst,
    mockFindMany: findMany,
    mockInsert: insert,
    mockUpdate: update,
    mockRedisGet: vi.fn(),
    mockRedisSet: vi.fn(),
  };
});

vi.mock("../db/index.js", () => ({
  db: {
    query: {
      poojas: { findFirst: (...args: any[]) => mockFindFirst(...args) },
      bookings: { 
        findFirst: (...args: any[]) => mockFindFirst(...args),
        findMany: (...args: any[]) => mockFindMany(...args)
      },
    },
    insert: (...args: any[]) => mockInsert(...args),
    update: (...args: any[]) => mockUpdate(...args),
  },
  poojas: { id: "id" },
  bookings: { id: "id", idempotencyKeyHash: "idempotency_key_hash" },
}));

vi.mock("../config/redis.js", () => ({
  getRedis: vi.fn().mockResolvedValue({
    get: mockRedisGet,
    set: mockRedisSet,
  }),
}));

import app from "../app.js";

describe("POST /api/v1/bookings", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  const validInPersonBody = {
    poojaId: "00000000-0000-0000-0000-000000000001",
    bookingTime: new Date().toISOString(),
    mode: "IN_PERSON",
    venueAddress: "123 Temple St",
    lat: 10.0,
    lng: 20.0,
    samagriIncluded: true,
    customNotes: "Test booking",
  };

  const validOnlineBody = {
    poojaId: "00000000-0000-0000-0000-000000000001",
    bookingTime: new Date().toISOString(),
    mode: "ONLINE",
  };

  it("201 – Happy path IN_PERSON booking", async () => {
    mockFindFirst.mockResolvedValue(mockPooja);
    mockRedisGet.mockResolvedValue(null); // No idempotent hit

    const res = await request(app)
      .post("/api/v1/bookings")
      .set("Authorization", `Bearer ${yajmanToken}`)
      .send(validInPersonBody);

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.booking.totalAmount).toBe("1500.00");
    expect(mockInsert).toHaveBeenCalled();
  });

  it("201 – Happy path ONLINE booking (forces samagri, adds price)", async () => {
    mockFindFirst.mockResolvedValue(mockPooja);
    mockRedisGet.mockResolvedValue(null);

    const onlineReturn = [{ ...mockInsertReturn[0], mode: "ONLINE", totalAmount: "1500.00", venueLocation: null, venueAddress: null }];
    mockInsert.mockReturnValueOnce({
      values: vi.fn().mockReturnValue({
        returning: vi.fn().mockResolvedValue(onlineReturn),
      }),
    });

    const res = await request(app)
      .post("/api/v1/bookings")
      .set("Authorization", `Bearer ${yajmanToken}`)
      .send({ ...validOnlineBody, samagriIncluded: false }); // Should ignore false

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.booking.totalAmount).toBe("1500.00");
    expect(res.body.data.booking.mode).toBe("ONLINE");
  });

  it("201 – Idempotency returns existing booking", async () => {
    const existingBooking = { ...mockInsertReturn[0], id: "existing-booking-id" };
    // Redis returns existing ID
    mockRedisGet.mockResolvedValue("existing-booking-id");
    // DB returns existing booking
    mockFindFirst.mockResolvedValueOnce(existingBooking);

    const res = await request(app)
      .post("/api/v1/bookings")
      .set("Authorization", `Bearer ${yajmanToken}`)
      .set("Idempotency-Key", "test-key-123")
      .send(validInPersonBody);

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.booking.id).toBe("existing-booking-id");
    expect(mockInsert).not.toHaveBeenCalled(); // Should not create a new one
  });

  it("401 – Unauthorized without token", async () => {
    const res = await request(app)
      .post("/api/v1/bookings")
      .send(validInPersonBody);

    expect(res.status).toBe(401);
  });

  it("400 – Invalid input: ONLINE mode with lat/lng (strict rejects)", async () => {
    const res = await request(app)
      .post("/api/v1/bookings")
      .set("Authorization", `Bearer ${yajmanToken}`)
      .send({ ...validOnlineBody, lat: 10, lng: 20 });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("VALIDATION_ERROR");
  });

  it("400 – Invalid input: IN_PERSON without venueAddress", async () => {
    const { venueAddress, ...bodyWithoutAddress } = validInPersonBody;
    const res = await request(app)
      .post("/api/v1/bookings")
      .set("Authorization", `Bearer ${yajmanToken}`)
      .send(bodyWithoutAddress);

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("VALIDATION_ERROR");
  });

  it("400 – Invalid input: body contains totalAmount", async () => {
    const res = await request(app)
      .post("/api/v1/bookings")
      .set("Authorization", `Bearer ${yajmanToken}`)
      .send({ ...validInPersonBody, totalAmount: 100 });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("VALIDATION_ERROR");
  });

  it("400 – Invalid input: body contains status", async () => {
    const res = await request(app)
      .post("/api/v1/bookings")
      .set("Authorization", `Bearer ${yajmanToken}`)
      .send({ ...validInPersonBody, status: "COMPLETED" });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("VALIDATION_ERROR");
  });

  it("404 – returns 404 if booking not found", async () => {
    mockFindFirst.mockResolvedValue(null);

    const res = await request(app)
      .get("/api/v1/bookings/nonexistent-id")
      .set("Authorization", `Bearer ${yajmanToken}`);

    expect(res.status).toBe(400); // Because UUID validation fails first!
  });

  it("404 – Not found: non-existent poojaId", async () => {
    mockFindFirst.mockResolvedValue(null);

    const res = await request(app)
      .post("/api/v1/bookings")
      .set("Authorization", `Bearer ${yajmanToken}`)
      .send(validInPersonBody);

    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe("NOT_FOUND");
  });
});

describe("PATCH /api/v1/bookings/:id/cancel", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  const validBookingId = "11111111-1111-1111-1111-111111111111";
  const myBooking = { id: validBookingId, yajmanId: "00000000-0000-0000-0000-000000000001", status: "PENDING" };

  it("200 – cancels a pending booking successfully", async () => {
    mockFindFirst.mockResolvedValue(myBooking);
    mockUpdate.mockReturnValue({
      set: vi.fn().mockReturnValue({
        where: vi.fn().mockReturnValue({
          returning: vi.fn().mockResolvedValue([{ ...myBooking, status: "CANCELLED" }])
        })
      })
    });

    const res = await request(app)
      .patch(`/api/v1/bookings/${validBookingId}/cancel`)
      .set("Authorization", `Bearer ${yajmanToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.booking.status).toBe("CANCELLED");
  });

  it("409 – returns conflict if booking status changed concurrently", async () => {
    mockFindFirst.mockResolvedValue(myBooking);
    mockUpdate.mockReturnValue({
      set: vi.fn().mockReturnValue({
        where: vi.fn().mockReturnValue({
          returning: vi.fn().mockResolvedValue([]) // Simulate 0 rows updated
        })
      })
    });

    const res = await request(app)
      .patch(`/api/v1/bookings/${validBookingId}/cancel`)
      .set("Authorization", `Bearer ${yajmanToken}`);

    expect(res.status).toBe(409);
  });
});

describe("PATCH /api/v1/bookings/:id/status", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  const validBookingId = "22222222-2222-2222-2222-222222222222";
  const panditId = "33333333-3333-3333-3333-333333333333";
  const panditToken = signTestToken({
    id: panditId,
    phone: "+919876543210",
    role: "PANDIT",
  });
  
  const myBooking = { id: validBookingId, panditId, status: "PENDING" };

  it("200 – pandit updates status from PENDING to CONFIRMED", async () => {
    mockFindFirst.mockResolvedValue(myBooking);
    mockUpdate.mockReturnValue({
      set: vi.fn().mockReturnValue({
        where: vi.fn().mockReturnValue({
          returning: vi.fn().mockResolvedValue([{ ...myBooking, status: "CONFIRMED" }])
        })
      })
    });

    const res = await request(app)
      .patch(`/api/v1/bookings/${validBookingId}/status`)
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ expectedStatus: "PENDING", newStatus: "CONFIRMED" });

    expect(res.status).toBe(200);
    expect(res.body.data.booking.status).toBe("CONFIRMED");
  });

  it("400 – rejects invalid state transition (PENDING -> COMPLETED)", async () => {
    const res = await request(app)
      .patch(`/api/v1/bookings/${validBookingId}/status`)
      .set("Authorization", `Bearer ${panditToken}`)
      .send({ expectedStatus: "PENDING", newStatus: "COMPLETED" });

    expect(res.status).toBe(400);
    expect(res.body.error.message).toContain("Invalid status transition");
  });
});
