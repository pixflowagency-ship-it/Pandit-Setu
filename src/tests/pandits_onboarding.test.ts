import { describe, it, expect, vi, beforeEach } from "vitest";
import request from "supertest";
import app from "../app.js";
import { signTestToken, yajmanToken } from "./helpers/setup.js";

// Mock DB
const {
  mockFindFirst,
  mockFindMany,
  mockInsert,
  mockUpdate,
  mockDelete,
} = vi.hoisted(() => ({
  mockFindFirst: vi.fn(),
  mockFindMany: vi.fn(),
  mockInsert: vi.fn(),
  mockUpdate: vi.fn(),
  mockDelete: vi.fn(),
}));

vi.mock("../db/index.js", () => ({
  db: {
    query: {
      users: { findFirst: (...args: any[]) => mockFindFirst(...args) },
      pandits: { findFirst: (...args: any[]) => mockFindFirst(...args), findMany: (...args: any[]) => mockFindMany(...args) },
      panditDocuments: { findFirst: (...args: any[]) => mockFindFirst(...args), findMany: (...args: any[]) => mockFindMany(...args) },
    },
    insert: (...args: any[]) => mockInsert(...args),
    update: (...args: any[]) => mockUpdate(...args),
    delete: (...args: any[]) => mockDelete(...args),
  },
  users: {},
  pandits: {},
  panditDocuments: {},
}));

