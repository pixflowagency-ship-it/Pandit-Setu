import { z } from "zod";

export const orderItemSchema = z.object({
  productId: z.string().uuid("Invalid product ID"),
  quantity: z.number().int().min(1, "Quantity must be at least 1").max(100, "Quantity cannot exceed 100"),
});

export const createProductOrderSchema = z.object({
  items: z.array(orderItemSchema).min(1, "Order must contain at least 1 item").max(50, "Order cannot contain more than 50 items"),
  shippingName: z.string().trim().min(2, "Name must be at least 2 characters").max(255),
  shippingPhone: z.string().trim().min(10, "Phone number must be at least 10 digits").max(20),
  shippingAddress: z.string().trim().min(5, "Address must be at least 5 characters").max(1000),
  shippingCity: z.string().trim().min(2, "City must be at least 2 characters").max(100),
  shippingPincode: z.string().trim().min(4, "Pincode must be at least 4 digits").max(20),
  shippingNotes: z.string().trim().max(1000).optional(),
});

export const listProductOrdersQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(20),
  status: z.enum(["PENDING", "PROCESSING", "SHIPPED", "DELIVERED", "CANCELLED"]).optional(),
});

export const getOrderByIdParamsSchema = z.object({
  id: z.string().uuid("Invalid order ID format"),
});

export const verifyOrderPaymentSchema = z.object({
  razorpayOrderId: z.string().trim().min(1, "Razorpay order ID is required"),
  razorpayPaymentId: z.string().trim().min(1, "Razorpay payment ID is required"),
  razorpaySignature: z.string().trim().min(1, "Razorpay signature is required"),
});

export type CreateProductOrderInput = z.infer<typeof createProductOrderSchema>;
export type ListProductOrdersQuery = z.infer<typeof listProductOrdersQuerySchema>;
export type VerifyOrderPaymentInput = z.infer<typeof verifyOrderPaymentSchema>;
