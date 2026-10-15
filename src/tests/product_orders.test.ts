import { describe, it, expect, vi, beforeEach } from "vitest";
import request from "supertest";
import app from "../app.js";
import { yajmanToken, signTestToken } from "./helpers/setup.js";
import crypto from "crypto";

const customerId = "00000000-0000-0000-0000-000000000001";
const otherCustomerId = "22222222-2222-2222-2222-222222222222";

const otherCustomerToken = signTestToken({
  id: otherCustomerId,
  phone: "+919876543299",
  role: "YAJMAN",
});

const productId1 = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";
const productId2 = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb";
const inactiveProductId = "cccccccc-cccc-cccc-cccc-cccccccccccc";
const missingProductId = "dddddddd-dddd-dddd-dddd-dddddddddddd";
const orderId1 = "11111111-1111-1111-1111-111111111111";

/* ------------------------------------------------------------------ *
 *  Mock DB, Razorpay, Redis
 * ------------------------------------------------------------------ */
const {
  mockFindFirstOrder,
  mockFindManyOrders,
  mockSelectProducts,
  mockCountOrders,
  mockInsertOrder,
  mockInsertItems,
  mockUpdateOrder,
  mockRazorpayCreate,
} = vi.hoisted(() => {
  return {
    mockFindFirstOrder: vi.fn(),
    mockFindManyOrders: vi.fn(),
    mockSelectProducts: vi.fn(),
    mockCountOrders: vi.fn(),
    mockInsertOrder: vi.fn(),
    mockInsertItems: vi.fn(),
    mockUpdateOrder: vi.fn(),
    mockRazorpayCreate: vi.fn(),
  };
});

vi.mock("../db/index.js", () => {
  const transactionMock = async (cb: any) => {
    return cb({
      select: () => ({
        from: () => ({
          where: () => mockSelectProducts(),
        }),
      }),
      insert: (table: any) => ({
        values: (data: any) => {
          if (table?.orderNumber || table?._?.name === "product_orders") {
            return {
              returning: () => mockInsertOrder(data),
            };
          }
          return {
            returning: () => mockInsertItems(data),
          };
        },
      }),
    });
  };

  return {
    db: {
      transaction: transactionMock,
      query: {
        productOrders: {
          findFirst: (...args: any[]) => mockFindFirstOrder(...args),
          findMany: (...args: any[]) => mockFindManyOrders(...args),
        },
      },
      select: () => ({
        from: () => ({
          where: () => mockCountOrders(),
        }),
      }),
      update: () => ({
        set: (data: any) => ({
          where: () => ({
            returning: () => mockUpdateOrder(data),
          }),
        }),
      }),
    },
    productOrders: {
      id: "id",
      orderNumber: "order_number",
      customerId: "customer_id",
      status: "status",
      paymentStatus: "payment_status",
      razorpayOrderId: "razorpay_order_id",
      createdAt: "created_at",
      _: { name: "product_orders" },
    },
    productOrderItems: {
      id: "id",
      orderId: "order_id",
      productId: "product_id",
    },
    products: {
      id: "id",
      price: "price",
      isActive: "is_active",
    },
  };
});

vi.mock("razorpay", () => {
  return {
    default: vi.fn().mockImplementation(function () {
      return {
        orders: {
          create: (...args: any[]) => mockRazorpayCreate(...args),
        },
      };
    }),
  };
});

