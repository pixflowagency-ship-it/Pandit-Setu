import { z } from "zod";

export const nearbyQuerySchema = z
  .object({
    lat: z.coerce.number().min(-90).max(90),
    lng: z.coerce.number().min(-180).max(180),
    radiusKm: z.coerce.number().min(1).max(100).optional().default(15),
  })
  .strict();

export type NearbyQuery = z.infer<typeof nearbyQuerySchema>;

export const dutyStatusSchema = z
  .object({
    isAvailable: z.boolean(),
    lat: z.number().min(-90, "Latitude must be between -90 and 90").max(90, "Latitude must be between -90 and 90").optional(),
    lng: z.number().min(-180, "Longitude must be between -180 and 180").max(180, "Longitude must be between -180 and 180").optional(),
  })
  .strict()
  .refine(
    (data) => (data.lat === undefined && data.lng === undefined) || (data.lat !== undefined && data.lng !== undefined),
    {
      message: "Both lat and lng must be provided together",
      path: ["lat"],
    }
  );

export type DutyStatusInput = z.infer<typeof dutyStatusSchema>;

export const acceptBookingSchema = z
  .object({
    bookingId: z.string().uuid("bookingId must be a valid UUID"),
  })
  .strict();

export type AcceptBookingInput = z.infer<typeof acceptBookingSchema>;

export const declineBookingSchema = z
  .object({
    bookingId: z.string().uuid("bookingId must be a valid UUID"),
    reason: z.enum(["TOO_FAR", "BUSY", "SCHEDULE_CONFLICT", "OTHER"]).optional().default("OTHER"),
    notes: z.string().max(500, "Notes cannot exceed 500 characters").optional(),
  })
  .strict();

export type DeclineBookingInput = z.infer<typeof declineBookingSchema>;

export const updatePanditProfileSchema = z
  .object({
    experienceYears: z.number().int().min(0).max(70).optional(),
    vedicSpecialization: z.string().min(2).max(255).optional(),
    languages: z.array(z.string()).min(1).optional(),
    bio: z.string().max(2000).optional(),
    serviceRadiusKm: z.number().int().min(1).max(100).optional(),
    latitude: z.number().min(-90).max(90).optional(),
    longitude: z.number().min(-180).max(180).optional(),
  })
  .strict();

export const uploadDocumentSchema = z
  .object({
    docType: z.enum(["AADHAAR", "PAN", "DEGREE_CERTIFICATE", "OTHER"]),
    fileName: z.string().min(1).max(255),
    mimeType: z.string().min(3).max(100),
    fileDataBase64: z.string().min(10),
    docNumber: z.string().max(100).optional(),
  })
  .strict();

export const scheduleVideoVerificationSchema = z
  .object({
    scheduledAt: z.string().datetime(),
    preferredLanguage: z.string().optional(),
  })
  .strict();

export const adminVerifyDocumentSchema = z
  .object({
    status: z.enum(["VERIFIED", "REJECTED"]),
    rejectionReason: z.string().max(500).optional(),
  })
  .strict();

export const adminVerifyVideoSchema = z
  .object({
    status: z.enum(["COMPLETED", "MISSED"]),
    notes: z.string().max(1000).optional(),
  })
  .strict();

export const adminApprovePanditSchema = z
  .object({
    status: z.enum(["APPROVED", "REJECTED"]),
    rejectionReason: z.string().max(1000).optional(),
  })
  .strict();

export const setVerificationMethodSchema = z
  .object({
    method: z.enum(["MANTRA_VIDEO", "MANTRA_RECORDING", "VIDEO_CALL"]),
  })
  .strict();

export type SetVerificationMethodInput = z.infer<typeof setVerificationMethodSchema>;

export const uploadMantraRecordingSchema = z
  .object({
    mantraId: z.string().min(1).max(64),
    mantraTitle: z.string().min(1).max(255),
    fileName: z.string().min(1).max(255),
    mimeType: z.string().min(3).max(100),
    fileDataBase64: z.string().min(10),
    durationSeconds: z.number().int().min(1).max(600).optional().default(0),
  })
  .strict();

export type UploadMantraRecordingInput = z.infer<typeof uploadMantraRecordingSchema>;

export const adminReviewMantraRecordingSchema = z
  .object({
    status: z.enum(["APPROVED", "REJECTED", "RESUBMISSION_REQUIRED"]),
    notes: z.string().max(1000).optional(),
    rejectionReason: z.string().max(1000).optional(),
  })
  .strict();

export type AdminReviewMantraRecordingInput = z.infer<typeof adminReviewMantraRecordingSchema>;

export const createMantraSchema = z
  .object({
    id: z.string().min(2).max(64).optional(),
    title: z.string().min(3).max(255),
    sanskritText: z.string().min(5),
    transliteration: z.string().optional(),
    meaning: z.string().optional(),
    pronunciationGuidance: z.string().optional(),
    minDurationSeconds: z.number().int().min(5).max(180).optional().default(10),
    maxDurationSeconds: z.number().int().min(15).max(300).optional().default(120),
    isActive: z.boolean().optional().default(true),
    displayOrder: z.number().int().optional().default(0),
  })
  .strict();

export type CreateMantraInput = z.infer<typeof createMantraSchema>;

export const updateMantraSchema = createMantraSchema.partial();
export type UpdateMantraInput = z.infer<typeof updateMantraSchema>;


