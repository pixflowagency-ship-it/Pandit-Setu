import crypto from "crypto";
import { eq, and, desc, inArray, count } from "drizzle-orm";
import { db } from "../db/index.js";
import { productOrders, productOrderItems } from "../db/schema/product_orders.js";
import { products } from "../db/schema/products.js";
import { AppError } from "../utils/api-error.js";
import { getRazorpayInstance } from "./payments.service.js";
import type {
  CreateProductOrderInput,
  ListProductOrdersQuery,
  VerifyOrderPaymentInput,
} from "../validators/product-orders.validator.js";

export async function createProductOrder(
  customerId: string,
  input: CreateProductOrderInput
) {
  return await db.transaction(async (tx) => {
    const productIds = Array.from(new Set(input.items.map((i) => i.productId)));

    // Fetch authoritative product records
    const fetchedProducts = await tx
      .select()
      .from(products)
      .where(inArray(products.id, productIds));

    if (fetchedProducts.length !== productIds.length) {
      throw new AppError(
        404,
        "PRODUCT_NOT_FOUND",
        "One or more selected products could not be found"
      );
    }

    const productMap = new Map(fetchedProducts.map((p) => [p.id, p]));

    // Validate availability and calculate totals server-side
    let subtotal = 0;
    const itemsToInsert: {
      productId: string;
      productName: string;
      productSku: string | null;
      quantity: number;
      unitPrice: string;
      lineTotal: string;
    }[] = [];

    for (const item of input.items) {
      const product = productMap.get(item.productId)!;

      if (!product.isActive || product.status !== "Active") {
        throw new AppError(
          400,
          "INACTIVE_PRODUCT",
          `Product "${product.name}" is currently unavailable`
        );
      }

      const unitPrice = parseFloat(product.price.toString());
      if (isNaN(unitPrice) || unitPrice < 0) {
        throw new AppError(
          400,
          "INVALID_PRODUCT_PRICE",
          `Invalid price for product "${product.name}"`
        );
      }

      const lineTotal = Math.round(unitPrice * item.quantity * 100) / 100;
      subtotal += lineTotal;

      itemsToInsert.push({
        productId: product.id,
        productName: product.name,
        productSku: product.productId || null,
        quantity: item.quantity,
        unitPrice: unitPrice.toFixed(2),
        lineTotal: lineTotal.toFixed(2),
      });
    }

    subtotal = Math.round(subtotal * 100) / 100;

    // Delivery fee rule: Free shipping for orders >= ₹500, else ₹50
    const deliveryCharge = subtotal >= 500 ? 0 : 50;
    const discount = 0;
    const totalAmount = Math.round((subtotal + deliveryCharge - discount) * 100) / 100;

    // Generate unique, readable order number
    const orderNumber = `SM-ORD-${Date.now().toString(36).toUpperCase()}-${Math.floor(
      1000 + Math.random() * 9000
    )}`;

    const [createdOrder] = await tx
      .insert(productOrders)
      .values({
        orderNumber,
        customerId,
        status: "PENDING",
        paymentStatus: "PENDING",
        subtotal: subtotal.toFixed(2),
        deliveryCharge: deliveryCharge.toFixed(2),
        discount: discount.toFixed(2),
        totalAmount: totalAmount.toFixed(2),
        currency: "INR",
        shippingName: input.shippingName,
        shippingPhone: input.shippingPhone,
        shippingAddress: input.shippingAddress,
        shippingCity: input.shippingCity,
        shippingPincode: input.shippingPincode,
        shippingNotes: input.shippingNotes || null,
      })
      .returning();

    const orderItemsWithOrderId = itemsToInsert.map((item) => ({
      ...item,
      orderId: createdOrder.id,
    }));

    const createdItems = await tx
      .insert(productOrderItems)
      .values(orderItemsWithOrderId)
      .returning();

    return {
      ...createdOrder,
      items: createdItems,
    };
  });
}

