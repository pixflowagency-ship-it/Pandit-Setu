import express from "express";
import cors from "cors";
// Using cors package for CORS handling
import apiRouter from "./routes/index.js";
import { errorHandler } from "./middleware/error-handler.js";
const app = express();
app.use(express.json());
app.use(cors({ origin: '*', credentials: true }));
app.get("/", (_req, res) => {
    res.status(200).json({
        success: true,
        message: "Welcome to Poojapaath API Server 🙏",
        version: "1.0.0",
        documentation: "/api/v1",
    });
});
app.get("/health", (_req, res) => {
    res.json({
        success: true,
        status: "UP",
        timestamp: new Date().toISOString(),
    });
});
app.use("/api/v1", apiRouter);
app.use((_req, res) => {
    res.status(404).json({
        success: false,
        error: {
            code: "NOT_FOUND",
            message: "The requested resource was not found",
        },
    });
});
app.use(errorHandler);
export default app;
//# sourceMappingURL=app.js.map