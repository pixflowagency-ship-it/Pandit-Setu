import crypto from "crypto";
import { eq, and, desc, count } from "drizzle-orm";
import { db } from "../db/index.js";
import { consultations, type Consultation } from "../db/schema/consultations.js";
import { users } from "../db/schema/users.js";
import { pandits } from "../db/schema/pandits.js";
import { AppError } from "../utils/api-error.js";
import { logger } from "../utils/logger.js";
import { getRazorpayInstance } from "./payments.service.js";
import { getIO } from "./realtime.service.js";

export function calculateConsultationFee(
  type: "ONLINE" | "OFFLINE",
  durationMinutes: number
): number {
  if (type === "ONLINE") {
    if (durationMinutes === 15) return 199;
    if (durationMinutes === 30) return 349;
    return 599; // 60 mins
  } else {
    if (durationMinutes === 15) return 299;
    if (durationMinutes === 30) return 499;
    return 899; // 60 mins
  }
}

export function generateConsultationNumber(): string {
  const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, "");
  const randomSuffix = crypto.randomBytes(3).toString("hex").toUpperCase();
  return `CNS-${dateStr}-${randomSuffix}`;
}

export async function createConsultation(
  userId: string,
  data: {
    type: "ONLINE" | "OFFLINE";
    timing: "IMMEDIATE" | "SCHEDULED";
    medium: "PHONE" | "VIDEO" | "IN_PERSON";
    topic: string;
    durationMinutes: number;
    devoteeName: string;
    devoteePhone: string;
    requestedDate?: string | null;
    requestedTimeSlot?: string | null;
    venueAddress?: string | null;
    kendraName?: string | null;
    notes?: string | null;
  }
) {
  const user = await db.query.users.findFirst({
    where: eq(users.id, userId),
  });

  if (!user) {
    throw new AppError(404, "NOT_FOUND", "User identity not found");
  }

  const amount = calculateConsultationFee(data.type, data.durationMinutes);
  const consultationNumber = generateConsultationNumber();

  const [created] = await db
    .insert(consultations)
    .values({
      consultationNumber,
      userId,
      type: data.type,
      timing: data.timing,
      medium: data.medium,
      topic: data.topic,
      durationMinutes: data.durationMinutes,
      amount: amount.toFixed(2),
      currency: "INR",
      status: "REQUESTED",
      paymentStatus: "PENDING",
      devoteeName: data.devoteeName,
      devoteePhone: data.devoteePhone,
      requestedDate: data.requestedDate ? new Date(data.requestedDate) : null,
      requestedTimeSlot: data.requestedTimeSlot || null,
      venueAddress: data.venueAddress || null,
      kendraName: data.kendraName || null,
      notes: data.notes || null,
    })
    .returning();

  logger.info(
    { consultationId: created.id, consultationNumber, userId },
    "Vedic consultation request created and persisted"
  );

  // Safe realtime notification
  try {
    const io = getIO();
    io.to(`user:${userId}`).emit("consultation:created", {
      consultationId: created.id,
      consultationNumber,
      status: created.status,
    });
    io.to("admin:operations").emit("admin:consultation:new", {
      consultationId: created.id,
      consultationNumber,
      type: created.type,
      topic: created.topic,
    });
  } catch (_e) {
    // Non-fatal if socket not active
  }

  return created;
}

export async function getUserConsultations(
  userId: string,
  params: { page?: number; limit?: number }
) {
  const page = params.page && params.page > 0 ? params.page : 1;
  const limit = params.limit && params.limit > 0 ? params.limit : 20;
  const offset = (page - 1) * limit;

  const [totalRes, rows] = await Promise.all([
    db
      .select({ count: count() })
      .from(consultations)
      .where(eq(consultations.userId, userId)),
    db.query.consultations.findMany({
      where: eq(consultations.userId, userId),
      with: {
        assignedPandit: {
          with: {
            user: {
              columns: {
                id: true,
                name: true,
                phone: true,
              },
            },
          },
        },
      },
      orderBy: [desc(consultations.createdAt)],
      limit,
      offset,
    }),
  ]);

  const total = totalRes[0]?.count ?? 0;

  return {
    items: rows,
    pagination: {
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit) || 1,
    },
  };
}

