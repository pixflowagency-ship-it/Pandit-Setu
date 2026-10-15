import crypto from "crypto";
import Razorpay from "razorpay";
import { eq, and } from "drizzle-orm";
import { db } from "../db/index.js";
import { bookings } from "../db/schema/bookings.js";
import { pandits } from "../db/schema/pandits.js";
import { dakshinaCollections } from "../db/schema/dakshina_collections.js";
import { AppError } from "../utils/api-error.js";
import { getIO } from "./realtime.service.js";
import { sendPush } from "./notification.service.js";
import type {
  CollectCashDakshinaInput,
  CreateDakshinaOrderInput,
  VerifyDakshinaPaymentInput,
} from "../validators/dakshina.validator.js";

const getRazorpayInstance = () => {
  const key_id = process.env.RAZORPAY_KEY_ID;
  const key_secret = process.env.RAZORPAY_KEY_SECRET;
  if (!key_id || !key_secret) {
    throw new AppError(500, "CONFIGURATION_ERROR", "Razorpay credentials are not configured");
  }
  return new Razorpay({ key_id, key_secret });
};

export async function collectCashDakshina(
  bookingId: string,
  panditId: string,
  input: CollectCashDakshinaInput
) {
  // 1. Verify booking exists
  const booking = await db.query.bookings.findFirst({
    where: eq(bookings.id, bookingId),
    with: {
      pooja: true,
    },
  });

  if (!booking) {
    throw new AppError(404, "NOT_FOUND", "Booking not found");
  }

  // 2. Authorization: Caller must be the assigned Pandit
  if (booking.panditId !== panditId) {
    throw new AppError(403, "FORBIDDEN", "Only the assigned Pandit can collect Dakshina for this booking");
  }

  // 3. Authorization: Assigned Pandit must be verified and approved
  const pandit = await db.query.pandits.findFirst({
    where: eq(pandits.userId, panditId),
  });

  if (!pandit || pandit.verificationStatus !== "APPROVED" || !pandit.isVerified) {
    throw new AppError(403, "PANDIT_NOT_APPROVED", "Only approved Pandits can collect Dakshina");
  }

  // 4. Lifecycle state gate: Booking must be in PUJA_STARTED or IN_PROGRESS
  if (booking.status !== "PUJA_STARTED" && booking.status !== "IN_PROGRESS" && booking.status !== "COMPLETED") {
    throw new AppError(
      400,
      "INVALID_BOOKING_STATE",
      `Dakshina can only be collected during or after puja execution (current status: ${booking.status})`
    );
  }

  // 5. Idempotency: If Dakshina is already paid, return existing record safely
  const existingPaid = await db.query.dakshinaCollections.findFirst({
    where: and(
      eq(dakshinaCollections.bookingId, bookingId),
      eq(dakshinaCollections.paymentStatus, "PAID")
    ),
  });

  if (existingPaid) {
    return { dakshina: existingPaid, booking, alreadyPaid: true };
  }

  // 6. Server-side amount validation
  const defaultAmount = parseFloat(booking.totalAmount.toString());
  const finalAmount = input.amount !== undefined ? input.amount : defaultAmount;

  if (finalAmount <= 0) {
    throw new AppError(400, "BAD_REQUEST", "Dakshina amount must be a positive number");
  }

  // 7. Atomic insert into dakshina_collections
  const [collection] = await db.insert(dakshinaCollections)
    .values({
      bookingId,
      panditId,
      amount: finalAmount.toFixed(2),
      currency: "INR",
      paymentMethod: "CASH",
      paymentStatus: "PAID",
      collectedAt: new Date(),
      notes: input.notes,
    })
    .returning();

  let updatedBooking = booking;

  // 8. Optionally complete booking atomically if requested
  if (input.completeBooking && booking.status !== "COMPLETED") {
    const [completed] = await db.update(bookings)
      .set({ status: "COMPLETED", updatedAt: new Date() })
      .where(and(
        eq(bookings.id, bookingId),
        eq(bookings.panditId, panditId),
        eq(bookings.status, booking.status)
      ))
      .returning();

    if (completed) {
      updatedBooking = { ...booking, status: "COMPLETED" };
    }
  }

  // 9. Post-commit Socket.IO realtime emission
  try {
    const io = getIO();
    const payload = {
      bookingId,
      method: "CASH",
      amount: finalAmount,
      currency: "INR",
      status: "PAID",
      timestamp: collection.collectedAt?.toISOString() || new Date().toISOString(),
    };
    io.to(`booking:${bookingId}`).emit("dakshina:collected", payload);
    io.to(`user:${booking.yajmanId}`).emit("dakshina:collected", payload);
    io.to(`user:${panditId}`).emit("dakshina:collected", payload);

    if (input.completeBooking && updatedBooking.status === "COMPLETED") {
      const statusPayload = {
        bookingId,
        status: "COMPLETED",
        timestamp: new Date().toISOString(),
      };
      io.to(`booking:${bookingId}`).emit("booking:status-change", statusPayload);
      io.to(`booking:${bookingId}`).emit("booking:status-changed", statusPayload);
      io.to(`user:${booking.yajmanId}`).emit("booking:status-change", statusPayload);
      io.to(`user:${panditId}`).emit("booking:status-change", statusPayload);
    }
  } catch (err) {
    console.warn("Socket.io emit failed (server running without socket init):", err);
  }

  // 10. Non-blocking FCM notification to Yajman
  sendPush(
    booking.yajmanId,
    "Dakshina Confirmed 🙏",
    `Acharya confirmed cash Dakshina of ₹${finalAmount.toFixed(0)} for your Pooja.`,
    { bookingId, type: "DAKSHINA_PAID" }
  ).catch(() => {});

  return { dakshina: collection, booking: updatedBooking, alreadyPaid: false };
}

