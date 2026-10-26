import { eq, desc, count, inArray, ilike, or, and } from "drizzle-orm";
import { db } from "../db/index.js";
import { pandits, panditDocuments, panditMantraRecordings } from "../db/schema/pandits.js";
import { users } from "../db/schema/users.js";
import { bookings } from "../db/schema/bookings.js";
import { poojas } from "../db/schema/poojas.js";
import { subscriptions } from "../db/schema/subscriptions.js";
import { productOrders } from "../db/schema/product_orders.js";
import { AppError } from "../utils/api-error.js";
import { logger } from "../utils/logger.js";
import {
  adminApprovePandit,
  adminVerifyDocument,
  adminVerifyVideo,
  adminReviewMantraRecording,
  getPanditDocumentStream,
  getPanditMantraStream,
  getAllMantrasAdmin,
  adminCreateMantra,
  adminUpdateMantra,
  adminDeleteMantra,
} from "./pandit-verification.service.js";

import { consultations } from "../db/schema/consultations.js";
import { kundliOrders } from "../db/schema/kundli_orders.js";

export async function getAdminStats() {
  const [
    pendingPanditsRes,
    approvedPanditsRes,
    rejectedPanditsRes,
    totalPanditsRes,
    totalBookingsRes,
    totalSubscriptionsRes,
    activeSubscriptionsRes,
    totalProductOrdersRes,
    totalConsultationsRes,
    pendingConsultationsRes,
    totalKundliOrdersRes,
    pendingKundliOrdersRes,
  ] = await Promise.all([
    db.select({ count: count() }).from(pandits).where(eq(pandits.verificationStatus, "PENDING")),
    db.select({ count: count() }).from(pandits).where(eq(pandits.verificationStatus, "APPROVED")),
    db.select({ count: count() }).from(pandits).where(eq(pandits.verificationStatus, "REJECTED")),
    db.select({ count: count() }).from(pandits),
    db.select({ count: count() }).from(bookings),
    db.select({ count: count() }).from(subscriptions),
    db.select({ count: count() }).from(subscriptions).where(eq(subscriptions.status, "ACTIVE")),
    db.select({ count: count() }).from(productOrders),
    db.select({ count: count() }).from(consultations),
    db.select({ count: count() }).from(consultations).where(eq(consultations.status, "REQUESTED")),
    db.select({ count: count() }).from(kundliOrders),
    db.select({ count: count() }).from(kundliOrders).where(eq(kundliOrders.status, "REQUESTED")),
  ]);

  return {
    pandits: {
      pending: Array.isArray(pendingPanditsRes) ? (pendingPanditsRes[0]?.count ?? 0) : 0,
      approved: Array.isArray(approvedPanditsRes) ? (approvedPanditsRes[0]?.count ?? 0) : 0,
      rejected: Array.isArray(rejectedPanditsRes) ? (rejectedPanditsRes[0]?.count ?? 0) : 0,
      total: Array.isArray(totalPanditsRes) ? (totalPanditsRes[0]?.count ?? 0) : 0,
    },
    bookings: {
      total: Array.isArray(totalBookingsRes) ? (totalBookingsRes[0]?.count ?? 0) : 0,
    },
    subscriptions: {
      total: Array.isArray(totalSubscriptionsRes) ? (totalSubscriptionsRes[0]?.count ?? 0) : 0,
      active: Array.isArray(activeSubscriptionsRes) ? (activeSubscriptionsRes[0]?.count ?? 0) : 0,
    },
    productOrders: {
      total: Array.isArray(totalProductOrdersRes) ? (totalProductOrdersRes[0]?.count ?? 0) : 0,
    },
    consultations: {
      total: Array.isArray(totalConsultationsRes) ? (totalConsultationsRes[0]?.count ?? 0) : 0,
      pending: Array.isArray(pendingConsultationsRes) ? (pendingConsultationsRes[0]?.count ?? 0) : 0,
      persistentRecords: true,
    },
    kundliOrders: {
      total: Array.isArray(totalKundliOrdersRes) ? (totalKundliOrdersRes[0]?.count ?? 0) : 0,
      pending: Array.isArray(pendingKundliOrdersRes) ? (pendingKundliOrdersRes[0]?.count ?? 0) : 0,
      persistentRecords: true,
    },
  };
}