export async function getConsultationById(
  userId: string,
  userRole: string,
  consultationId: string
) {
  const consultation = await db.query.consultations.findFirst({
    where: eq(consultations.id, consultationId),
    with: {
      user: {
        columns: {
          id: true,
          name: true,
          phone: true,
          email: true,
          city: true,
        },
      },
      assignedPandit: {
        with: {
          user: {
            columns: {
              id: true,
              name: true,
              phone: true,
            },
          },
        },
      },
    },
  });

  if (!consultation) {
    throw new AppError(404, "NOT_FOUND", "Consultation record not found");
  }

  // Enforce access control
  const isOwner = consultation.userId === userId;
  const isAdmin = userRole === "ADMIN";

  if (!isOwner && !isAdmin) {
    // If user is a Pandit, check assignment
    if (userRole === "PANDIT") {
      const pandit = await db.query.pandits.findFirst({
        where: eq(pandits.userId, userId),
      });
      if (!pandit || consultation.assignedPanditId !== pandit.id) {
        throw new AppError(403, "FORBIDDEN", "Access denied to this consultation");
      }
    } else {
      throw new AppError(403, "FORBIDDEN", "Access denied to this consultation");
    }
  }

  return consultation;
}

export async function cancelConsultation(
  userId: string,
  consultationId: string,
  cancellationReason: string
) {
  const consultation = await db.query.consultations.findFirst({
    where: and(eq(consultations.id, consultationId), eq(consultations.userId, userId)),
  });

  if (!consultation) {
    throw new AppError(404, "NOT_FOUND", "Consultation not found or access denied");
  }

  if (["COMPLETED", "CANCELLED", "REJECTED"].includes(consultation.status)) {
    throw new AppError(
      400,
      "INVALID_STATE_TRANSITION",
      `Cannot cancel consultation in ${consultation.status} state`
    );
  }

  const [updated] = await db
    .update(consultations)
    .set({
      status: "CANCELLED",
      cancellationReason,
      updatedAt: new Date(),
    })
    .where(eq(consultations.id, consultationId))
    .returning();

  logger.info({ consultationId, userId }, "Consultation cancelled by devotee");

  try {
    const io = getIO();
    io.to(`user:${userId}`).emit("consultation:status-change", {
      consultationId,
      status: "CANCELLED",
      cancellationReason,
    });
  } catch (_e) {}

  return updated;
}

export async function adminGetConsultations(params: {
  type?: "ONLINE" | "OFFLINE" | "ALL";
  status?: string;
  page?: number;
  limit?: number;
}) {
  const page = params.page && params.page > 0 ? params.page : 1;
  const limit = params.limit && params.limit > 0 ? params.limit : 20;
  const offset = (page - 1) * limit;

  const conditions = [];
  if (params.type && params.type !== "ALL") {
    conditions.push(eq(consultations.type, params.type));
  }
  if (params.status && params.status !== "ALL") {
    conditions.push(eq(consultations.status, params.status as any));
  }

  const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

  const [totalRes, rows] = await Promise.all([
    db
      .select({ count: count() })
      .from(consultations)
      .where(whereClause),
    db.query.consultations.findMany({
      where: whereClause,
      with: {
        user: {
          columns: {
            id: true,
            name: true,
            phone: true,
            city: true,
          },
        },
        assignedPandit: {
          with: {
            user: {
              columns: {
                id: true,
                name: true,
                phone: true,
              },
            },
          },
        },
      },
      orderBy: [desc(consultations.createdAt)],
      limit,
      offset,
    }),
  ]);

  const total = totalRes[0]?.count ?? 0;

  return {
    items: rows,
    pagination: {
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit) || 1,
    },
  };
}