export async function createDakshinaOrder(
  bookingId: string,
  panditId: string,
  input: CreateDakshinaOrderInput
) {
  // 1. Verify booking exists
  const booking = await db.query.bookings.findFirst({
    where: eq(bookings.id, bookingId),
  });

  if (!booking) {
    throw new AppError(404, "NOT_FOUND", "Booking not found");
  }

  // 2. Authorization: Caller must be the assigned Pandit
  if (booking.panditId !== panditId) {
    throw new AppError(403, "FORBIDDEN", "Only the assigned Pandit can create a Dakshina order");
  }

  // 3. Authorization: Assigned Pandit must be verified and approved
  const pandit = await db.query.pandits.findFirst({
    where: eq(pandits.userId, panditId),
  });

  if (!pandit || pandit.verificationStatus !== "APPROVED" || !pandit.isVerified) {
    throw new AppError(403, "PANDIT_NOT_APPROVED", "Only approved Pandits can create a Dakshina order");
  }

  // 4. Lifecycle state gate
  if (booking.status !== "PUJA_STARTED" && booking.status !== "IN_PROGRESS") {
    throw new AppError(
      400,
      "INVALID_BOOKING_STATE",
      `Dakshina order can only be created during puja execution (current status: ${booking.status})`
    );
  }

  // 5. Check if already paid
  const existingPaid = await db.query.dakshinaCollections.findFirst({
    where: and(
      eq(dakshinaCollections.bookingId, bookingId),
      eq(dakshinaCollections.paymentStatus, "PAID")
    ),
  });

  if (existingPaid) {
    throw new AppError(400, "DAKSHINA_ALREADY_PAID", "Dakshina for this booking has already been collected.");
  }

  // 6. Idempotency: Return existing pending order if already generated
  const existingPending = await db.query.dakshinaCollections.findFirst({
    where: and(
      eq(dakshinaCollections.bookingId, bookingId),
      eq(dakshinaCollections.paymentMethod, "ONLINE"),
      eq(dakshinaCollections.paymentStatus, "PENDING")
    ),
  });

  if (existingPending && existingPending.razorpayOrderId) {
    return {
      order: {
        id: existingPending.razorpayOrderId,
        amount: Math.round(parseFloat(existingPending.amount.toString()) * 100),
        currency: "INR",
        receipt: `dakshina_${bookingId.slice(0, 20)}`,
        status: "created",
      },
      dakshina: existingPending,
    };
  }

  // 7. Calculate server-controlled amount
  const defaultAmount = parseFloat(booking.totalAmount.toString());
  const finalAmount = input.amount !== undefined ? input.amount : defaultAmount;

  if (finalAmount <= 0) {
    throw new AppError(400, "BAD_REQUEST", "Dakshina amount must be a positive number");
  }

  const razorpay = getRazorpayInstance();
  const amountInPaise = Math.round(finalAmount * 100);

  try {
    const order = await razorpay.orders.create({
      amount: amountInPaise,
      currency: "INR",
      receipt: `dakshina_${bookingId.slice(0, 20)}`,
      notes: {
        bookingId,
        panditId,
        type: "DAKSHINA",
      },
    });

    const [collection] = await db.insert(dakshinaCollections)
      .values({
        bookingId,
        panditId,
        amount: finalAmount.toFixed(2),
        currency: "INR",
        paymentMethod: "ONLINE",
        paymentStatus: "PENDING",
        razorpayOrderId: order.id,
      })
      .returning();

    return { order, dakshina: collection };
  } catch (error: any) {
    if (error instanceof AppError) throw error;
    console.error("Dakshina Razorpay order creation failed:", error);
    throw new AppError(500, "PAYMENT_GATEWAY_ERROR", "Failed to create Dakshina payment order");
  }
}