export async function getAdminPanditApplications(params: {
  status?: "PENDING" | "APPROVED" | "REJECTED" | "ALL";
  page: number;
  limit: number;
}) {
  const { status = "ALL", page = 1, limit = 20 } = params;
  const offset = (page - 1) * limit;

  const whereClause =
    status && status !== "ALL" ? eq(pandits.verificationStatus, status) : undefined;

  const [totalRes, rows] = await Promise.all([
    db
      .select({ count: count() })
      .from(pandits)
      .where(whereClause),
    db
      .select({
        pandit: pandits,
        userName: users.name,
        userPhone: users.phone,
        userEmail: users.email,
        userCity: users.city,
      })
      .from(pandits)
      .leftJoin(users, eq(pandits.userId, users.id))
      .where(whereClause)
      .orderBy(desc(pandits.createdAt))
      .limit(limit)
      .offset(offset),
  ]);

  const total = totalRes[0]?.count ?? 0;
  const panditIds = rows.map((r) => r.pandit.id);

  let docsByPandit: Record<string, any[]> = {};
  let mantraRecsByPandit: Record<string, any[]> = {};

  if (panditIds.length > 0) {
    const [docs, recs] = await Promise.all([
      db.query.panditDocuments.findMany({
        where: inArray(panditDocuments.panditId, panditIds),
        orderBy: (docs, { desc }) => [desc(docs.createdAt)],
      }),
      db.query.panditMantraRecordings.findMany({
        where: inArray(panditMantraRecordings.panditId, panditIds),
        orderBy: (r, { desc }) => [desc(r.createdAt)],
      }),
    ]);

    for (const d of docs) {
      if (!docsByPandit[d.panditId]) {
        docsByPandit[d.panditId] = [];
      }
      docsByPandit[d.panditId].push({
        id: d.id,
        docType: d.docType,
        fileName: d.fileName || `${d.docType.toLowerCase()}.pdf`,
        fileSize: d.fileSize,
        mimeType: d.mimeType,
        docNumber: d.docNumber ? `•••• ${d.docNumber.slice(-4)}` : null,
        status: d.status,
        rejectionReason: d.rejectionReason,
        createdAt: d.createdAt,
      });
    }

    for (const r of recs) {
      if (!mantraRecsByPandit[r.panditId]) {
        mantraRecsByPandit[r.panditId] = [];
      }
      mantraRecsByPandit[r.panditId].push({
        id: r.id,
        mantraId: r.mantraId,
        mantraTitle: r.mantraTitle,
        durationSeconds: r.durationSeconds,
        fileName: r.fileName,
        fileSize: r.fileSize,
        mimeType: r.mimeType,
        status: r.status,
        rejectionReason: r.rejectionReason,
        reviewerNotes: r.reviewerNotes,
        reviewedAt: r.reviewedAt,
        createdAt: r.createdAt,
      });
    }
  }

  const items = rows.map((r) => ({
    id: r.pandit.id,
    userId: r.pandit.userId,
    userName: r.userName || "Unnamed Pandit",
    userPhone: r.userPhone,
    userEmail: r.userEmail,
    userCity: r.userCity,
    experienceYears: r.pandit.experienceYears,
    vedicSpecialization: r.pandit.vedicSpecialization,
    languages: r.pandit.languages || [],
    bio: r.pandit.bio,
    verificationMethod: r.pandit.verificationMethod || "VIDEO_CALL",
    verificationStatus: r.pandit.verificationStatus,
    verificationStage: r.pandit.verificationStage,
    mantraRecordingStatus: r.pandit.mantraRecordingStatus || "NOT_SUBMITTED",
    isVerified: r.pandit.isVerified,
    rejectionReason: r.pandit.rejectionReason,
    videoCallStatus: r.pandit.videoCallStatus,
    videoScheduledAt: r.pandit.videoScheduledAt,
    videoCallRoomId: r.pandit.videoCallRoomId,
    videoVerifierNotes: r.pandit.videoVerifierNotes,
    approvedAt: r.pandit.approvedAt,
    serviceRadiusKm: r.pandit.serviceRadiusKm,
    rating: r.pandit.rating,
    createdAt: r.pandit.createdAt,
    updatedAt: r.pandit.updatedAt,
    documents: docsByPandit[r.pandit.id] || [],
    mantraRecordings: mantraRecsByPandit[r.pandit.id] || [],
  }));

  return {
    items,
    pagination: {
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit) || 1,
    },
  };
}