describe("Pandit Onboarding & Verification Workflow", () => {
  const panditUserId = "44444444-4444-4444-4444-444444444444";
  const panditId = "p-test-uuid";
  const panditToken = signTestToken({
    id: panditUserId,
    phone: "+919876543210",
    role: "PANDIT",
  });

  const adminToken = signTestToken({
    id: "admin-uuid-1",
    phone: "+919999999999",
    role: "ADMIN",
  });

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("401 – rejects unauthenticated access to onboarding status", async () => {
    const res = await request(app).get("/api/v1/pandits/me/onboarding-status");
    expect(res.status).toBe(401);
  });

  it("403 – Yajman role cannot access pandit onboarding status", async () => {
    const res = await request(app)
      .get("/api/v1/pandits/me/onboarding-status")
      .set("Authorization", `Bearer ${yajmanToken}`);
    expect(res.status).toBe(403);
  });

  it("200 – Yajman can apply for Pandit role without duplicate phone identity", async () => {
    const userYajman = { id: "u-yajman-1", phone: "9876543210", name: "Devotee One", role: "YAJMAN" };
    mockFindFirst.mockResolvedValueOnce(userYajman).mockResolvedValueOnce(null); // No existing pandit

    mockInsert.mockReturnValue({
      values: vi.fn().mockReturnValue({
        returning: vi.fn().mockResolvedValue([{
          id: "new-p-1",
          userId: userYajman.id,
          verificationStatus: "PENDING",
          verificationStage: "STAGE_1_COMPLETE",
          isVerified: false,
        }]),
      }),
    });

    const res = await request(app)
      .post("/api/v1/pandits/apply")
      .set("Authorization", `Bearer ${yajmanToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.pandit.verificationStatus).toBe("PENDING");
    expect(res.body.data.pandit.verificationStage).toBe("STAGE_1_COMPLETE");
    expect(res.body.data.token).toBeDefined();
  });

  it("200 – returns authoritative onboarding status for pandit", async () => {
    const mockPandit = {
      id: panditId,
      userId: panditUserId,
      verificationStatus: "PENDING",
      verificationStage: "STAGE_1_COMPLETE",
      isVerified: false,
      experienceYears: 4,
      vedicSpecialization: "Rigveda Karmakand",
      languages: ["Hindi", "Sanskrit"],
      bio: "Devoted Acharya",
      videoCallStatus: "PENDING",
    };

    mockFindFirst.mockResolvedValueOnce(mockPandit);
    mockFindMany.mockResolvedValueOnce([]); // no docs yet

    const res = await request(app)
      .get("/api/v1/pandits/me/onboarding-status")
      .set("Authorization", `Bearer ${panditToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.verificationStatus).toBe("PENDING");
    expect(res.body.data.verificationStage).toBe("STAGE_1_COMPLETE");
    expect(res.body.data.canAccessDashboard).toBe(false);
  });

  it("400 – document upload rejects invalid file mime type", async () => {
    const mockPandit = { id: panditId, userId: panditUserId };
    mockFindFirst.mockResolvedValueOnce(mockPandit);

    const res = await request(app)
      .post("/api/v1/pandits/me/documents")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({
        docType: "AADHAAR",
        fileName: "malicious.exe",
        mimeType: "application/x-msdownload",
        fileDataBase64: Buffer.from("bad-executable-content").toString("base64"),
      });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("INVALID_FILE_TYPE");
  });

  it("400 – document upload rejects spoofed mime type if magic bytes mismatch", async () => {
    const mockPandit = { id: panditId, userId: panditUserId };
    mockFindFirst.mockResolvedValueOnce(mockPandit);

    const res = await request(app)
      .post("/api/v1/pandits/me/documents")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({
        docType: "AADHAAR",
        fileName: "fake.pdf",
        mimeType: "application/pdf",
        fileDataBase64: Buffer.alloc(150, "A").toString("base64"),
      });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("CONTENT_VALIDATION_FAILED");
  });

  it("201 – document upload with valid PDF magic bytes saves with PENDING status", async () => {
    const mockPandit = { id: panditId, userId: panditUserId };
    mockFindFirst.mockResolvedValueOnce(mockPandit);

    // Valid PDF starts with %PDF-
    const validPdfBuffer = Buffer.concat([
      Buffer.from("%PDF-1.4\n%âãÏÓ\n"),
      Buffer.alloc(200, "a"),
    ]);

    mockInsert.mockReturnValue({
      values: vi.fn().mockReturnValue({
        returning: vi.fn().mockResolvedValue([{
          id: "doc-1",
          panditId,
          docType: "AADHAAR",
          docUrl: "aadhaar_test.pdf",
          fileName: "aadhaar_front.pdf",
          fileSize: validPdfBuffer.length,
          mimeType: "application/pdf",
          status: "PENDING",
          createdAt: new Date(),
        }]),
      }),
    });

    const res = await request(app)
      .post("/api/v1/pandits/me/documents")
      .set("Authorization", `Bearer ${panditToken}`)
      .send({
        docType: "AADHAAR",
        fileName: "aadhaar_front.pdf",
        mimeType: "application/pdf",
        fileDataBase64: validPdfBuffer.toString("base64"),
        docNumber: "987654321012",
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.status).toBe("PENDING");
  });

  it("403 – a Pandit cannot download another Pandit's private document", async () => {
    const otherPanditId = "other-pandit-uuid";
    const mockDoc = { id: "doc-2", panditId: otherPanditId, docUrl: "other.pdf", mimeType: "application/pdf" };
    const otherPandit = { id: otherPanditId, userId: "other-user-uuid" };

    mockFindFirst
      .mockResolvedValueOnce(mockDoc)
      .mockResolvedValueOnce(otherPandit);

    const res = await request(app)
      .get("/api/v1/pandits/me/documents/doc-2/download")
      .set("Authorization", `Bearer ${panditToken}`); // panditUserId !== other-user-uuid

    expect(res.status).toBe(403);
    expect(res.body.error.code).toBe("FORBIDDEN");
  });

  it("403 – a Pandit cannot approve their own application", async () => {
    const res = await request(app)
      .patch(`/api/v1/pandits/admin/${panditId}/approval`)
      .set("Authorization", `Bearer ${panditToken}`) // PANDIT role, not ADMIN
      .send({ status: "APPROVED" });

    expect(res.status).toBe(403);
    expect(res.body.error.code).toBe("FORBIDDEN");
  });

  it("400 – document submission cannot skip profile requirement", async () => {
    const unprofiledPandit = {
      id: panditId,
      userId: panditUserId,
      verificationStage: "STAGE_1_COMPLETE",
      bio: null,
      experienceYears: null,
    };
    mockFindFirst.mockResolvedValueOnce(unprofiledPandit);

    const res = await request(app)
      .post("/api/v1/pandits/me/submit-for-review")
      .set("Authorization", `Bearer ${panditToken}`);

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("PROFILE_INCOMPLETE");
  });

  it("400 – admin cannot approve a pandit prematurely before review is completed", async () => {
    const stage1Pandit = { id: panditId, userId: panditUserId, verificationStage: "STAGE_1_COMPLETE" };
    mockFindFirst.mockResolvedValueOnce(stage1Pandit);

    const res = await request(app)
      .patch(`/api/v1/pandits/admin/${panditId}/approval`)
      .set("Authorization", `Bearer ${adminToken}`)
      .send({ status: "APPROVED" });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("INVALID_STATE_TRANSITION");
  });

  it("200 – authorized admin can approve pandit application after review", async () => {
    const reviewedPandit = {
      id: panditId,
      userId: panditUserId,
      verificationStage: "VIDEO_VERIFICATION_COMPLETED",
    };
    mockFindFirst.mockResolvedValueOnce(reviewedPandit);

    mockUpdate.mockReturnValue({
      set: vi.fn().mockReturnValue({
        where: vi.fn().mockReturnValue({
          returning: vi.fn().mockResolvedValue([{
            id: panditId,
            verificationStatus: "APPROVED",
            isVerified: true,
            verificationStage: "APPROVED",
          }]),
        }),
      }),
    });

    const res = await request(app)
      .patch(`/api/v1/pandits/admin/${panditId}/approval`)
      .set("Authorization", `Bearer ${adminToken}`)
      .send({ status: "APPROVED" });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.verificationStatus).toBe("APPROVED");
    expect(res.body.data.isVerified).toBe(true);
  });
});
