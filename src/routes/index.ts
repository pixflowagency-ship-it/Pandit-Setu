import { Router } from "express";
import authRouter from "./auth.routes.js";
import { verifyToken } from "../middleware/verify-token.js";
import { requireRole } from "../middleware/require-role.js";
import { sendSuccess } from "../utils/response.js";
import { asyncHandler } from "../middleware/async-handler.js";
import productsRouter from "./products.routes.js";
import { usersRouter } from "./users.routes.js";
import poojasRouter from "./poojas.routes.js";

const apiRouter = Router();

apiRouter.use("/auth", authRouter);
apiRouter.use("/users", usersRouter);
apiRouter.use("/products", productsRouter);
apiRouter.use("/poojas", poojasRouter);

apiRouter.get(
  "/me",
  verifyToken,
  asyncHandler((req, res) => {
    sendSuccess(res, { user: req.user });
  }),
);

apiRouter.get(
  "/admin/health",
  verifyToken,
  requireRole(["ADMIN"]),
  asyncHandler((_req, res) => {
    sendSuccess(res, { status: "ok" });
  }),
);

export default apiRouter;
