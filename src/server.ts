import dotenv from "dotenv";
dotenv.config();

import app from "./app.js";
import { env } from "./config/env.js";
import pool, { testDbConnection } from "./config/db.js";
import { closeRedis } from "./config/redis.js";
import { logger } from "./utils/logger.js";

import http from "http";
import { initializeSocket, closeSocket } from "./services/realtime.service.js";

async function startServer() {
  await testDbConnection();
  
  const httpServer = http.createServer(app);
  
  // Initialize WebSocket Server
  initializeSocket(httpServer);

  const host = process.env.HOST || "0.0.0.0";
  const server = httpServer.listen(env.port, host, () => {
    logger.info(`SARV MANGAL API running on http://${host === "0.0.0.0" ? "localhost" : host}:${env.port}`);
  });

  let isShuttingDown = false;
  async function gracefulShutdown(signal: string) {
    if (isShuttingDown) return;
    isShuttingDown = true;
    logger.info({ signal }, "Graceful shutdown initiated...");

    const forceExitTimeout = setTimeout(() => {
      logger.error("Graceful shutdown timed out (10s), forcing process exit.");
      process.exit(1);
    }, 10000);
    forceExitTimeout.unref();

    try {
      // 1. Stop accepting new HTTP requests
      await new Promise<void>((resolve) => {
        server.close(() => {
          logger.info("HTTP server closed.");
          resolve();
        });
      });

      // 2. Close Socket.IO connections
      await closeSocket();
      logger.info("Socket.IO server closed.");

      // 3. Close Redis connection
      await closeRedis();
      logger.info("Redis connection closed.");

      // 4. Close Postgres pool
      await pool.end();
      logger.info("Database pool closed.");

      logger.info("Graceful shutdown completed successfully.");
      process.exit(0);
    } catch (err) {
      logger.error({ err }, "Error during graceful shutdown");
      process.exit(1);
    }
  }

  process.on("SIGTERM", () => gracefulShutdown("SIGTERM"));
  process.on("SIGINT", () => gracefulShutdown("SIGINT"));

  process.on("unhandledRejection", (reason) => {
    logger.error({ reason }, "Unhandled Promise Rejection detected");
  });

  process.on("uncaughtException", (error) => {
    logger.fatal({ err: error }, "Uncaught Exception detected");
    gracefulShutdown("uncaughtException");
  });
}

startServer();
