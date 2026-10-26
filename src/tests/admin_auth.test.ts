import { describe, it, expect, vi, beforeEach } from "vitest";
import request from "supertest";
import app from "../app.js";
import { hashPassword, verifyPassword } from "../utils/password.js";
import { signTestToken, signExpiredToken, yajmanToken, adminToken } from "./helpers/setup.js";
import { clearRevocationMemoryStore } from "../services/token-revocation.service.js";

// Mock DB
const { mockFindFirst } = vi.hoisted(() => ({
  mockFindFirst: vi.fn(),
}));

vi.mock("../db/index.js", () => {
  return {
    db: {
      query: {
        users: {
          findFirst: (...args: any[]) => mockFindFirst(...args),
        },
      },
    },
    users: {
      id: "users.id",
      email: "users.email",
      role: "users.role",
    },
  };
});

describe("Phase P7: Dedicated Admin Authentication & RBAC Guards", () => {
  const panditToken = signTestToken({
    id: "pandit-user-id",
    phone: "+919876543210",
    role: "PANDIT",
  });

  beforeEach(() => {
    vi.clearAllMocks();
    clearRevocationMemoryStore();
  });

  describe("Password Hashing & Verification Utility", () => {
    it("generates unique salts and hashes for the same password", () => {
      const pass = "Test@AdminPass#2026";
      const cred1 = hashPassword(pass);
      const cred2 = hashPassword(pass);

      expect(cred1.salt).not.toBe(cred2.salt);
      expect(cred1.hash).not.toBe(cred2.hash);
      expect(cred1.salt.length).toBe(32); // 16 bytes hex
      expect(cred1.hash.length).toBe(128); // 64 bytes hex
    });

    it("verifies matching password correctly", () => {
      const pass = "SuperSecretAdmin#1";
      const { hash, salt } = hashPassword(pass);

      expect(verifyPassword(pass, hash, salt)).toBe(true);
      expect(verifyPassword("WrongPassword", hash, salt)).toBe(false);
    });

    it("gracefully returns false on malformed or empty inputs", () => {
      expect(verifyPassword("", "hash", "salt")).toBe(false);
      expect(verifyPassword("pass", "", "salt")).toBe(false);
      expect(verifyPassword("pass", "invalid_hex", "salt")).toBe(false);
    });
  });

  describe("POST /api/v1/admin/auth/login", () => {
    it("400 – rejects request with invalid email format", async () => {
      const res = await request(app)
        .post("/api/v1/admin/auth/login")
        .send({ email: "not-an-email", password: "Password123" });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it("400 – rejects request with short password (< 8 chars)", async () => {
      const res = await request(app)
        .post("/api/v1/admin/auth/login")
        .send({ email: "admin@sarvmangal.app", password: "short" });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it("401 – rejects non-existent admin user", async () => {
      mockFindFirst.mockResolvedValueOnce(null);

      const res = await request(app)
        .post("/api/v1/admin/auth/login")
        .send({ email: "unknown@sarvmangal.app", password: "Password123!" });

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe("INVALID_CREDENTIALS");
    });

    it("401 – rejects user who exists but has non-ADMIN role", async () => {
      const { hash, salt } = hashPassword("ValidPassword123!");
      mockFindFirst.mockResolvedValueOnce({
        id: "devotee-1",
        email: "devotee@sarvmangal.app",
        role: "YAJMAN",
        passwordHash: hash,
        passwordSalt: salt,
      });

      const res = await request(app)
        .post("/api/v1/admin/auth/login")
        .send({ email: "devotee@sarvmangal.app", password: "ValidPassword123!" });

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe("INVALID_CREDENTIALS");
    });

    it("401 – rejects invalid password for admin user", async () => {
      const { hash, salt } = hashPassword("CorrectAdminPass123!");
      mockFindFirst.mockResolvedValueOnce({
        id: "admin-1",
        email: "admin@sarvmangal.app",
        role: "ADMIN",
        passwordHash: hash,
        passwordSalt: salt,
      });

      const res = await request(app)
        .post("/api/v1/admin/auth/login")
        .send({ email: "admin@sarvmangal.app", password: "WrongPassword999!" });

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe("INVALID_CREDENTIALS");
    });

    it("200 – succeeds for valid admin credentials and returns JWT + user profile", async () => {
      const pass = "Test@AdminPass#2026";
      const { hash, salt } = hashPassword(pass);
      mockFindFirst.mockResolvedValueOnce({
        id: "admin-uuid-1234",
        phone: "+919999900000",
        name: "SARV MANGAL Admin Desk",
        email: "admin@sarvmangal.app",
        role: "ADMIN",
        passwordHash: hash,
        passwordSalt: salt,
      });

      const res = await request(app)
        .post("/api/v1/admin/auth/login")
        .send({ email: "admin@sarvmangal.app", password: pass });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty("token");
      expect(res.body.data.user).toEqual({
        id: "admin-uuid-1234",
        email: "admin@sarvmangal.app",
        name: "SARV MANGAL Admin Desk",
        role: "ADMIN",
      });
    });
  });

  describe("GET /api/v1/admin/auth/me", () => {
    it("401 – rejects unauthenticated access", async () => {
      const res = await request(app).get("/api/v1/admin/auth/me");
      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it("403 – rejects devotee (YAJMAN) role", async () => {
      const res = await request(app)
        .get("/api/v1/admin/auth/me")
        .set("Authorization", `Bearer ${yajmanToken}`);

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });

    it("403 – rejects Pandit role", async () => {
      const res = await request(app)
        .get("/api/v1/admin/auth/me")
        .set("Authorization", `Bearer ${panditToken}`);

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });

    it("200 – returns profile for authenticated admin", async () => {
      mockFindFirst.mockResolvedValueOnce({
        id: "admin-user-id",
        name: "SARV MANGAL Admin Desk",
        email: "admin@sarvmangal.app",
        phone: "+919999900000",
        role: "ADMIN",
      });

      const res = await request(app)
        .get("/api/v1/admin/auth/me")
        .set("Authorization", `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.user.email).toBe("admin@sarvmangal.app");
      expect(res.body.data.user.role).toBe("ADMIN");
    });
  });

  describe("POST /api/v1/admin/auth/logout & Server-Side Token Revocation", () => {
    it("401 – rejects unauthenticated logout attempt", async () => {
      const res = await request(app).post("/api/v1/admin/auth/logout");
      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it("403 – forbids Devotee (YAJMAN) role from accessing admin logout", async () => {
      const res = await request(app)
        .post("/api/v1/admin/auth/logout")
        .set("Authorization", `Bearer ${yajmanToken}`);

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });

    it("403 – forbids Pandit role from accessing admin logout", async () => {
      const res = await request(app)
        .post("/api/v1/admin/auth/logout")
        .set("Authorization", `Bearer ${panditToken}`);

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });

    it("200 – successfully accepts logout and returns confirmation message", async () => {
      const tempToken = signTestToken({
        id: "temp-admin-id",
        phone: "+919999900001",
        role: "ADMIN",
      });

      const res = await request(app)
        .post("/api/v1/admin/auth/logout")
        .set("Authorization", `Bearer ${tempToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty("message");
    });

    it("REGRESSION: Admin token works before logout, succeeds logout, and is strictly rejected after logout", async () => {
      const sessionToken = signTestToken({
        id: "session-admin-1",
        phone: "+919999912345",
        role: "ADMIN",
      });

      // 1. Token works before logout
      mockFindFirst.mockResolvedValueOnce({
        id: "session-admin-1",
        email: "session.admin@sarvmangal.app",
        role: "ADMIN",
        name: "Session Admin",
        phone: "+919999912345",
      });

      const preLogoutRes = await request(app)
        .get("/api/v1/admin/auth/me")
        .set("Authorization", `Bearer ${sessionToken}`);

      expect(preLogoutRes.status).toBe(200);
      expect(preLogoutRes.body.success).toBe(true);

      // 2. Perform logout to revoke token on server
      const logoutRes = await request(app)
        .post("/api/v1/admin/auth/logout")
        .set("Authorization", `Bearer ${sessionToken}`);

      expect(logoutRes.status).toBe(200);
      expect(logoutRes.body.success).toBe(true);

      // 3. Post-logout reuse attempt is strictly rejected
      const postLogoutRes = await request(app)
        .get("/api/v1/admin/auth/me")
        .set("Authorization", `Bearer ${sessionToken}`);

      expect(postLogoutRes.status).toBe(401);
      expect(postLogoutRes.body.success).toBe(false);
      expect(postLogoutRes.body.error.code).toBe("TOKEN_REVOKED");

      // 4. Repeated logout with already revoked token is also rejected
      const repeatLogoutRes = await request(app)
        .post("/api/v1/admin/auth/logout")
        .set("Authorization", `Bearer ${sessionToken}`);

      expect(repeatLogoutRes.status).toBe(401);
      expect(repeatLogoutRes.body.success).toBe(false);
      expect(repeatLogoutRes.body.error.code).toBe("TOKEN_REVOKED");
    });

    it("401 – rejects expired token with TOKEN_EXPIRED error", async () => {
      const expiredToken = signExpiredToken({
        id: "expired-admin",
        phone: "+919999900000",
        role: "ADMIN",
      });

      const res = await request(app)
        .get("/api/v1/admin/auth/me")
        .set("Authorization", `Bearer ${expiredToken}`);

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe("TOKEN_EXPIRED");
    });

    it("401 – rejects malformed or fabricated token with INVALID_TOKEN error", async () => {
      const res = await request(app)
        .get("/api/v1/admin/auth/me")
        .set("Authorization", "Bearer not-a-valid-jwt-token-string");

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe("INVALID_TOKEN");
    });

    it("Resilience: token revocation and rejection succeeds even when Redis is unavailable", async () => {
      const isolatedToken = signTestToken({
        id: "redis-fail-admin",
        phone: "+919999900099",
        role: "ADMIN",
      });

      // Logout succeeds and records into in-memory store
      const logoutRes = await request(app)
        .post("/api/v1/admin/auth/logout")
        .set("Authorization", `Bearer ${isolatedToken}`);

      expect(logoutRes.status).toBe(200);
      expect(logoutRes.body.success).toBe(true);

      // Reused token is rejected via in-memory store
      const reuseRes = await request(app)
        .get("/api/v1/admin/auth/me")
        .set("Authorization", `Bearer ${isolatedToken}`);

      expect(reuseRes.status).toBe(401);
      expect(reuseRes.body.error.code).toBe("TOKEN_REVOKED");
    });
  });
});