export async function verifyDakshinaPayment(
  bookingId: string,
  panditId: string,
  input: VerifyDakshinaPaymentInput
) {
  // 1. Verify Razorpay credentials
  const secret = process.env.RAZORPAY_KEY_SECRET;
  if (!secret) {
    throw new AppError(500, "CONFIGURATION_ERROR", "Razorpay key secret is not configured");
  }

  // 2. Cryptographic signature verification (timing-safe)
  const generatedSignature = crypto
    .createHmac("sha256", secret)
    .update(`${input.orderId}|${input.paymentId}`)
    .digest("hex");

  const generatedBuffer = Buffer.from(generatedSignature, "utf-8");
  const providedBuffer = Buffer.from(input.signature, "utf-8");

  let isSignatureValid = false;
  if (generatedBuffer.length === providedBuffer.length) {
    isSignatureValid = crypto.timingSafeEqual(generatedBuffer, providedBuffer);
  }

  if (!isSignatureValid) {
    throw new AppError(400, "BAD_REQUEST", "Invalid payment signature");
  }

  // 3. Find associated Dakshina collection record
  const dakshina = await db.query.dakshinaCollections.findFirst({
    where: and(
      eq(dakshinaCollections.bookingId, bookingId),
      eq(dakshinaCollections.razorpayOrderId, input.orderId)
    ),
  });

  if (!dakshina) {
    throw new AppError(404, "NOT_FOUND", "Associated Dakshina order record not found");
  }

  const booking = await db.query.bookings.findFirst({
    where: eq(bookings.id, bookingId),
  });

  if (!booking) {
    throw new AppError(404, "NOT_FOUND", "Associated booking not found");
  }

  // 4. Idempotency: If already marked PAID, return existing record
  if (dakshina.paymentStatus === "PAID") {
    return { dakshina, booking, alreadyPaid: true };
  }

  // 5. Update collection status to PAID
  const [updatedDakshina] = await db.update(dakshinaCollections)
    .set({
      paymentStatus: "PAID",
      razorpayPaymentId: input.paymentId,
      razorpaySignature: input.signature,
      collectedAt: new Date(),
      updatedAt: new Date(),
    })
    .where(and(
      eq(dakshinaCollections.id, dakshina.id),
      eq(dakshinaCollections.paymentStatus, "PENDING")
    ))
    .returning();

  let updatedBooking = booking;

  // 6. Optionally complete booking atomically
  if (input.completeBooking && booking.status !== "COMPLETED") {
    const [completed] = await db.update(bookings)
      .set({ status: "COMPLETED", updatedAt: new Date() })
      .where(and(
        eq(bookings.id, bookingId),
        eq(bookings.panditId, panditId)
      ))
      .returning();

    if (completed) {
      updatedBooking = { ...booking, status: "COMPLETED" };
    }
  }

  // 7. Real-time post-commit Socket.IO emission
  try {
    const io = getIO();
    const payload = {
      bookingId,
      method: "ONLINE",
      amount: parseFloat(updatedDakshina?.amount?.toString() || dakshina.amount.toString()),
      currency: "INR",
      status: "PAID",
      timestamp: new Date().toISOString(),
    };
    io.to(`booking:${bookingId}`).emit("dakshina:collected", payload);
    io.to(`user:${booking.yajmanId}`).emit("dakshina:collected", payload);
    io.to(`user:${panditId}`).emit("dakshina:collected", payload);

    if (input.completeBooking && updatedBooking.status === "COMPLETED") {
      const statusPayload = {
        bookingId,
        status: "COMPLETED",
        timestamp: new Date().toISOString(),
      };
      io.to(`booking:${bookingId}`).emit("booking:status-change", statusPayload);
      io.to(`booking:${bookingId}`).emit("booking:status-changed", statusPayload);
      io.to(`user:${booking.yajmanId}`).emit("booking:status-change", statusPayload);
      io.to(`user:${panditId}`).emit("booking:status-change", statusPayload);
    }
  } catch (err) {
    console.warn("Socket.io emit failed (server running without socket init):", err);
  }

  // 8. Push notification
  sendPush(
    booking.yajmanId,
    "Dakshina Payment Successful 🙏",
    `Your online Dakshina payment has been received and verified. Thank you!`,
    { bookingId, type: "DAKSHINA_PAID" }
  ).catch(() => {});

  return { dakshina: updatedDakshina || dakshina, booking: updatedBooking, alreadyPaid: false };
}

export async function getDakshinaStatus(bookingId: string, userId: string) {
  const booking = await db.query.bookings.findFirst({
    where: eq(bookings.id, bookingId),
  });

  if (!booking) {
    throw new AppError(404, "NOT_FOUND", "Booking not found");
  }

  // Authorization: Only assigned Pandit or Yajman or Admin
  if (booking.panditId !== userId && booking.yajmanId !== userId) {
    throw new AppError(403, "FORBIDDEN", "You are not authorized to view Dakshina for this booking");
  }

  const collections = await db.query.dakshinaCollections.findMany({
    where: eq(dakshinaCollections.bookingId, bookingId),
  });

  const paidCollection = collections.find((c) => c.paymentStatus === "PAID") || null;

  return {
    isPaid: Boolean(paidCollection),
    collection: paidCollection || collections[0] || null,
    allAttempts: collections,
  };
}
