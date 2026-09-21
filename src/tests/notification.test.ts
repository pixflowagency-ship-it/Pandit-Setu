import { describe, it, expect, vi, beforeEach } from "vitest";
import { sendPush } from "../services/notification.service.js";

/* ------------------------------------------------------------------ *
 *  Mock DB and Firebase Admin
 * ------------------------------------------------------------------ */
const {
  mockFindFirst,
  mockUpdate,
  mockMessagingSend,
} = vi.hoisted(() => {
  return {
    mockFindFirst: vi.fn(),
    mockUpdate: vi.fn(),
    mockMessagingSend: vi.fn(),
  };
});

vi.mock("../db/index.js", () => ({
  db: {
    query: {
      users: {
        findFirst: (...args: any[]) => mockFindFirst(...args),
      },
    },
    update: (...args: any[]) => mockUpdate(...args),
  },
}));

vi.mock("firebase-admin/app", () => {
  return {
    getApps: vi.fn().mockReturnValue([{ name: "test-app" }]),
    getApp: vi.fn().mockReturnValue({ name: "test-app" }),
    cert: vi.fn(),
    initializeApp: vi.fn(),
  };
});

vi.mock("firebase-admin/messaging", () => {
  return {
    getMessaging: vi.fn().mockReturnValue({
      send: (...args: any[]) => mockMessagingSend(...args),
    }),
  };
});

/* ------------------------------------------------------------------ *
 *  Test Suites
 * ------------------------------------------------------------------ */

describe("Notification Service - sendPush", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  const userId = "user123";

  it("successfully sends a push notification if token exists", async () => {
    mockFindFirst.mockResolvedValue({ fcmToken: "valid_token_123" });
    mockMessagingSend.mockResolvedValue("projects/test/messages/msg_123");

    await sendPush(userId, "Test Title", "Test Body");

    expect(mockFindFirst).toHaveBeenCalled();
    expect(mockMessagingSend).toHaveBeenCalledWith({
      token: "valid_token_123",
      notification: {
        title: "Test Title",
        body: "Test Body",
      },
      data: undefined,
    });
    expect(mockUpdate).not.toHaveBeenCalled();
  });

  it("skips sending if user has no FCM token", async () => {
    mockFindFirst.mockResolvedValue({ fcmToken: null }); // Missing token

    await sendPush(userId, "Test Title", "Test Body");

    expect(mockFindFirst).toHaveBeenCalled();
    expect(mockMessagingSend).not.toHaveBeenCalled();
  });

  it("automatically clears the token if FCM returns invalid-registration-token error", async () => {
    mockFindFirst.mockResolvedValue({ fcmToken: "dead_token" });
    
    // Simulate FCM throwing the specific error code
    const fcmError: any = new Error("Invalid token");
    fcmError.code = "messaging/invalid-registration-token";
    mockMessagingSend.mockRejectedValue(fcmError);

    const updateSetMock = vi.fn().mockReturnValue({
      where: vi.fn().mockResolvedValue(true)
    });
    mockUpdate.mockReturnValue({ set: updateSetMock });

    await sendPush(userId, "Test Title", "Test Body");

    expect(mockMessagingSend).toHaveBeenCalled();
    expect(updateSetMock).toHaveBeenCalledWith({ fcmToken: null }); // Must auto-clear
  });
  
  it("does NOT clear the token for other random errors", async () => {
    mockFindFirst.mockResolvedValue({ fcmToken: "valid_token" });
    
    // Simulate a network failure, NOT an invalid token
    const fcmError: any = new Error("Network timeout");
    fcmError.code = "messaging/internal-error";
    mockMessagingSend.mockRejectedValue(fcmError);

    await sendPush(userId, "Test Title", "Test Body");

    expect(mockMessagingSend).toHaveBeenCalled();
    expect(mockUpdate).not.toHaveBeenCalled(); // Should not clear token
  });
});