export async function adminScheduleConsultation(
  reviewerId: string,
  consultationId: string,
  scheduledDateTime: string,
  notes?: string | null
) {
  const consultation = await db.query.consultations.findFirst({
    where: eq(consultations.id, consultationId),
  });

  if (!consultation) {
    throw new AppError(404, "NOT_FOUND", "Consultation not found");
  }

  const [updated] = await db
    .update(consultations)
    .set({
      scheduledDateTime: new Date(scheduledDateTime),
      status: "SCHEDULED",
      notes: notes || consultation.notes,
      updatedAt: new Date(),
    })
    .where(eq(consultations.id, consultationId))
    .returning();

  logger.info({ consultationId, reviewerId }, "Consultation scheduled by admin");

  try {
    const io = getIO();
    io.to(`user:${consultation.userId}`).emit("consultation:status-change", {
      consultationId,
      status: "SCHEDULED",
      scheduledDateTime,
    });
  } catch (_e) {}

  return updated;
}

export async function adminAssignPandit(
  reviewerId: string,
  consultationId: string,
  panditId: string
) {
  const [consultation, pandit] = await Promise.all([
    db.query.consultations.findFirst({
      where: eq(consultations.id, consultationId),
    }),
    db.query.pandits.findFirst({
      where: eq(pandits.id, panditId),
      with: {
        user: true,
      },
    }),
  ]);

  if (!consultation) {
    throw new AppError(404, "NOT_FOUND", "Consultation not found");
  }

  if (!pandit) {
    throw new AppError(404, "NOT_FOUND", "Pandit not found");
  }

  // Ensure Pandit is approved and verified
  if (!pandit.isVerified || pandit.verificationStatus !== "APPROVED") {
    throw new AppError(
      400,
      "INVALID_PANDIT_STATE",
      "Only verified and approved Acharyas can be assigned to consultations"
    );
  }

  const [updated] = await db
    .update(consultations)
    .set({
      assignedPanditId: panditId,
      status: consultation.status === "REQUESTED" ? "CONFIRMED" : consultation.status,
      updatedAt: new Date(),
    })
    .where(eq(consultations.id, consultationId))
    .returning();

  logger.info({ consultationId, panditId, reviewerId }, "Pandit assigned to consultation");

  try {
    const io = getIO();
    io.to(`user:${consultation.userId}`).emit("consultation:status-change", {
      consultationId,
      status: updated.status,
      assignedPandit: {
        id: pandit.id,
        name: pandit.user?.name || "Verified Acharya",
      },
    });
  } catch (_e) {}

  return updated;
}

export async function adminUpdateConsultationStatus(
  reviewerId: string,
  consultationId: string,
  status:
    | "REQUESTED"
    | "UNDER_REVIEW"
    | "SCHEDULED"
    | "CONFIRMED"
    | "IN_PROGRESS"
    | "COMPLETED"
    | "CANCELLED"
    | "REJECTED",
  reason?: string | null
) {
  const consultation = await db.query.consultations.findFirst({
    where: eq(consultations.id, consultationId),
  });

  if (!consultation) {
    throw new AppError(404, "NOT_FOUND", "Consultation not found");
  }

  const VALID_CONSULTATION_TRANSITIONS: Record<string, string[]> = {
    REQUESTED: ["UNDER_REVIEW", "SCHEDULED", "CANCELLED", "REJECTED"],
    UNDER_REVIEW: ["SCHEDULED", "CONFIRMED", "CANCELLED", "REJECTED"],
    SCHEDULED: ["CONFIRMED", "IN_PROGRESS", "CANCELLED"],
    CONFIRMED: ["IN_PROGRESS", "CANCELLED", "COMPLETED"],
    IN_PROGRESS: ["COMPLETED", "CANCELLED"],
    COMPLETED: [],
    CANCELLED: [],
    REJECTED: [],
  };

  const allowedNext = VALID_CONSULTATION_TRANSITIONS[consultation.status] || [];
  if (!allowedNext.includes(status)) {
    throw new AppError(
      400,
      "INVALID_TRANSITION",
      `Invalid status transition: Cannot transition consultation from ${consultation.status} to ${status}`
    );
  }

  const updateData: Partial<Consultation> = {
    status,
    updatedAt: new Date(),
  };

  if (status === "REJECTED") {
    updateData.rejectionReason = reason || "Application requirements not fulfilled";
  } else if (status === "CANCELLED") {
    updateData.cancellationReason = reason || "Cancelled by desk administration";
  }

  const [updated] = await db
    .update(consultations)
    .set(updateData)
    .where(eq(consultations.id, consultationId))
    .returning();

  logger.info({ consultationId, status, reviewerId }, "Consultation status updated by admin");

  try {
    const io = getIO();
    io.to(`user:${consultation.userId}`).emit("consultation:status-change", {
      consultationId,
      status,
      reason,
    });
  } catch (_e) {}

  return updated;
}