export async function listProductOrders(
  customerId: string,
  query: ListProductOrdersQuery
) {
  const page = Number(query.page) || 1;
  const limit = Number(query.limit) || 20;
  const offset = (page - 1) * limit;

  const whereConditions = [eq(productOrders.customerId, customerId)];
  if (query.status) {
    whereConditions.push(eq(productOrders.status, query.status));
  }

  const whereClause =
    whereConditions.length === 1 ? whereConditions[0] : and(...whereConditions);

  const [ordersList, [{ total }]] = await Promise.all([
    db.query.productOrders.findMany({
      where: whereClause,
      with: {
        items: true,
      },
      orderBy: [desc(productOrders.createdAt)],
      limit,
      offset,
    }),
    db
      .select({ total: count() })
      .from(productOrders)
      .where(whereClause),
  ]);

  const totalPages = Math.ceil(total / limit) || 1;

  return {
    orders: ordersList,
    pagination: {
      total,
      page,
      limit,
      totalPages,
      hasNext: page < totalPages,
      hasPrev: page > 1,
    },
  };
}

export async function getProductOrderById(
  orderId: string,
  customerId: string,
  isAdmin: boolean = false
) {
  const order = await db.query.productOrders.findFirst({
    where: eq(productOrders.id, orderId),
    with: {
      items: true,
    },
  });

  if (!order) {
    throw new AppError(404, "NOT_FOUND", "Product order not found");
  }

  if (!isAdmin && order.customerId !== customerId) {
    throw new AppError(
      403,
      "FORBIDDEN",
      "You are not authorized to view this product order"
    );
  }

  return order;
}

export async function createOrderPayment(
  orderId: string,
  customerId: string
) {
  const order = await getProductOrderById(orderId, customerId);

  if (order.paymentStatus === "PAID") {
    throw new AppError(
      400,
      "ORDER_ALREADY_PAID",
      "This order has already been paid"
    );
  }

  // Idempotency: Return existing Razorpay order if already created
  if (order.razorpayOrderId) {
    return {
      id: order.razorpayOrderId,
      amount: Math.round(parseFloat(order.totalAmount.toString()) * 100),
      currency: "INR",
      receipt: order.orderNumber,
      status: "created",
    };
  }

  const razorpay = getRazorpayInstance();
  const amountInPaise = Math.round(parseFloat(order.totalAmount.toString()) * 100);

  try {
    const rzpOrder = await razorpay.orders.create({
      amount: amountInPaise,
      currency: "INR",
      receipt: order.orderNumber,
      notes: {
        orderId: order.id,
        customerId,
        type: "PRODUCT_ORDER",
      },
    });

    await db
      .update(productOrders)
      .set({
        razorpayOrderId: rzpOrder.id,
        updatedAt: new Date(),
      })
      .where(eq(productOrders.id, order.id));

    return rzpOrder;
  } catch (error: any) {
    console.error("Razorpay order creation for product order failed:", error);
    throw new AppError(
      500,
      "PAYMENT_GATEWAY_ERROR",
      "Failed to create payment order"
    );
  }
}

export async function verifyOrderPayment(
  orderId: string,
  customerId: string,
  input: VerifyOrderPaymentInput
) {
  const order = await getProductOrderById(orderId, customerId);

  // Idempotency: If already marked PAID, return existing order without error
  if (order.paymentStatus === "PAID") {
    return order;
  }

  const secret = process.env.RAZORPAY_KEY_SECRET;
  if (!secret) {
    throw new AppError(
      500,
      "CONFIGURATION_ERROR",
      "Razorpay key secret is not configured"
    );
  }

  const generatedSignature = crypto
    .createHmac("sha256", secret)
    .update(`${input.razorpayOrderId}|${input.razorpayPaymentId}`)
    .digest("hex");

  const generatedBuffer = Buffer.from(generatedSignature, "utf-8");
  const providedBuffer = Buffer.from(input.razorpaySignature, "utf-8");

  let isSignatureValid = false;
  if (generatedBuffer.length === providedBuffer.length) {
    isSignatureValid = crypto.timingSafeEqual(generatedBuffer, providedBuffer);
  }

  if (!isSignatureValid) {
    throw new AppError(
      400,
      "INVALID_PAYMENT_SIGNATURE",
      "Payment signature verification failed"
    );
  }

  // Update order status atomically
  const [updatedOrder] = await db
    .update(productOrders)
    .set({
      paymentStatus: "PAID",
      status: "PROCESSING",
      razorpayPaymentId: input.razorpayPaymentId,
      razorpaySignature: input.razorpaySignature,
      paidAt: new Date(),
      updatedAt: new Date(),
    })
    .where(eq(productOrders.id, order.id))
    .returning();

  const refreshedOrder = await db.query.productOrders.findFirst({
    where: eq(productOrders.id, updatedOrder.id),
    with: {
      items: true,
    },
  });

  return refreshedOrder || updatedOrder;
}
