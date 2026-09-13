import { Router } from "express";
import { db } from "../db/index.js";
import { poojas } from "../db/schema/poojas.js";
import { asyncHandler } from "../middleware/async-handler.js";
import { sendSuccess } from "../utils/response.js";
const poojasRouter = Router();
poojasRouter.get("/", asyncHandler(async (_req, res) => {
    const allPoojas = await db.select().from(poojas);
    sendSuccess(res, { poojas: allPoojas });
}));
export default poojasRouter;
//# sourceMappingURL=poojas.routes.js.map