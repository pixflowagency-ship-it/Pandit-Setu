import crypto from "crypto";
import Razorpay from "razorpay";
import { eq, and } from "drizzle-orm";
import { db } from "../db/index.js";
import { bookings } from "../db/schema/bookings.js";
import { AppError } from "../utils/api-error.js";
import { getRedis } from "../config/redis.js";

// Initialize Razorpay conditionally based on env (so tests don't crash if omitted)
const getRazorpayInstance = () => {
  const key_id = process.env.RAZORPAY_KEY_ID || "test_key_id";
  const key_secret = process.env.RAZORPAY_KEY_SECRET || "test_key_secret";
  return new Razorpay({ key_id, key_secret });
};

export async function createRazorpayOrder(userId: string, bookingId: string) {
  const booking = await db.query.bookings.findFirst({
    where: and(
      eq(bookings.id, bookingId),
      eq(bookings.yajmanId, userId)
    ),
  });

  if (!booking) {
    throw new AppError(404, "NOT_FOUND", "Booking not found");
  }

  // Idempotency: Return existing order if already created
  if (booking.razorpayOrderId) {
    return {
      id: booking.razorpayOrderId,
      amount: Math.round(parseFloat(booking.totalAmount.toString()) * 100),
      currency: "INR",
      receipt: booking.id,
      status: "created",
    };
  }

  const razorpay = getRazorpayInstance();
  const amountInPaise = Math.round(parseFloat(booking.totalAmount.toString()) * 100);

  try {
    const order = await razorpay.orders.create({
      amount: amountInPaise,
      currency: "INR",
      receipt: booking.id,
    });

    await db.update(bookings)
      .set({ razorpayOrderId: order.id, updatedAt: new Date() })
      .where(eq(bookings.id, booking.id));

    return order;
  } catch (error: any) {
    console.error("Razorpay order creation failed:", error);
    throw new AppError(500, "PAYMENT_GATEWAY_ERROR", "Failed to create payment order");
  }
}

export async function verifyPaymentSignature(userId: string, orderId: string, paymentId: string, signature: string) {
  const secret = process.env.RAZORPAY_KEY_SECRET || "test_key_secret";
  
  const generatedSignature = crypto
    .createHmac("sha256", secret)
    .update(`${orderId}|${paymentId}`)
    .digest("hex");

  const generatedBuffer = Buffer.from(generatedSignature, "utf-8");
  const providedBuffer = Buffer.from(signature, "utf-8");

  let isSignatureValid = false;
  if (generatedBuffer.length === providedBuffer.length) {
    isSignatureValid = crypto.timingSafeEqual(generatedBuffer, providedBuffer);
  }

  if (!isSignatureValid) {
    throw new AppError(400, "BAD_REQUEST", "Invalid payment signature");
  }

  const booking = await db.query.bookings.findFirst({
    where: and(
      eq(bookings.razorpayOrderId, orderId),
      eq(bookings.yajmanId, userId)
    ),
  });

  if (!booking) {
    throw new AppError(404, "NOT_FOUND", "Associated booking not found");
  }

  // Update payment status safely
  const [updatedBooking] = await db.update(bookings)
    .set({
      paymentId,
      paymentStatus: "PAID",
      status: booking.status === "PENDING" ? "CONFIRMED" : booking.status,
      updatedAt: new Date()
    })
    .where(eq(bookings.id, booking.id))
    .returning();

  return updatedBooking;
}

export async function createRazorpaySubscription(userId: string, planId: string) {
  const { subscriptions } = await import("../db/schema/subscriptions.js");

  const razorpay = getRazorpayInstance();
  
  try {
    const sub = await razorpay.subscriptions.create({
      plan_id: planId,
      total_count: 12,
      customer_notify: 1,
    });

    const [insertedSub] = await db.insert(subscriptions)
      .values({
        userId,
        planId,
        razorpaySubscriptionId: sub.id,
        status: "CREATED",
      })
      .returning();

    return insertedSub;
  } catch (error: any) {
    console.error("Razorpay subscription creation failed:", error);
    throw new AppError(500, "PAYMENT_GATEWAY_ERROR", "Failed to create subscription");
  }
}

export async function handleWebhookEvent(event: any, signature: string, rawBody: Buffer) {
  const secret = process.env.RAZORPAY_WEBHOOK_SECRET || "test_webhook_secret";

  const generatedSignature = crypto
    .createHmac("sha256", secret)
    .update(rawBody)
    .digest("hex");

  const generatedBuffer = Buffer.from(generatedSignature, "utf-8");
  const providedBuffer = Buffer.from(signature, "utf-8");

  let isSignatureValid = false;
  if (generatedBuffer.length === providedBuffer.length) {
    isSignatureValid = crypto.timingSafeEqual(generatedBuffer, providedBuffer);
  }

  if (!isSignatureValid) {
    throw new AppError(401, "UNAUTHORIZED", "Invalid webhook signature");
  }

  const redis = await getRedis();
  const idempotencyKey = `webhook:processed:${event.id}`;

  if (redis) {
    const isProcessed = await redis.get(idempotencyKey);
    if (isProcessed) {
      // Already processed, return early to prevent double-fulfillment
      return;
    }
  }

  const payload = event.payload?.payment?.entity || event.payload?.order?.entity || event.payload?.subscription?.entity;
  
  // Handle One-off Payments
  const orderId = payload?.order_id || (event.event === 'order.paid' ? payload?.id : null);
  if (orderId && (event.event === "payment.captured" || event.event === "order.paid")) {
    const booking = await db.query.bookings.findFirst({
      where: eq(bookings.razorpayOrderId, orderId)
    });

    if (booking && booking.paymentStatus !== "PAID") {
      await db.update(bookings)
        .set({
          paymentStatus: "PAID",
          status: booking.status === "PENDING" ? "CONFIRMED" : booking.status,
          updatedAt: new Date()
        })
        .where(eq(bookings.id, booking.id));
    }
  }

  // Handle Subscriptions
  const subscriptionId = event.event.startsWith("subscription") ? payload?.id || payload?.subscription_id : null;
  
  if (subscriptionId) {
    const { subscriptions } = await import("../db/schema/subscriptions.js");
    const sub = await db.query.subscriptions.findFirst({
      where: eq(subscriptions.razorpaySubscriptionId, subscriptionId)
    });

    if (sub) {
      const updateData: any = { updatedAt: new Date() };

      switch (event.event) {
        case "subscription.activated":
          updateData.status = "ACTIVE";
          break;
        case "subscription.charged":
          updateData.status = "ACTIVE";
          if (payload?.current_end) {
            updateData.currentPeriodEnd = new Date(payload.current_end * 1000);
          }
          break;
        case "subscription.halted":
          updateData.status = "HALTED";
          break;
        case "subscription.cancelled":
          updateData.status = "CANCELLED";
          break;
      }

      if (Object.keys(updateData).length > 1) {
        await db.update(subscriptions)
          .set(updateData)
          .where(eq(subscriptions.id, sub.id));
      }
    }
  }

  if (redis) {
    await redis.setex(idempotencyKey, 86400, "1"); // 24h TTL
  }
}
