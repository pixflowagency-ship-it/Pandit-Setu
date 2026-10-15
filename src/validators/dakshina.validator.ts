import { z } from "zod";

export const collectCashDakshinaSchema = z.object({
  amount: z.number().positive().min(1).max(1000000).optional(),
  notes: z.string().max(500).optional(),
  completeBooking: z.boolean().optional().default(true),
});

export const createDakshinaOrderSchema = z.object({
  amount: z.number().positive().min(1).max(1000000).optional(),
});

export const verifyDakshinaPaymentSchema = z.object({
  orderId: z.string().min(1, "Order ID is required"),
  paymentId: z.string().min(1, "Payment ID is required"),
  signature: z.string().min(1, "Signature is required"),
  completeBooking: z.boolean().optional().default(true),
});

export type CollectCashDakshinaInput = z.infer<typeof collectCashDakshinaSchema>;
export type CreateDakshinaOrderInput = z.infer<typeof createDakshinaOrderSchema>;
export type VerifyDakshinaPaymentInput = z.infer<typeof verifyDakshinaPaymentSchema>;