export async function getAdminPanditDetail(panditId: string) {
  const pandit = await db.query.pandits.findFirst({
    where: eq(pandits.id, panditId),
  });

  if (!pandit) {
    throw new AppError(404, "NOT_FOUND", "Pandit application not found");
  }

  const user = await db.query.users.findFirst({
    where: eq(users.id, pandit.userId),
  });

  const docs = await db.query.panditDocuments.findMany({
    where: eq(panditDocuments.panditId, pandit.id),
    orderBy: (docs, { desc }) => [desc(docs.createdAt)],
  });

  const mantraRecordings = await db.query.panditMantraRecordings.findMany({
    where: eq(panditMantraRecordings.panditId, pandit.id),
    orderBy: (r, { desc }) => [desc(r.createdAt)],
  });

  return {
    id: pandit.id,
    userId: pandit.userId,
    user: user
      ? {
          id: user.id,
          name: user.name,
          phone: user.phone,
          email: user.email,
          city: user.city,
        }
      : null,
    experienceYears: pandit.experienceYears,
    vedicSpecialization: pandit.vedicSpecialization,
    languages: pandit.languages || [],
    bio: pandit.bio,
    verificationMethod: pandit.verificationMethod || "VIDEO_CALL",
    verificationStatus: pandit.verificationStatus,
    verificationStage: pandit.verificationStage,
    mantraRecordingStatus: pandit.mantraRecordingStatus || "NOT_SUBMITTED",
    isVerified: pandit.isVerified,
    rejectionReason: pandit.rejectionReason,
    videoCallStatus: pandit.videoCallStatus,
    videoScheduledAt: pandit.videoScheduledAt,
    videoCallRoomId: pandit.videoCallRoomId,
    videoVerifierNotes: pandit.videoVerifierNotes,
    approvedAt: pandit.approvedAt,
    serviceRadiusKm: pandit.serviceRadiusKm,
    rating: pandit.rating,
    createdAt: pandit.createdAt,
    updatedAt: pandit.updatedAt,
    documents: docs.map((d) => ({
      id: d.id,
      docType: d.docType,
      fileName: d.fileName || `${d.docType.toLowerCase()}.pdf`,
      fileSize: d.fileSize,
      mimeType: d.mimeType,
      docNumber: d.docNumber ? `•••• ${d.docNumber.slice(-4)}` : null,
      status: d.status,
      rejectionReason: d.rejectionReason,
      createdAt: d.createdAt,
    })),
    mantraRecordings: mantraRecordings.map((r) => ({
      id: r.id,
      mantraId: r.mantraId,
      mantraTitle: r.mantraTitle,
      durationSeconds: r.durationSeconds,
      fileName: r.fileName,
      fileSize: r.fileSize,
      mimeType: r.mimeType,
      status: r.status,
      rejectionReason: r.rejectionReason,
      reviewerNotes: r.reviewerNotes,
      reviewedAt: r.reviewedAt,
      createdAt: r.createdAt,
    })),
  };
}

