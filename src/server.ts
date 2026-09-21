import dotenv from "dotenv";
dotenv.config();

import app from "./app.js";
import { env } from "./config/env.js";
import { testDbConnection } from "./config/db.js";
import { logger } from "./utils/logger.js";

import http from "http";
import { initializeSocket } from "./services/realtime.service.js";

async function startServer() {
  await testDbConnection();
  
  const httpServer = http.createServer(app);
  
  // Initialize WebSocket Server
  initializeSocket(httpServer);

  httpServer.listen(env.port, () => {
    logger.info(`Poojapaath API running on http://localhost:${env.port}`);
  });
}

startServer();