export async function createConsultationPaymentOrder(
  userId: string,
  consultationId: string
) {
  const consultation = await db.query.consultations.findFirst({
    where: and(eq(consultations.id, consultationId), eq(consultations.userId, userId)),
  });

  if (!consultation) {
    throw new AppError(404, "NOT_FOUND", "Consultation not found");
  }

  if (consultation.paymentStatus === "PAID") {
    throw new AppError(400, "ALREADY_PAID", "Consultation has already been paid for");
  }

  if (consultation.razorpayOrderId) {
    return {
      orderId: consultation.razorpayOrderId,
      amount: Math.round(parseFloat(consultation.amount.toString()) * 100),
      currency: "INR",
      consultationNumber: consultation.consultationNumber,
    };
  }

  const razorpay = getRazorpayInstance();
  const amountInPaise = Math.round(parseFloat(consultation.amount.toString()) * 100);

  const order = await razorpay.orders.create({
    amount: amountInPaise,
    currency: "INR",
    receipt: consultation.consultationNumber || consultation.id,
    notes: {
      consultationId: consultation.id,
      topic: (consultation.topic || "Consultation").slice(0, 40),
    },
  });

  await db
    .update(consultations)
    .set({
      razorpayOrderId: order.id,
      updatedAt: new Date(),
    })
    .where(eq(consultations.id, consultation.id));

  return {
    orderId: order.id,
    amount: amountInPaise,
    currency: "INR",
    consultationNumber: consultation.consultationNumber,
  };
}

export async function verifyConsultationPayment(
  userId: string,
  consultationId: string,
  paymentData: {
    razorpayOrderId: string;
    razorpayPaymentId: string;
    razorpaySignature: string;
  }
) {
  const { razorpayOrderId, razorpayPaymentId, razorpaySignature } = paymentData;
  const secret = process.env.RAZORPAY_KEY_SECRET;
  if (!secret) {
    throw new AppError(500, "CONFIGURATION_ERROR", "Razorpay key secret not configured");
  }

  const generatedSignature = crypto
    .createHmac("sha256", secret)
    .update(`${razorpayOrderId}|${razorpayPaymentId}`)
    .digest("hex");

  const generatedBuffer = Buffer.from(generatedSignature, "utf-8");
  const providedBuffer = Buffer.from(razorpaySignature, "utf-8");

  let isSignatureValid = false;
  if (generatedBuffer.length === providedBuffer.length) {
    isSignatureValid = crypto.timingSafeEqual(generatedBuffer, providedBuffer);
  }

  if (!isSignatureValid) {
    throw new AppError(400, "BAD_REQUEST", "Invalid payment signature");
  }

  const consultation = await db.query.consultations.findFirst({
    where: and(eq(consultations.id, consultationId), eq(consultations.userId, userId)),
  });

  if (!consultation) {
    throw new AppError(404, "NOT_FOUND", "Consultation not found");
  }

  // Idempotency: Return existing if already marked paid
  if (consultation.paymentStatus === "PAID") {
    return consultation;
  }

  const [updated] = await db
    .update(consultations)
    .set({
      paymentStatus: "PAID",
      razorpayPaymentId,
      razorpaySignature,
      paidAt: new Date(),
      status: consultation.status === "REQUESTED" ? "CONFIRMED" : consultation.status,
      updatedAt: new Date(),
    })
    .where(eq(consultations.id, consultation.id))
    .returning();

  logger.info({ consultationId, razorpayPaymentId }, "Consultation payment verified successfully");

  return updated;
}
