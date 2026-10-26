import crypto from "crypto";
import { eq, and, desc, count } from "drizzle-orm";
import { db } from "../db/index.js";
import { kundliOrders, type KundliOrder } from "../db/schema/kundli_orders.js";
import { users } from "../db/schema/users.js";
import { pandits } from "../db/schema/pandits.js";
import { AppError } from "../utils/api-error.js";
import { logger } from "../utils/logger.js";
import { getRazorpayInstance } from "./payments.service.js";
import { getIO } from "./realtime.service.js";

export function generateKundliOrderNumber(): string {
  const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, "");
  const randomSuffix = crypto.randomBytes(3).toString("hex").toUpperCase();
  return `KND-${dateStr}-${randomSuffix}`;
}

export async function createKundliOrder(
  userId: string,
  data: {
    devoteeName: string;
    devoteePhone: string;
    gender?: string;
    dob: string;
    tob: string;
    pob: string;
    birthAccuracy?: string;
    gotra?: string | null;
    language?: string;
    deliveryAddress: string;
    kundliType?: string;
    concernCategory?: string | null;
    specialNotes?: string | null;
  }
) {
  const user = await db.query.users.findFirst({
    where: eq(users.id, userId),
  });

  if (!user) {
    throw new AppError(404, "NOT_FOUND", "User identity not found");
  }

  const orderNumber = generateKundliOrderNumber();
  const standardPrice = "1501.00";

  // Format special notes to preserve Kundli type and concern category consistently
  const notesParts: string[] = [];
  if (data.kundliType && data.kundliType !== "Patrika") {
    notesParts.push(`[Type: ${data.kundliType}]`);
  } else if (data.kundliType) {
    notesParts.push(`[Type: Patrika (32 Page Kundli)]`);
  }
  if (data.concernCategory) {
    notesParts.push(`[Concern: ${data.concernCategory}]`);
  }
  if (data.specialNotes && data.specialNotes.trim().length > 0) {
    notesParts.push(data.specialNotes.trim());
  }
  const formattedSpecialNotes = notesParts.length > 0 ? notesParts.join(" - ") : null;

  const [created] = await db
    .insert(kundliOrders)
    .values({
      orderNumber,
      userId,
      amount: standardPrice,
      currency: "INR",
      status: "REQUESTED",
      paymentStatus: "PENDING",
      devoteeName: data.devoteeName,
      devoteePhone: data.devoteePhone,
      gender: data.gender || "Male",
      dob: data.dob,
      tob: data.tob,
      pob: data.pob,
      birthAccuracy: data.birthAccuracy || "accurate",
      gotra: data.gotra || null,
      language: data.language || "Hindi",
      deliveryAddress: data.deliveryAddress,
      specialNotes: formattedSpecialNotes,
    })
    .returning();

  logger.info({ orderId: created.id, orderNumber, userId }, "Handmade Kundli order request created and persisted");

  try {
    const io = getIO();
    io.to(`user:${userId}`).emit("kundli:created", {
      orderId: created.id,
      orderNumber,
      status: created.status,
    });
    io.to("admin:operations").emit("admin:kundli:new", {
      orderId: created.id,
      orderNumber,
      devoteeName: created.devoteeName,
    });
  } catch (_e) {}

  return created;
}

