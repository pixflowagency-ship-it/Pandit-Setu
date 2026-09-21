import { describe, it, expect, vi, beforeEach } from "vitest";
import { Server as SocketIOServer } from "socket.io";
import { initializeSocket, getIO, socketAuthMiddleware } from "../services/realtime.service.js";
import type { Server as HttpServer } from "http";
import jwt from "jsonwebtoken";

const { mockFindFirst } = vi.hoisted(() => ({
  mockFindFirst: vi.fn(),
}));

vi.mock("../db/index.js", () => ({
  db: {
    query: {
      bookings: {
        findFirst: (...args: any[]) => mockFindFirst(...args),
      },
    },
  },
}));

vi.mock("ioredis", () => {
  return {
    Redis: class Redis {
      duplicate() {
        return this;
      }
      on() {}
      psubscribe() {}
      punsubscribe() {}
      subscribe() {}
      unsubscribe() {}
      publish() {}
    },
  };
});

describe("Realtime Service (Socket.io)", () => {
  let io: SocketIOServer;
  
  beforeEach(() => {
    vi.clearAllMocks();
    vi.stubEnv("JWT_SECRET", "test_secret");
    
    // Quick mock of HttpServer
    const httpServer = {} as HttpServer;
    
    // Actually initialize it
    initializeSocket(httpServer);
    io = getIO();
  });

  it("fails connection if no token is provided", () => {
    const next = vi.fn();
    const socket = {
      handshake: { auth: {} },
    } as any;

    socketAuthMiddleware(socket, next);

    expect(next).toHaveBeenCalledWith(expect.any(Error));
    expect(next.mock.calls[0][0].message).toContain("Token missing");
  });

  it("authenticates connection and decodes JWT successfully", () => {
    const next = vi.fn();
    const validToken = jwt.sign({ id: "yajman_123", role: "YAJMAN" }, "test_secret");
    
    const socket = {
      handshake: { auth: { token: validToken } },
      data: {},
    } as any;

    socketAuthMiddleware(socket, next);

    expect(next).toHaveBeenCalledWith(); // Called with no args on success
    expect(socket.data.user.id).toBe("yajman_123");
    expect(socket.data.user.role).toBe("YAJMAN");
  });

  // We are not spinning up a full mock client/server network in vitest to test 
  // the exact event bus due to complexity, but we can verify the service initializes.
  it("getIO() returns the initialized instance", () => {
    expect(getIO()).toBeDefined();
    expect(getIO()).toBe(io);
  });
});
