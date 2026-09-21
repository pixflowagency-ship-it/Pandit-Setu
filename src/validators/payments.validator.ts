import { z } from "zod";

export const createOrderSchema = z
  .object({
    bookingId: z.string().uuid("bookingId must be a valid UUID"),
  })
  .strict();

export const verifyPaymentSchema = z
  .object({
    orderId: z.string().min(1, "orderId is required"),
    paymentId: z.string().min(1, "paymentId is required"),
    signature: z.string().min(1, "signature is required"),
  })
  .strict();

export type CreateOrderInput = z.infer<typeof createOrderSchema>;
export type VerifyPaymentInput = z.infer<typeof verifyPaymentSchema>;
