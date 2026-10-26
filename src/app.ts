import express from "express";
import cors from "cors";
import { randomUUID } from "crypto";

import apiRouter from "./routes/index.js";
import { errorHandler } from "./middleware/error-handler.js";
import { webhookHandler } from "./controllers/payments.controller.js";
import { performReadinessCheck } from "./services/health.service.js";

const app = express();

// Request correlation ID and HTTP security headers middleware
app.use((req, res, next) => {
  const correlationId = (req.headers["x-request-id"] as string) || randomUUID();
  (req as any).id = correlationId;
  res.setHeader("x-request-id", correlationId);
  res.setHeader("X-Content-Type-Options", "nosniff");
  res.setHeader("X-Frame-Options", "DENY");
  res.setHeader("Referrer-Policy", "strict-origin-when-cross-origin");
  next();
});

// Webhook must be parsed as raw before express.json() intercepts it
app.post("/api/v1/payments/webhook", express.raw({ type: "application/json" }), webhookHandler);

app.use(express.json({ limit: "10mb" }));
const corsOrigin = process.env.CORS_ORIGIN || "*";
app.use(
  cors({
    origin: corsOrigin === "*" ? true : corsOrigin.split(",").map((o) => o.trim()),
    credentials: true,
  })
);

app.get("/", (_req, res) => {
  res.status(200).json({
    success: true,
    message: "Welcome to SARV MANGAL API Server 🙏",
    brand: "SARV MANGAL",
    version: "1.0.0",
    documentation: "/api/v1",
  });
});

// Standard health endpoint (backwards compatible)
app.get("/health", (_req, res) => {
  res.json({
    success: true,
    status: "UP",
    timestamp: new Date().toISOString(),
  });
});

// Liveness probe: returns 200 if Node.js event loop is responding
app.get("/health/live", (_req, res) => {
  res.status(200).json({
    status: "ok",
    timestamp: new Date().toISOString(),
    uptimeSeconds: Math.floor(process.uptime()),
  });
});

// Readiness probe: verifies DB, Redis, and external provider configurations
app.get("/health/ready", async (_req, res) => {
  const health = await performReadinessCheck();
  const statusCode = health.status === "down" ? 503 : 200;
  res.status(statusCode).json(health);
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
