import { Server as SocketIOServer, Socket } from "socket.io";
import { createAdapter } from "@socket.io/redis-adapter";
import { Redis } from "ioredis";
import jwt from "jsonwebtoken";
import type { Server as HttpServer } from "http";
import { db } from "../db/index.js";
import { bookings } from "../db/schema/bookings.js";
import { eq } from "drizzle-orm";

let io: SocketIOServer;

export const socketAuthMiddleware = (socket: any, next: (err?: Error) => void) => {
  const token = socket.handshake.auth?.token;
  
  if (!token) {
    return next(new Error("Authentication error: Token missing"));
  }

  const secret = process.env.JWT_SECRET;
  if (!secret) {
    return next(new Error("Internal Server Error"));
  }

  jwt.verify(token, secret, (err: any, decoded: any) => {
    if (err || !decoded) {
      return next(new Error("Authentication error: Invalid token"));
    }
    
    socket.data.user = decoded; // { id, role, iat, exp }
    next();
  });
};

export const initializeSocket = (httpServer: HttpServer) => {
  io = new SocketIOServer(httpServer, {
    cors: {
      origin: "*", // Adjust for production
      methods: ["GET", "POST"],
    },
  });

  const redisUrl = process.env.REDIS_URL || "redis://localhost:6379";
  try {
    const pubClient = new Redis(redisUrl, {
      lazyConnect: true,
      maxRetriesPerRequest: null,
      retryStrategy(times) {
        if (times > 3) return null;
        return Math.min(times * 200, 2000);
      },
    });
    const subClient = pubClient.duplicate();

    pubClient.on("error", (err) => {
      // Non-fatal error handling for Redis pub client
    });
    subClient.on("error", (err) => {
      // Non-fatal error handling for Redis sub client
    });

    if (typeof pubClient.connect === "function") {
      pubClient.connect().then(() => {
        if (typeof subClient.connect === "function") {
          return subClient.connect();
        }
      }).then(() => {
        io.adapter(createAdapter(pubClient, subClient));
        console.log("Socket.IO Redis adapter connected");
      }).catch((err) => {
        console.warn("Socket.IO Redis adapter connection failed, using in-memory adapter");
      });
    } else {
      io.adapter(createAdapter(pubClient, subClient));
    }
  } catch (err: any) {
    console.warn("Socket.IO Redis adapter initialization failed, using in-memory adapter:", err?.message);
  }

  // Authentication Middleware
  io.use(socketAuthMiddleware);

  io.on("connection", (socket: Socket) => {
    console.log(`Socket connected: ${socket.id} (User: ${socket.data.user.id}, Role: ${socket.data.user.role})`);

    // Authenticated private rooms for targeted dispatches and notifications
    socket.join(`user:${socket.data.user.id}`);
    if (socket.data.user.role === "PANDIT") {
      socket.join(`pandit:user:${socket.data.user.id}`);
    }

    // Pandit emitting location updates
    socket.on("pandit:location-update", async (data: { bookingId: string; lat: number; lng: number }) => {
      if (socket.data.user.role !== "PANDIT") return;

      const { bookingId, lat, lng } = data;
      if (!bookingId || !lat || !lng) return;

      // Delegate to shared tracking service
      const { processLocationUpdate } = await import("./tracking.service.js");
      await processLocationUpdate(socket.data.user.id, bookingId, lat, lng).catch(console.error);
    });

    // Yajman subscribing to track the Pandit (backward compatibility)
    socket.on("yajman:track-pandit", async (data: { bookingId: string }, callback: (res: any) => void) => {
      try {
        const { bookingId } = data;
        if (!bookingId) {
          if (callback) callback({ error: "bookingId is required" });
          return;
        }

        // Verify Ownership
        const booking = await db.query.bookings.findFirst({
          where: eq(bookings.id, bookingId),
          columns: { yajmanId: true },
        });

        if (!booking || booking.yajmanId !== socket.data.user.id) {
          if (callback) callback({ error: "Unauthorized: You do not own this booking" });
          return;
        }

        socket.join(`booking:${bookingId}`);
        console.log(`Yajman ${socket.data.user.id} joined room booking:${bookingId}`);
        if (callback) callback({ success: true });
      } catch (error) {
        console.error("Error in yajman:track-pandit:", error);
        if (callback) callback({ error: "Internal server error" });
      }
    });

    // Authorized booking participants (Yajman or Pandit) subscribing to real-time status updates
    socket.on("booking:subscribe", async (data: { bookingId: string }, callback: (res: any) => void) => {
      try {
        const { bookingId } = data;
        if (!bookingId) {
          if (callback) callback({ error: "bookingId is required" });
          return;
        }

        const booking = await db.query.bookings.findFirst({
          where: eq(bookings.id, bookingId),
          columns: { yajmanId: true, panditId: true },
        });

        if (!booking || (booking.yajmanId !== socket.data.user.id && booking.panditId !== socket.data.user.id)) {
          if (callback) callback({ error: "Unauthorized: You are not a participant in this booking" });
          return;
        }

        socket.join(`booking:${bookingId}`);
        console.log(`User ${socket.data.user.id} joined room booking:${bookingId}`);
        if (callback) callback({ success: true, bookingId });
      } catch (error) {
        console.error("Error in booking:subscribe:", error);
        if (callback) callback({ error: "Internal server error" });
      }
    });

    socket.on("disconnect", () => {
      console.log(`Socket disconnected: ${socket.id}`);
    });
  });
};

export const getIO = () => {
  if (!io) {
    throw new Error("Socket.io is not initialized");
  }
  return io;
};