export async function getAdminSubscriptions(params: {
  status?: string;
  page: number;
  limit: number;
}) {
  const { status = "ALL", page = 1, limit = 20 } = params;
  const offset = (page - 1) * limit;

  const whereClause =
    status && status !== "ALL"
      ? eq(subscriptions.status, status as any)
      : undefined;

  const [totalRes, rows] = await Promise.all([
    db
      .select({ count: count() })
      .from(subscriptions)
      .where(whereClause),
    db
      .select({
        id: subscriptions.id,
        userId: subscriptions.userId,
        userName: users.name,
        userPhone: users.phone,
        userEmail: users.email,
        razorpaySubscriptionId: subscriptions.razorpaySubscriptionId,
        planId: subscriptions.planId,
        status: subscriptions.status,
        currentPeriodEnd: subscriptions.currentPeriodEnd,
        createdAt: subscriptions.createdAt,
        updatedAt: subscriptions.updatedAt,
      })
      .from(subscriptions)
      .leftJoin(users, eq(subscriptions.userId, users.id))
      .where(whereClause)
      .orderBy(desc(subscriptions.createdAt))
      .limit(limit)
      .offset(offset),
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

/**
 * Admin: List users with role filter and search
 */
export async function getAdminUsers(params: {
  search?: string;
  role?: "YAJMAN" | "PANDIT" | "ADMIN" | "ALL";
  page: number;
  limit: number;
}) {
  const { search, role = "ALL", page = 1, limit = 20 } = params;
  const offset = (page - 1) * limit;

  const conditions = [];

  if (role && role !== "ALL") {
    conditions.push(eq(users.role, role as any));
  }

  if (search && search.trim()) {
    const term = `%${search.trim()}%`;
    conditions.push(
      or(ilike(users.name, term), ilike(users.phone, term), ilike(users.email, term))
    );
  }

  const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

  const [totalRes, rows] = await Promise.all([
    db.select({ count: count() }).from(users).where(whereClause),
    db
      .select({
        id: users.id,
        name: users.name,
        phone: users.phone,
        email: users.email,
        city: users.city,
        address: users.address,
        role: users.role,
        createdAt: users.createdAt,
      })
      .from(users)
      .where(whereClause)
      .orderBy(desc(users.createdAt))
      .limit(limit)
      .offset(offset),
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

/**
 * Admin: Get detailed user profile with activity
 */
export async function getAdminUserDetail(userId: string) {
  const user = await db.query.users.findFirst({
    where: eq(users.id, userId),
  });

  if (!user) {
    throw new AppError(404, "USER_NOT_FOUND", "User not found");
  }

  let panditProfile = null;
  if (user.role === "PANDIT") {
    panditProfile = await db.query.pandits.findFirst({
      where: eq(pandits.userId, userId),
    });
  }

  const [recentBookings, recentConsultations, recentKundliOrders] = await Promise.all([
    db
      .select({
        id: bookings.id,
        mode: bookings.mode,
        bookingTime: bookings.bookingTime,
        status: bookings.status,
        totalAmount: bookings.totalAmount,
        poojaTitle: poojas.title,
        createdAt: bookings.createdAt,
      })
      .from(bookings)
      .leftJoin(poojas, eq(bookings.poojaId, poojas.id))
      .where(eq(bookings.yajmanId, userId))
      .orderBy(desc(bookings.createdAt))
      .limit(5),
    db
      .select()
      .from(consultations)
      .where(eq(consultations.userId, userId))
      .orderBy(desc(consultations.createdAt))
      .limit(5),
    db
      .select()
      .from(kundliOrders)
      .where(eq(kundliOrders.userId, userId))
      .orderBy(desc(kundliOrders.createdAt))
      .limit(5),
  ]);

  return {
    user: {
      id: user.id,
      name: user.name,
      phone: user.phone,
      email: user.email,
      dob: user.dob,
      tob: user.tob,
      pob: user.pob,
      gotra: user.gotra,
      zodiac: user.zodiac,
      city: user.city,
      address: user.address,
      role: user.role,
      createdAt: user.createdAt,
    },
    panditProfile,
    recentBookings,
    recentConsultations,
    recentKundliOrders,
  };
}

/**
 * Admin: List pooja bookings with filters
 */
export async function getAdminBookings(params: {
  status?: string;
  page: number;
  limit: number;
}) {
  const { status = "ALL", page = 1, limit = 20 } = params;
  const offset = (page - 1) * limit;

  const whereClause =
    status && status !== "ALL" ? eq(bookings.status, status as any) : undefined;

  const [totalRes, rows] = await Promise.all([
    db.select({ count: count() }).from(bookings).where(whereClause),
    db
      .select({
        id: bookings.id,
        yajmanId: bookings.yajmanId,
        panditId: bookings.panditId,
        poojaId: bookings.poojaId,
        mode: bookings.mode,
        bookingTime: bookings.bookingTime,
        venueAddress: bookings.venueAddress,
        totalAmount: bookings.totalAmount,
        status: bookings.status,
        paymentStatus: bookings.paymentStatus,
        createdAt: bookings.createdAt,
        poojaTitle: poojas.title,
        yajmanName: users.name,
        yajmanPhone: users.phone,
      })
      .from(bookings)
      .leftJoin(poojas, eq(bookings.poojaId, poojas.id))
      .leftJoin(users, eq(bookings.yajmanId, users.id))
      .where(whereClause)
      .orderBy(desc(bookings.createdAt))
      .limit(limit)
      .offset(offset),
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

/**
 * Admin: Get detailed booking information
 */
export async function getAdminBookingDetail(bookingId: string) {
  const [booking] = await db
    .select({
      id: bookings.id,
      yajmanId: bookings.yajmanId,
      panditId: bookings.panditId,
      poojaId: bookings.poojaId,
      mode: bookings.mode,
      bookingTime: bookings.bookingTime,
      venueAddress: bookings.venueAddress,
      totalAmount: bookings.totalAmount,
      status: bookings.status,
      paymentStatus: bookings.paymentStatus,
      customNotes: bookings.customNotes,
      createdAt: bookings.createdAt,
      poojaTitle: poojas.title,
      yajmanName: users.name,
      yajmanPhone: users.phone,
    })
    .from(bookings)
    .leftJoin(poojas, eq(bookings.poojaId, poojas.id))
    .leftJoin(users, eq(bookings.yajmanId, users.id))
    .where(eq(bookings.id, bookingId));

  if (!booking) {
    throw new AppError(404, "BOOKING_NOT_FOUND", "Booking not found");
  }

  return booking;
}

/**
 * Admin: Update booking status with audit logging
 */
export async function updateAdminBookingStatus(
  adminId: string,
  bookingId: string,
  status: any,
  notes?: string
) {
  const existing = await db.query.bookings.findFirst({
    where: eq(bookings.id, bookingId),
  });

  if (!existing) {
    throw new AppError(404, "BOOKING_NOT_FOUND", "Booking not found");
  }

  const [updated] = await db
    .update(bookings)
    .set({
      status,
      customNotes: notes ? `${existing.customNotes || ""}\n[Admin]: ${notes}`.trim() : existing.customNotes,
      updatedAt: new Date(),
    })
    .where(eq(bookings.id, bookingId))
    .returning();

  logger.info({ bookingId, previousStatus: existing.status, newStatus: status, adminId }, "Admin updated booking status");

  return { success: true, booking: updated };
}

/**
 * Admin: List poojas catalogue
 */
export async function getAdminPoojas(params: {
  category?: string;
  page: number;
  limit: number;
}) {
  const { category, page = 1, limit = 20 } = params;
  const offset = (page - 1) * limit;

  const whereClause = category ? eq(poojas.category, category) : undefined;

  const [totalRes, rows] = await Promise.all([
    db.select({ count: count() }).from(poojas).where(whereClause),
    db
      .select()
      .from(poojas)
      .where(whereClause)
      .orderBy(desc(poojas.createdAt))
      .limit(limit)
      .offset(offset),
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

/**
 * Admin: Create a new pooja
 */
export async function createAdminPooja(data: any) {
  const [created] = await db
    .insert(poojas)
    .values({
      title: data.title,
      slug: data.slug,
      description: data.description,
      category: data.category,
      duration: data.duration,
      requiredPandits: data.requiredPandits || "1",
      basePrice: String(data.basePrice),
      samagriPrice: String(data.samagriPrice || 0),
      durationMinutes: data.durationMinutes,
      imageUrl: data.imageUrl,
      isActive: data.isActive ?? true,
    })
    .returning();

  return created;
}

/**
 * Admin: Update an existing pooja
 */
export async function updateAdminPooja(poojaId: string, data: any) {
  const updatePayload: Record<string, any> = { updatedAt: new Date() };

  if (data.title !== undefined) updatePayload.title = data.title;
  if (data.slug !== undefined) updatePayload.slug = data.slug;
  if (data.description !== undefined) updatePayload.description = data.description;
  if (data.category !== undefined) updatePayload.category = data.category;
  if (data.duration !== undefined) updatePayload.duration = data.duration;
  if (data.requiredPandits !== undefined) updatePayload.requiredPandits = data.requiredPandits;
  if (data.basePrice !== undefined) updatePayload.basePrice = String(data.basePrice);
  if (data.samagriPrice !== undefined) updatePayload.samagriPrice = String(data.samagriPrice);
  if (data.durationMinutes !== undefined) updatePayload.durationMinutes = data.durationMinutes;
  if (data.imageUrl !== undefined) updatePayload.imageUrl = data.imageUrl;
  if (data.isActive !== undefined) updatePayload.isActive = data.isActive;

  const [updated] = await db
    .update(poojas)
    .set(updatePayload)
    .where(eq(poojas.id, poojaId))
    .returning();

  if (!updated) {
    throw new AppError(404, "POOJA_NOT_FOUND", "Pooja not found");
  }

  return updated;
}

export {
  adminApprovePandit,
  adminVerifyDocument,
  adminVerifyVideo,
  adminReviewMantraRecording,
  getPanditDocumentStream,
  getPanditMantraStream,
  getAllMantrasAdmin,
  adminCreateMantra,
  adminUpdateMantra,
  adminDeleteMantra,
};