describe("SARV MANGAL Stage 3: Store Cart, Checkout & Product Orders", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    process.env.RAZORPAY_KEY_ID = "rzp_test_key_dummy";
    process.env.RAZORPAY_KEY_SECRET = "rzp_test_secret_key_1234567890";
  });

  /* ------------------------------------------------------------------ *
   *  POST /api/v1/product-orders (Create Order)
   * ------------------------------------------------------------------ */
  describe("POST /api/v1/product-orders (Create Order)", () => {
    const validPayload = {
      items: [
        { productId: productId1, quantity: 2 },
        { productId: productId2, quantity: 1 },
      ],
      shippingName: "Anand Sharma",
      shippingPhone: "9876543210",
      shippingAddress: "Flat 402, Shanti Kunj, Sector 62",
      shippingCity: "Noida",
      shippingPincode: "201309",
      shippingNotes: "Leave at door if not available",
    };

    it("201 – creates order with server-calculated prices and correct totals", async () => {
      // Mock product lookup: Product 1 = ₹150, Product 2 = ₹300.
      // Subtotal = 2 * 150 + 1 * 300 = 600.
      // Since subtotal >= 500, deliveryCharge = 0. Total = 600.
      mockSelectProducts.mockResolvedValueOnce([
        {
          id: productId1,
          productId: "SKU-P1",
          name: "Pure Ganga Jal 500ml",
          price: "150.00",
          isActive: true,
          status: "Active",
        },
        {
          id: productId2,
          productId: "SKU-P2",
          name: "Premium Hawan Samagri 1kg",
          price: "300.00",
          isActive: true,
          status: "Active",
        },
      ]);

      mockInsertOrder.mockImplementationOnce((data) => [
        {
          id: orderId1,
          ...data,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        },
      ]);

      mockInsertItems.mockImplementationOnce((items) =>
        items.map((i: any, idx: number) => ({ id: `item-id-${idx}`, ...i }))
      );

      const res = await request(app)
        .post("/api/v1/product-orders")
        .set("Authorization", `Bearer ${yajmanToken}`)
        .send(validPayload);

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.order.id).toBe(orderId1);
      expect(res.body.data.order.subtotal).toBe("600.00");
      expect(res.body.data.order.deliveryCharge).toBe("0.00");
      expect(res.body.data.order.totalAmount).toBe("600.00");
      expect(res.body.data.order.status).toBe("PENDING");
      expect(res.body.data.order.paymentStatus).toBe("PENDING");
      expect(res.body.data.order.items.length).toBe(2);
    });

    it("201 – adds ₹50 standard delivery charge when subtotal is below ₹500", async () => {
      // Product 1 only = 2 * 150 = 300 (< 500) -> deliveryCharge = 50. Total = 350.
      mockSelectProducts.mockResolvedValueOnce([
        {
          id: productId1,
          productId: "SKU-P1",
          name: "Pure Ganga Jal 500ml",
          price: "150.00",
          isActive: true,
          status: "Active",
        },
      ]);

      mockInsertOrder.mockImplementationOnce((data) => [
        {
          id: orderId1,
          ...data,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        },
      ]);
      mockInsertItems.mockImplementationOnce((items) => items);

      const res = await request(app)
        .post("/api/v1/product-orders")
        .set("Authorization", `Bearer ${yajmanToken}`)
        .send({
          ...validPayload,
          items: [{ productId: productId1, quantity: 2 }],
        });

      expect(res.status).toBe(201);
      expect(res.body.data.order.subtotal).toBe("300.00");
      expect(res.body.data.order.deliveryCharge).toBe("50.00");
      expect(res.body.data.order.totalAmount).toBe("350.00");
    });

    it("404 – rejects order when a requested product does not exist", async () => {
      mockSelectProducts.mockResolvedValueOnce([
        {
          id: productId1,
          price: "150.00",
          isActive: true,
          status: "Active",
        },
      ]); // Only 1 of 2 found

      const res = await request(app)
        .post("/api/v1/product-orders")
        .set("Authorization", `Bearer ${yajmanToken}`)
        .send({
          ...validPayload,
          items: [
            { productId: productId1, quantity: 1 },
            { productId: missingProductId, quantity: 1 },
          ],
        });

      expect(res.status).toBe(404);
      expect(res.body.error.code).toBe("PRODUCT_NOT_FOUND");
    });

    it("400 – rejects order when a product is inactive or unavailable", async () => {
      mockSelectProducts.mockResolvedValueOnce([
        {
          id: inactiveProductId,
          name: "Rare Rudraksha Mala",
          price: "1500.00",
          isActive: false,
          status: "Out of Stock",
        },
      ]);

      const res = await request(app)
        .post("/api/v1/product-orders")
        .set("Authorization", `Bearer ${yajmanToken}`)
        .send({
          ...validPayload,
          items: [{ productId: inactiveProductId, quantity: 1 }],
        });

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe("INACTIVE_PRODUCT");
    });

    it("400 – rejects invalid quantity (0, negative, or > 100)", async () => {
      const res1 = await request(app)
        .post("/api/v1/product-orders")
        .set("Authorization", `Bearer ${yajmanToken}`)
        .send({
          ...validPayload,
          items: [{ productId: productId1, quantity: 0 }],
        });
      expect(res1.status).toBe(400);

      const res2 = await request(app)
        .post("/api/v1/product-orders")
        .set("Authorization", `Bearer ${yajmanToken}`)
        .send({
          ...validPayload,
          items: [{ productId: productId1, quantity: 101 }],
        });
      expect(res2.status).toBe(400);
    });

    it("400 – rejects missing required shipping address fields", async () => {
      const res = await request(app)
        .post("/api/v1/product-orders")
        .set("Authorization", `Bearer ${yajmanToken}`)
        .send({
          items: [{ productId: productId1, quantity: 1 }],
          shippingName: "Anand",
          // missing shippingPhone, address, city, pincode
        });

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe("VALIDATION_ERROR");
    });

    it("401 – rejects unauthenticated order placement", async () => {
      const res = await request(app)
        .post("/api/v1/product-orders")
        .send(validPayload);

      expect(res.status).toBe(401);
    });
  });

  /* ------------------------------------------------------------------ *
   *  GET /api/v1/product-orders (List Orders)
   * ------------------------------------------------------------------ */
  describe("GET /api/v1/product-orders (List Orders)", () => {
    it("200 – returns customer orders with pagination", async () => {
      mockFindManyOrders.mockResolvedValueOnce([
        {
          id: orderId1,
          orderNumber: "SM-ORD-1",
          customerId,
          totalAmount: "600.00",
          status: "PENDING",
          paymentStatus: "PENDING",
          items: [{ id: "i-1", productName: "Pure Ganga Jal", quantity: 2 }],
        },
      ]);
      mockCountOrders.mockResolvedValueOnce([{ total: 1 }]);

      const res = await request(app)
        .get("/api/v1/product-orders?page=1&limit=20")
        .set("Authorization", `Bearer ${yajmanToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.orders.length).toBe(1);
      expect(res.body.data.pagination.total).toBe(1);
      expect(res.body.data.pagination.page).toBe(1);
    });

    it("401 – rejects unauthenticated order listing", async () => {
      const res = await request(app).get("/api/v1/product-orders");
      expect(res.status).toBe(401);
    });
  });

  /* ------------------------------------------------------------------ *
   *  GET /api/v1/product-orders/:id (Get Order by ID)
   * ------------------------------------------------------------------ */
  describe("GET /api/v1/product-orders/:id", () => {
    it("200 – returns order details to the owner", async () => {
      mockFindFirstOrder.mockResolvedValueOnce({
        id: orderId1,
        customerId,
        orderNumber: "SM-ORD-1",
        totalAmount: "600.00",
        items: [{ id: "i-1", productName: "Pure Ganga Jal", quantity: 2 }],
      });

      const res = await request(app)
        .get(`/api/v1/product-orders/${orderId1}`)
        .set("Authorization", `Bearer ${yajmanToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.order.id).toBe(orderId1);
    });

    it("403 – rejects access when requested by an unrelated customer", async () => {
      mockFindFirstOrder.mockResolvedValueOnce({
        id: orderId1,
        customerId, // Owned by customerId, requested by otherCustomerId
        orderNumber: "SM-ORD-1",
      });

      const res = await request(app)
        .get(`/api/v1/product-orders/${orderId1}`)
        .set("Authorization", `Bearer ${otherCustomerToken}`);

      expect(res.status).toBe(403);
      expect(res.body.error.code).toBe("FORBIDDEN");
    });

    it("404 – returns not found for non-existent order ID", async () => {
      mockFindFirstOrder.mockResolvedValueOnce(null);

      const res = await request(app)
        .get(`/api/v1/product-orders/${orderId1}`)
        .set("Authorization", `Bearer ${yajmanToken}`);

      expect(res.status).toBe(404);
    });
  });

  /* ------------------------------------------------------------------ *
   *  POST /api/v1/product-orders/:id/create-payment
   * ------------------------------------------------------------------ */
  describe("POST /api/v1/product-orders/:id/create-payment", () => {
    it("200 – creates Razorpay order with server-controlled amount in paise", async () => {
      mockFindFirstOrder.mockResolvedValueOnce({
        id: orderId1,
        customerId,
        orderNumber: "SM-ORD-1",
        totalAmount: "600.00",
        paymentStatus: "PENDING",
        razorpayOrderId: null,
      });

      mockRazorpayCreate.mockResolvedValueOnce({
        id: "order_rzp_mock_product_123",
        amount: 60000,
        currency: "INR",
        receipt: "SM-ORD-1",
      });

      mockUpdateOrder.mockResolvedValueOnce([{ id: orderId1 }]);

      const res = await request(app)
        .post(`/api/v1/product-orders/${orderId1}/create-payment`)
        .set("Authorization", `Bearer ${yajmanToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.paymentOrder.id).toBe("order_rzp_mock_product_123");
      expect(res.body.data.paymentOrder.amount).toBe(60000);
    });

    it("200 – returns existing Razorpay order idempotently without re-creating", async () => {
      mockFindFirstOrder.mockResolvedValueOnce({
        id: orderId1,
        customerId,
        orderNumber: "SM-ORD-1",
        totalAmount: "600.00",
        paymentStatus: "PENDING",
        razorpayOrderId: "order_rzp_existing_456",
      });

      const res = await request(app)
        .post(`/api/v1/product-orders/${orderId1}/create-payment`)
        .set("Authorization", `Bearer ${yajmanToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.paymentOrder.id).toBe("order_rzp_existing_456");
      expect(mockRazorpayCreate).not.toHaveBeenCalled();
    });

    it("400 – rejects payment order creation if order is already marked PAID", async () => {
      mockFindFirstOrder.mockResolvedValueOnce({
        id: orderId1,
        customerId,
        orderNumber: "SM-ORD-1",
        totalAmount: "600.00",
        paymentStatus: "PAID",
      });

      const res = await request(app)
        .post(`/api/v1/product-orders/${orderId1}/create-payment`)
        .set("Authorization", `Bearer ${yajmanToken}`);

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe("ORDER_ALREADY_PAID");
    });
  });

  /* ------------------------------------------------------------------ *
   *  POST /api/v1/product-orders/:id/verify-payment
   * ------------------------------------------------------------------ */
  describe("POST /api/v1/product-orders/:id/verify-payment", () => {
    it("200 – verifies valid HMAC-SHA256 signature and updates order to PAID / PROCESSING", async () => {
      const razorpayOrderId = "order_rzp_mock_product_123";
      const razorpayPaymentId = "pay_rzp_mock_product_789";

      const validSignature = crypto
        .createHmac("sha256", process.env.RAZORPAY_KEY_SECRET!)
        .update(`${razorpayOrderId}|${razorpayPaymentId}`)
        .digest("hex");

      mockFindFirstOrder
        .mockResolvedValueOnce({
          id: orderId1,
          customerId,
          orderNumber: "SM-ORD-1",
          totalAmount: "600.00",
          paymentStatus: "PENDING",
          razorpayOrderId,
        })
        .mockResolvedValueOnce({
          id: orderId1,
          customerId,
          orderNumber: "SM-ORD-1",
          paymentStatus: "PAID",
          status: "PROCESSING",
          razorpayPaymentId,
          razorpaySignature: validSignature,
        });

      mockUpdateOrder.mockResolvedValueOnce([{ id: orderId1 }]);

      const res = await request(app)
        .post(`/api/v1/product-orders/${orderId1}/verify-payment`)
        .set("Authorization", `Bearer ${yajmanToken}`)
        .send({
          razorpayOrderId,
          razorpayPaymentId,
          razorpaySignature: validSignature,
        });

      expect(res.status).toBe(200);
      expect(res.body.data.order.paymentStatus).toBe("PAID");
      expect(res.body.data.order.status).toBe("PROCESSING");
    });

    it("400 – rejects invalid or tampered payment signature", async () => {
      const razorpayOrderId = "order_rzp_mock_product_123";
      const razorpayPaymentId = "pay_rzp_mock_product_789";
      const forgedSignature = "invalid_forged_signature_1234567890abcdef";

      mockFindFirstOrder.mockResolvedValueOnce({
        id: orderId1,
        customerId,
        orderNumber: "SM-ORD-1",
        totalAmount: "600.00",
        paymentStatus: "PENDING",
        razorpayOrderId,
      });

      const res = await request(app)
        .post(`/api/v1/product-orders/${orderId1}/verify-payment`)
        .set("Authorization", `Bearer ${yajmanToken}`)
        .send({
          razorpayOrderId,
          razorpayPaymentId,
          razorpaySignature: forgedSignature,
        });

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe("INVALID_PAYMENT_SIGNATURE");
    });

    it("200 – idempotently returns order if already verified and marked PAID", async () => {
      mockFindFirstOrder.mockResolvedValueOnce({
        id: orderId1,
        customerId,
        orderNumber: "SM-ORD-1",
        paymentStatus: "PAID",
        status: "PROCESSING",
      });

      const res = await request(app)
        .post(`/api/v1/product-orders/${orderId1}/verify-payment`)
        .set("Authorization", `Bearer ${yajmanToken}`)
        .send({
          razorpayOrderId: "order_123",
          razorpayPaymentId: "pay_123",
          razorpaySignature: "sig_123",
        });

      expect(res.status).toBe(200);
      expect(res.body.data.order.paymentStatus).toBe("PAID");
      expect(mockUpdateOrder).not.toHaveBeenCalled();
    });
  });
});