export async function getUserKundliOrders(
  userId: string,
  params: { page?: number; limit?: number }
) {
  const page = params.page && params.page > 0 ? params.page : 1;
  const limit = params.limit && params.limit > 0 ? params.limit : 20;
  const offset = (page - 1) * limit;

  const [totalRes, rows] = await Promise.all([
    db
      .select({ count: count() })
      .from(kundliOrders)
      .where(eq(kundliOrders.userId, userId)),
    db.query.kundliOrders.findMany({
      where: eq(kundliOrders.userId, userId),
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
      orderBy: [desc(kundliOrders.createdAt)],
      limit,
      offset,
    }),
  ]);

  const total = totalRes[0]?.count ?? 0;

  const items = rows.map((r) => ({
    ...r,
    dob: "••••",
    tob: "••••",
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

export async function getKundliOrderById(
  userId: string,
  userRole: string,
  orderId: string
) {
  const order = await db.query.kundliOrders.findFirst({
    where: eq(kundliOrders.id, orderId),
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

  if (!order) {
    throw new AppError(404, "NOT_FOUND", "Kundli order not found");
  }

  const isOwner = order.userId === userId;
  const isAdmin = userRole === "ADMIN";

  if (!isOwner && !isAdmin) {
    if (userRole === "PANDIT") {
      const pandit = await db.query.pandits.findFirst({
        where: eq(pandits.userId, userId),
      });
      if (!pandit || order.assignedPanditId !== pandit.id) {
        throw new AppError(403, "FORBIDDEN", "Access denied to this order");
      }
    } else {
      throw new AppError(403, "FORBIDDEN", "Access denied to this order");
    }
  }

  return order;
}

export async function cancelKundliOrder(
  userId: string,
  orderId: string,
  cancellationReason: string
) {
  const order = await db.query.kundliOrders.findFirst({
    where: and(eq(kundliOrders.id, orderId), eq(kundliOrders.userId, userId)),
  });

  if (!order) {
    throw new AppError(404, "NOT_FOUND", "Kundli order not found or access denied");
  }

  if (["PREPARING", "READY", "DISPATCHED", "DELIVERED", "CANCELLED", "REJECTED"].includes(order.status)) {
    throw new AppError(
      400,
      "INVALID_STATE_TRANSITION",
      `Cannot cancel Kundli order in ${order.status} state`
    );
  }

  const [updated] = await db
    .update(kundliOrders)
    .set({
      status: "CANCELLED",
      cancellationReason,
      updatedAt: new Date(),
    })
    .where(eq(kundliOrders.id, orderId))
    .returning();

  logger.info({ orderId, userId }, "Kundli order cancelled by devotee");

  try {
    const io = getIO();
    io.to(`user:${userId}`).emit("kundli:status-change", {
      orderId,
      status: "CANCELLED",
      cancellationReason,
    });
  } catch (_e) {}

  return updated;
}

export async function adminGetKundliOrders(params: {
  status?: string;
  page?: number;
  limit?: number;
}) {
  const page = params.page && params.page > 0 ? params.page : 1;
  const limit = params.limit && params.limit > 0 ? params.limit : 20;
  const offset = (page - 1) * limit;

  const whereClause =
    params.status && params.status !== "ALL"
      ? eq(kundliOrders.status, params.status as any)
      : undefined;

  const [totalRes, rows] = await Promise.all([
    db
      .select({ count: count() })
      .from(kundliOrders)
      .where(whereClause),
    db.query.kundliOrders.findMany({
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
      orderBy: [desc(kundliOrders.createdAt)],
      limit,
      offset,
    }),
  ]);

  const total = totalRes[0]?.count ?? 0;

  // Mask sensitive birth data in list view
  const items = rows.map((r) => ({
    ...r,
    dob: "••••",
    tob: "••••",
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

export async function adminDecisionKundliOrder(
  reviewerId: string,
  orderId: string,
  decision: "ACCEPT" | "REJECT",
  reason?: string | null
) {
  const order = await db.query.kundliOrders.findFirst({
    where: eq(kundliOrders.id, orderId),
  });

  if (!order) {
    throw new AppError(404, "NOT_FOUND", "Kundli order not found");
  }

  const isAccept = decision === "ACCEPT";
  const newStatus = isAccept ? "ACCEPTED" : "REJECTED";

  const [updated] = await db
    .update(kundliOrders)
    .set({
      status: newStatus,
      rejectionReason: !isAccept ? reason || "Birth details incomplete or unverified" : null,
      updatedAt: new Date(),
    })
    .where(eq(kundliOrders.id, orderId))
    .returning();

  logger.info({ orderId, decision, reviewerId }, "Admin made decision on Kundli order");

  try {
    const io = getIO();
    io.to(`user:${order.userId}`).emit("kundli:status-change", {
      orderId,
      status: newStatus,
      reason,
    });
  } catch (_e) {}

  return updated;
}

export async function adminAssignPanditToKundli(
  reviewerId: string,
  orderId: string,
  panditId: string
) {
  const [order, pandit] = await Promise.all([
    db.query.kundliOrders.findFirst({
      where: eq(kundliOrders.id, orderId),
    }),
    db.query.pandits.findFirst({
      where: eq(pandits.id, panditId),
      with: { user: true },
    }),
  ]);

  if (!order) {
    throw new AppError(404, "NOT_FOUND", "Kundli order not found");
  }

  if (!pandit) {
    throw new AppError(404, "NOT_FOUND", "Pandit not found");
  }

  if (!pandit.isVerified || pandit.verificationStatus !== "APPROVED") {
    throw new AppError(
      400,
      "INVALID_PANDIT_STATE",
      "Only verified and approved Acharyas can be assigned to prepare handwritten Kundli manuscripts"
    );
  }

  const [updated] = await db
    .update(kundliOrders)
    .set({
      assignedPanditId: panditId,
      status: "ASSIGNED",
      updatedAt: new Date(),
    })
    .where(eq(kundliOrders.id, orderId))
    .returning();

  logger.info({ orderId, panditId, reviewerId }, "Pandit assigned to Kundli order");

  try {
    const io = getIO();
    io.to(`user:${order.userId}`).emit("kundli:status-change", {
      orderId,
      status: "ASSIGNED",
      assignedPandit: {
        id: pandit.id,
        name: pandit.user?.name || "Verified Astrologer",
      },
    });
  } catch (_e) {}

  return updated;
}

export async function adminUpdateKundliStatus(
  reviewerId: string,
  orderId: string,
  data: {
    status:
      | "REQUESTED"
      | "UNDER_REVIEW"
      | "ACCEPTED"
      | "PAYMENT_PENDING"
      | "PAID"
      | "ASSIGNED"
      | "PREPARING"
      | "READY"
      | "DISPATCHED"
      | "DELIVERED"
      | "CANCELLED"
      | "REJECTED";
    dispatchTrackingNumber?: string | null;
    courierPartner?: string | null;
    notes?: string | null;
  }
) {
  const order = await db.query.kundliOrders.findFirst({
    where: eq(kundliOrders.id, orderId),
  });

  if (!order) {
    throw new AppError(404, "NOT_FOUND", "Kundli order not found");
  }

  const VALID_KUNDLI_TRANSITIONS: Record<string, string[]> = {
    REQUESTED: ["UNDER_REVIEW", "ACCEPTED", "PAYMENT_PENDING", "REJECTED", "CANCELLED"],
    UNDER_REVIEW: ["ACCEPTED", "PAYMENT_PENDING", "REJECTED", "CANCELLED"],
    ACCEPTED: ["PAYMENT_PENDING", "CANCELLED", "REJECTED"],
    PAYMENT_PENDING: ["PAID", "CANCELLED", "REJECTED"],
    PAID: ["ASSIGNED", "PREPARING", "CANCELLED"],
    ASSIGNED: ["PREPARING", "READY", "CANCELLED"],
    PREPARING: ["READY", "DISPATCHED"],
    READY: ["DISPATCHED"],
    DISPATCHED: ["DELIVERED"],
    DELIVERED: [],
    CANCELLED: [],
    REJECTED: [],
  };

  const allowedNext = VALID_KUNDLI_TRANSITIONS[order.status] || [];
  if (!allowedNext.includes(data.status)) {
    throw new AppError(
      400,
      "INVALID_TRANSITION",
      `Invalid status transition: Cannot transition Kundli order from ${order.status} to ${data.status}`
    );
  }

  const updateData: Partial<KundliOrder> = {
    status: data.status,
    updatedAt: new Date(),
  };

  if (data.dispatchTrackingNumber) {
    updateData.dispatchTrackingNumber = data.dispatchTrackingNumber;
  }
  if (data.courierPartner) {
    updateData.courierPartner = data.courierPartner;
  }

  const [updated] = await db
    .update(kundliOrders)
    .set(updateData)
    .where(eq(kundliOrders.id, orderId))
    .returning();

  logger.info({ orderId, status: data.status, reviewerId }, "Kundli order status updated by admin");

  try {
    const io = getIO();
    io.to(`user:${order.userId}`).emit("kundli:status-change", {
      orderId,
      status: data.status,
      dispatchTrackingNumber: data.dispatchTrackingNumber,
      courierPartner: data.courierPartner,
    });
  } catch (_e) {}

  return updated;
}

export async function createKundliPaymentOrder(
  userId: string,
  orderId: string
) {
  const order = await db.query.kundliOrders.findFirst({
    where: and(eq(kundliOrders.id, orderId), eq(kundliOrders.userId, userId)),
  });

  if (!order) {
    throw new AppError(404, "NOT_FOUND", "Kundli order not found");
  }

  if (order.paymentStatus === "PAID") {
    throw new AppError(400, "ALREADY_PAID", "Kundli order has already been paid for");
  }

  if (order.status !== "PAYMENT_PENDING") {
    throw new AppError(
      400,
      "INVALID_STATE",
      "Payment can only be initiated when order is in PAYMENT_PENDING state"
    );
  }

  if (order.razorpayOrderId) {
    return {
      orderId: order.razorpayOrderId,
      amount: Math.round(parseFloat(order.amount.toString()) * 100),
      currency: "INR",
      orderNumber: order.orderNumber,
    };
  }

  const razorpay = getRazorpayInstance();
  const amountInPaise = Math.round(parseFloat(order.amount.toString()) * 100);

  const razorpayOrder = await razorpay.orders.create({
    amount: amountInPaise,
    currency: "INR",
    receipt: order.orderNumber || order.id,
    notes: {
      kundliOrderId: order.id,
      devoteeName: order.devoteeName || "Devotee",
    },
  });

  await db
    .update(kundliOrders)
    .set({
      razorpayOrderId: razorpayOrder.id,
      updatedAt: new Date(),
    })
    .where(eq(kundliOrders.id, order.id));

  return {
    orderId: razorpayOrder.id,
    amount: amountInPaise,
    currency: "INR",
    orderNumber: order.orderNumber,
  };
}

export async function verifyKundliPayment(
  userId: string,
  orderId: string,
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

  const order = await db.query.kundliOrders.findFirst({
    where: and(eq(kundliOrders.id, orderId), eq(kundliOrders.userId, userId)),
  });

  if (!order) {
    throw new AppError(404, "NOT_FOUND", "Kundli order not found");
  }

  if (order.paymentStatus === "PAID") {
    return order;
  }

  const [updated] = await db
    .update(kundliOrders)
    .set({
      paymentStatus: "PAID",
      razorpayPaymentId,
      razorpaySignature,
      paidAt: new Date(),
      status: "PAID",
      updatedAt: new Date(),
    })
    .where(eq(kundliOrders.id, order.id))
    .returning();

  logger.info({ orderId, razorpayPaymentId }, "Kundli order payment verified successfully");

  return updated;
}
