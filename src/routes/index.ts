import { Router } from "express";
import authRouter from "./auth.routes.js";
import { verifyToken } from "../middleware/verify-token.js";
import { requireRole } from "../middleware/require-role.js";
import { sendSuccess } from "../utils/response.js";
import { asyncHandler } from "../middleware/async-handler.js";
import { usersRouter } from "./users.routes.js";
import productsRouter from "./products.routes.js";
import poojasRouter from "./poojas.routes.js";
import bookingsRouter from "./bookings.routes.js";
import panditsRouter from "./pandits.routes.js";
import templesRouter from "./temples.routes.js";
import paymentsRouter from "./payments.routes.js";
import subscriptionsRouter from "./subscriptions.routes.js";
import trackingRouter from "./tracking.routes.js";
import productOrdersRouter from "./product-orders.routes.js";
import adminRouter from "./admin.routes.js";
import consultationsRouter from "./consultations.routes.js";
import kundliOrdersRouter from "./kundli_orders.routes.js";
import { apiLimiter } from "../middleware/rate-limit.js";

const apiRouter = Router();

apiRouter.use(apiLimiter);

apiRouter.use("/auth", authRouter);

// Mount specialized routers
apiRouter.use("/users", usersRouter);
apiRouter.use("/products", productsRouter);
apiRouter.use("/poojas", poojasRouter);
apiRouter.use("/bookings", bookingsRouter);
apiRouter.use("/pandits", panditsRouter);
apiRouter.use("/temples", templesRouter);
apiRouter.use("/payments", paymentsRouter);
apiRouter.use("/subscriptions", subscriptionsRouter);
apiRouter.use("/tracking", trackingRouter);
apiRouter.use("/product-orders", productOrdersRouter);
apiRouter.use("/consultations", consultationsRouter);
apiRouter.use("/kundli-orders", kundliOrdersRouter);
apiRouter.use("/admin", adminRouter);

apiRouter.get(
  "/me",
  verifyToken,
  asyncHandler((req, res) => {
    sendSuccess(res, { user: req.user });
  }),
);

export default apiRouter;
