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
      panditMantraRecordings: { findFirst: (...args: any[]) => mockFindFirst(...args), findMany: (...args: any[]) => mockFindMany(...args) },
      approvedMantras: { findFirst: (...args: any[]) => mockFindFirst(...args), findMany: (...args: any[]) => mockFindMany(...args) },
    },
    insert: (...args: any[]) => mockInsert(...args),
    update: (...args: any[]) => mockUpdate(...args),
    delete: (...args: any[]) => mockDelete(...args),
  },
  users: {},
  pandits: {},
  panditDocuments: {},
  panditMantraRecordings: {},
  approvedMantras: {},
}));

describe("SARV MANGAL — Pandit Mantra Recording Verification Suite", () => {
  const panditUserId = "55555555-5555-5555-5555-555555555555";
  const panditId = "pandit-record-test-id";
  const recordingId = "rec-test-123";

  const panditToken = signTestToken({
    id: panditUserId,
    phone: "+919876543210",
    role: "PANDIT",
  });

  const otherPanditToken = signTestToken({
    id: "other-user-pandit-2",
    phone: "+919876543211",
    role: "PANDIT",
  });

  const adminToken = signTestToken({
    id: "admin-user-id-99",
    phone: "+919999999999",
    role: "ADMIN",
  });

  // Valid standard WAV RIFF header buffer helper
  function createTestWavBase64(durationSeconds: number = 15): string {
    const sampleRate = 16000;
    const numSamples = sampleRate * durationSeconds;
    const dataSize = numSamples * 2;
    const totalSize = 36 + dataSize;
    const buf = Buffer.alloc(44 + dataSize);

    buf.write("RIFF", 0);
    buf.writeUInt32LE(totalSize, 4);
    buf.write("WAVE", 8);
    buf.write("fmt ", 12);
    buf.writeUInt32LE(16, 16);
    buf.writeUInt16LE(1, 20); // PCM
    buf.writeUInt16LE(1, 22); // Mono
    buf.writeUInt32LE(sampleRate, 24);
    buf.writeUInt32LE(sampleRate * 2, 28);
    buf.writeUInt16LE(2, 32);
    buf.writeUInt16LE(16, 34);
    buf.write("data", 36);
    buf.writeUInt32LE(dataSize, 40);

    return buf.toString("base64");
  }

  // Valid standard MP4 ISO Base Media File Format buffer helper
  function createTestMp4Base64(durationSeconds: number = 15): string {
    const totalFrames = durationSeconds * 30;
    const mediaSize = totalFrames * 240;
    const buf = Buffer.alloc(32 + 120 + 8 + mediaSize);

    // ftyp box
    buf.writeUInt32BE(32, 0);
    buf.write("ftyp", 4);
    buf.write("isom", 8);
    buf.writeUInt32BE(0x00000200, 12);
    buf.write("isom", 16);
    buf.write("mp41", 20);
    buf.write("mp42", 24);
    buf.write("    ", 28);

    // moov box
    buf.writeUInt32BE(120, 32);
    buf.write("moov", 36);
    buf.write("SARV_MANGAL_VIDEO_RECITATION", 40);

    // mdat box
    buf.writeUInt32BE(8 + mediaSize, 152);
    buf.write("mdat", 156);
    buf.fill(0x55, 160);

    return buf.toString("base64");
  }

  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe("1. Catalog of Approved Mantras", () => {
    it("200 – returns approved Sanskrit mantra prompts with guidance", async () => {
      const res = await request(app).get("/api/v1/pandits/mantras");
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data.mantras)).toBe(true);
      expect(res.body.data.mantras.length).toBeGreaterThanOrEqual(5);

      const gayatri = res.body.data.mantras.find((m: any) => m.id === "GAYATRI_MANTRA");
      expect(gayatri).toBeDefined();
      expect(gayatri.sanskritText).toContain("ॐ भूर्भुवः स्वः");
      expect(gayatri.pronunciationGuidance).toBeDefined();

      const shanti = res.body.data.mantras.find((m: any) => m.id === "SHANTI_MANTRA");
      expect(shanti).toBeDefined();
      expect(shanti.sanskritText).toContain("शान्ति");
    });
  });

  describe("2. Verification Method Selection", () => {
    it("401 – rejects unauthenticated method switch", async () => {
      const res = await request(app)
        .put("/api/v1/pandits/me/verification-method")
        .send({ method: "MANTRA_RECORDING" });
      expect(res.status).toBe(401);
    });

    it("403 – Yajman cannot switch verification method", async () => {
      const res = await request(app)
        .put("/api/v1/pandits/me/verification-method")
        .set("Authorization", `Bearer ${yajmanToken}`)
        .send({ method: "MANTRA_RECORDING" });
      expect(res.status).toBe(403);
    });

    it("400 – rejects invalid verification method enum", async () => {
      const res = await request(app)
        .put("/api/v1/pandits/me/verification-method")
        .set("Authorization", `Bearer ${panditToken}`)
        .send({ method: "INVALID_METHOD" });
      expect(res.status).toBe(400);
    });

    it("200 – successfully selects Mantra Recording method and preserves state", async () => {
      mockFindFirst.mockResolvedValueOnce({
        id: panditId,
        userId: panditUserId,
        verificationMethod: "VIDEO_CALL",
      });

      mockUpdate.mockReturnValue({
        set: vi.fn().mockReturnValue({
          where: vi.fn().mockResolvedValue([{ id: panditId, verificationMethod: "MANTRA_RECORDING" }]),
        }),
      });

      // getOnboardingStatus call in service
      mockFindFirst.mockResolvedValueOnce({
        id: panditId,
        userId: panditUserId,
        verificationMethod: "MANTRA_RECORDING",
        verificationStatus: "PENDING",
        verificationStage: "STAGE_1_COMPLETE",
        videoCallStatus: "PENDING",
        mantraRecordingStatus: "NOT_SUBMITTED",
      });
      mockFindMany.mockResolvedValueOnce([]).mockResolvedValueOnce([]);

      const res = await request(app)
        .put("/api/v1/pandits/me/verification-method")
        .set("Authorization", `Bearer ${panditToken}`)
        .send({ method: "MANTRA_RECORDING" });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.verificationMethod).toBe("MANTRA_RECORDING");
    });
  });

  describe("3. Recording Upload & Validation", () => {
    it("400 – rejects upload without required payload fields", async () => {
      const res = await request(app)
        .post("/api/v1/pandits/me/mantra-recordings")
        .set("Authorization", `Bearer ${panditToken}`)
        .send({});
      expect(res.status).toBe(400);
    });

    it("400 – rejects upload with unaccepted mime type (e.g. image/jpeg)", async () => {
      mockFindFirst.mockResolvedValueOnce({ id: panditId, userId: panditUserId });

      const res = await request(app)
        .post("/api/v1/pandits/me/mantra-recordings")
        .set("Authorization", `Bearer ${panditToken}`)
        .send({
          mantraId: "GAYATRI_MANTRA",
          mantraTitle: "Gayatri Mahamantra",
          fileName: "rec.jpg",
          mimeType: "image/jpeg",
          fileDataBase64: Buffer.from("fake data").toString("base64"),
          durationSeconds: 15,
        });

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe("INVALID_FILE_TYPE");
    });

    it("400 – rejects upload if audio file signature does not match magic bytes", async () => {
      mockFindFirst.mockResolvedValueOnce({ id: panditId, userId: panditUserId });

      const corruptedBase64 = Buffer.from("NOT_A_REAL_WAV_HEADER_DATA_1234567890123456789012345678901234567890").toString("base64");

      const res = await request(app)
        .post("/api/v1/pandits/me/mantra-recordings")
        .set("Authorization", `Bearer ${panditToken}`)
        .send({
          mantraId: "GAYATRI_MANTRA",
          mantraTitle: "Gayatri Mahamantra",
          fileName: "recording.wav",
          mimeType: "audio/wav",
          fileDataBase64: corruptedBase64,
          durationSeconds: 15,
        });

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe("CONTENT_VALIDATION_FAILED");
    });

    it("201 – successfully uploads valid WAV recording and sets PENDING status", async () => {
      mockFindFirst.mockResolvedValueOnce({
        id: panditId,
        userId: panditUserId,
        verificationMethod: "MANTRA_RECORDING",
        verificationStatus: "PENDING",
      });

      const validWavBase64 = createTestWavBase64(14);

      mockInsert.mockReturnValue({
        values: vi.fn().mockReturnValue({
          returning: vi.fn().mockResolvedValue([{
            id: recordingId,
            panditId,
            mantraId: "GAYATRI_MANTRA",
            mantraTitle: "Gayatri Mahamantra (गायत्री महामंत्र)",
            fileName: "rec_gayatri.wav",
            fileSize: 44 + 16000 * 14 * 2,
            mimeType: "audio/wav",
            durationSeconds: 14,
            status: "PENDING",
            createdAt: new Date().toISOString(),
          }]),
        }),
      });

      mockUpdate.mockReturnValue({
        set: vi.fn().mockReturnValue({
          where: vi.fn().mockResolvedValue([{ id: panditId }]),
        }),
      });

      const res = await request(app)
        .post("/api/v1/pandits/me/mantra-recordings")
        .set("Authorization", `Bearer ${panditToken}`)
        .send({
          mantraId: "GAYATRI_MANTRA",
          mantraTitle: "Gayatri Mahamantra (गायत्री महामंत्र)",
          fileName: "rec_gayatri.wav",
          mimeType: "audio/wav",
          fileDataBase64: validWavBase64,
          durationSeconds: 14,
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.recording.status).toBe("PENDING");
      expect(res.body.data.recording.mantraId).toBe("GAYATRI_MANTRA");
    });

    it("201 – successfully uploads valid MP4 video recording with ISO Base Media magic bytes", async () => {
      mockFindFirst.mockResolvedValueOnce({
        id: panditId,
        userId: panditUserId,
        verificationMethod: "MANTRA_VIDEO",
        verificationStatus: "PENDING",
      });

      const validMp4Base64 = createTestMp4Base64(18);

      mockInsert.mockReturnValue({
        values: vi.fn().mockReturnValue({
          returning: vi.fn().mockResolvedValue([{
            id: recordingId,
            panditId,
            mantraId: "MAHAMRITYUNJAYA_MANTRA",
            mantraTitle: "Mahamrityunjaya Mantra (महामृत्युंजय मंत्र)",
            fileName: "video_rec_mahamrityunjaya.mp4",
            fileSize: 32 + 120 + 8 + 18 * 30 * 240,
            mimeType: "video/mp4",
            durationSeconds: 18,
            status: "PENDING",
            createdAt: new Date().toISOString(),
          }]),
        }),
      });

      mockUpdate.mockReturnValue({
        set: vi.fn().mockReturnValue({
          where: vi.fn().mockResolvedValue([{ id: panditId }]),
        }),
      });

      const res = await request(app)
        .post("/api/v1/pandits/me/mantra-recordings")
        .set("Authorization", `Bearer ${panditToken}`)
        .send({
          mantraId: "MAHAMRITYUNJAYA_MANTRA",
          mantraTitle: "Mahamrityunjaya Mantra (महामृत्युंजय मंत्र)",
          fileName: "video_rec_mahamrityunjaya.mp4",
          mimeType: "video/mp4",
          fileDataBase64: validMp4Base64,
          durationSeconds: 18,
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.recording.status).toBe("PENDING");
      expect(res.body.data.recording.mimeType).toBe("video/mp4");
    });
  });

  describe("4. Security, Access Restrictions & State Persistence", () => {
    it("200 – getOnboardingStatus includes mantra verification and recordings list", async () => {
      mockFindFirst.mockResolvedValueOnce({
        id: panditId,
        userId: panditUserId,
        verificationMethod: "MANTRA_RECORDING",
        verificationStatus: "PENDING",
        verificationStage: "MANTRA_RECORDING_UNDER_REVIEW",
        mantraRecordingStatus: "PENDING",
        videoCallStatus: "PENDING",
        isVerified: false,
      });

      mockFindMany.mockResolvedValueOnce([]); // documents
      mockFindMany.mockResolvedValueOnce([{
        id: recordingId,
        panditId,
        mantraId: "MAHAMRITYUNJAYA_MANTRA",
        mantraTitle: "Mahamrityunjaya Mantra",
        status: "PENDING",
        durationSeconds: 18,
        createdAt: new Date().toISOString(),
      }]);

      const res = await request(app)
        .get("/api/v1/pandits/me/onboarding-status")
        .set("Authorization", `Bearer ${panditToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.verificationMethod).toBe("MANTRA_RECORDING");
      expect(res.body.data.mantraVerification.status).toBe("PENDING");
      expect(res.body.data.mantraVerification.latestRecording).toBeDefined();
      expect(res.body.data.mantraVerification.latestRecording.mantraId).toBe("MAHAMRITYUNJAYA_MANTRA");
    });

    it("403 – Yajman cannot access private mantra recordings", async () => {
      const res = await request(app)
        .get("/api/v1/pandits/me/mantra-recordings")
        .set("Authorization", `Bearer ${yajmanToken}`);
      expect(res.status).toBe(403);
    });
  });

  describe("5. Administrator Review Workflow & Premature Approval Safeguard", () => {
    it("403 – Non-admin cannot review mantra recordings", async () => {
      const res = await request(app)
        .patch(`/api/v1/admin/pandits/${panditId}/mantra-recordings/${recordingId}/review`)
        .set("Authorization", `Bearer ${panditToken}`)
        .send({ status: "APPROVED" });
      expect(res.status).toBe(403);
    });

    it("400 – Admin cannot approve a Pandit whose mantra recording is still PENDING", async () => {
      mockFindFirst.mockResolvedValueOnce({
        id: panditId,
        userId: panditUserId,
        verificationMethod: "MANTRA_RECORDING",
        verificationStatus: "PENDING",
        verificationStage: "MANTRA_RECORDING_UNDER_REVIEW",
        mantraRecordingStatus: "PENDING",
      });

      const res = await request(app)
        .patch(`/api/v1/admin/pandits/${panditId}/approval`)
        .set("Authorization", `Bearer ${adminToken}`)
        .send({ status: "APPROVED" });

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe("INVALID_STATE_TRANSITION");
      expect(res.body.error.message).toContain("Mantra Video Recording has been reviewed and approved");
    });

    it("200 – Admin can request resubmission with pronunciation guidance", async () => {
      mockFindFirst.mockResolvedValueOnce({ id: panditId, verificationStage: "MANTRA_RECORDING_UNDER_REVIEW" }); // pandit
      mockFindFirst.mockResolvedValueOnce({ id: recordingId, panditId, status: "PENDING" }); // recording

      mockUpdate.mockReturnValue({
        set: vi.fn().mockReturnValue({
          where: vi.fn().mockImplementation(() => {
            const p: any = Promise.resolve([{ id: recordingId, status: "RESUBMISSION_REQUIRED" }]);
            p.returning = vi.fn().mockResolvedValue([{
              id: recordingId,
              status: "RESUBMISSION_REQUIRED",
              reviewerNotes: "Please enunciate the Visarga at the end of each Pada phrase clearly.",
            }]);
            return p;
          }),
        }),
      });

      const res = await request(app)
        .patch(`/api/v1/admin/pandits/${panditId}/mantra-recordings/${recordingId}/review`)
        .set("Authorization", `Bearer ${adminToken}`)
        .send({
          status: "RESUBMISSION_REQUIRED",
          notes: "Please enunciate the Visarga at the end of each Pada phrase clearly.",
          rejectionReason: "Visarga enunciation unclear.",
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe("RESUBMISSION_REQUIRED");
    });

    it("200 – Admin approves mantra recording, and then authorizes Pandit application", async () => {
      mockFindFirst.mockResolvedValueOnce({ id: panditId, verificationStage: "MANTRA_RECORDING_UNDER_REVIEW" });
      mockFindFirst.mockResolvedValueOnce({ id: recordingId, panditId, status: "PENDING" });

      mockUpdate.mockReturnValue({
        set: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            returning: vi.fn().mockResolvedValue([{
              id: recordingId,
              status: "APPROVED",
              reviewerNotes: "Excellent Vedic Chhanda and accurate Sandhi pronunciation.",
            }]),
          }),
        }),
      });

      // Review recording
      const reviewRes = await request(app)
        .patch(`/api/v1/admin/pandits/${panditId}/mantra-recordings/${recordingId}/review`)
        .set("Authorization", `Bearer ${adminToken}`)
        .send({
          status: "APPROVED",
          notes: "Excellent Vedic Chhanda and accurate Sandhi pronunciation.",
        });

      expect(reviewRes.status).toBe(200);
      expect(reviewRes.body.data.status).toBe("APPROVED");

      // Now approve overall Pandit profile
      mockFindFirst.mockResolvedValueOnce({
        id: panditId,
        userId: panditUserId,
        verificationMethod: "MANTRA_RECORDING",
        verificationStatus: "PENDING",
        verificationStage: "MANTRA_RECORDING_APPROVED",
        mantraRecordingStatus: "APPROVED",
      });

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

      const approveRes = await request(app)
        .patch(`/api/v1/admin/pandits/${panditId}/approval`)
        .set("Authorization", `Bearer ${adminToken}`)
        .send({ status: "APPROVED" });

      expect(approveRes.status).toBe(200);
      expect(approveRes.body.data.verificationStatus).toBe("APPROVED");
      expect(approveRes.body.data.isVerified).toBe(true);
    });
  });

  describe("6. Admin Portal: Approved Mantras Management", () => {
    it("403 – Non-admin cannot manage approved mantras", async () => {
      const res = await request(app)
        .get("/api/v1/admin/mantras")
        .set("Authorization", `Bearer ${panditToken}`);
      expect(res.status).toBe(403);
    });

    it("200 – Admin can list all approved mantras including inactive ones", async () => {
      mockFindMany.mockResolvedValueOnce([
        {
          id: "GAYATRI_MANTRA",
          title: "Gayatri Mahamantra",
          sanskritText: "ॐ भूर्भुवः स्वः",
          isActive: true,
          displayOrder: 1,
        },
        {
          id: "CUSTOM_MANTRA",
          title: "Custom Vedic Recitation",
          sanskritText: "ॐ नमो भगवते वासुदेवाय",
          isActive: false,
          displayOrder: 2,
        },
      ]);

      const res = await request(app)
        .get("/api/v1/admin/mantras")
        .set("Authorization", `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBe(2);
    });

    it("201 – Admin can create a new approved mantra", async () => {
      const newMantra = {
        title: "Navagraha Shanti Mantra (नवग्रह शांति मंत्र)",
        sanskritText: "ॐ ब्रह्मा मुरारिस्त्रिपुरान्तकारी भानुः शशी भूमिसुतो बुधश्च।",
        transliteration: "Om Brahma Muraris-Tripurantakari Bhanuh Shashi Bhumisuto Budhashcha...",
        pronunciationGuidance: "Recite with calm rhythmic cadence dedicating each pada to the corresponding planetary deity.",
        minDurationSeconds: 15,
        maxDurationSeconds: 180,
      };

      mockInsert.mockReturnValue({
        values: vi.fn().mockReturnValue({
          returning: vi.fn().mockResolvedValue([{
            id: "NAVAGRAHA_SHANTI_MANTRA",
            ...newMantra,
            isActive: true,
            displayOrder: 10,
            createdAt: new Date().toISOString(),
          }]),
        }),
      });

      const res = await request(app)
        .post("/api/v1/admin/mantras")
        .set("Authorization", `Bearer ${adminToken}`)
        .send(newMantra);

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.title).toBe(newMantra.title);
      expect(res.body.data.isActive).toBe(true);
    });

    it("200 – Admin can update an existing mantra's guidance and status", async () => {
      mockFindFirst.mockResolvedValueOnce({
        id: "GAYATRI_MANTRA",
        title: "Gayatri Mahamantra",
        isActive: true,
      });

      mockUpdate.mockReturnValue({
        set: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            returning: vi.fn().mockResolvedValue([{
              id: "GAYATRI_MANTRA",
              title: "Gayatri Mahamantra (गायत्री महामंत्र) - Updated",
              pronunciationGuidance: "Ensure clear pronunciation of Savitur and Varenyam.",
              isActive: true,
              updatedAt: new Date().toISOString(),
            }]),
          }),
        }),
      });

      const res = await request(app)
        .patch("/api/v1/admin/mantras/GAYATRI_MANTRA")
        .set("Authorization", `Bearer ${adminToken}`)
        .send({
          title: "Gayatri Mahamantra (गायत्री महामंत्र) - Updated",
          pronunciationGuidance: "Ensure clear pronunciation of Savitur and Varenyam.",
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.pronunciationGuidance).toContain("Savitur");
    });

    it("200 – Admin can deactivate an approved mantra", async () => {
      mockFindFirst.mockResolvedValueOnce({
        id: "MAHAMRITYUNJAYA_MANTRA",
        isActive: true,
      });

      mockUpdate.mockReturnValue({
        set: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            returning: vi.fn().mockResolvedValue([{
              id: "MAHAMRITYUNJAYA_MANTRA",
              isActive: false,
            }]),
          }),
        }),
      });

      const res = await request(app)
        .delete("/api/v1/admin/mantras/MAHAMRITYUNJAYA_MANTRA")
        .set("Authorization", `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.success).toBe(true);
      expect(res.body.data.id).toBe("MAHAMRITYUNJAYA_MANTRA");
    });
  });
});
