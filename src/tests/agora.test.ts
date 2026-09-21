import { describe, it, expect, vi, beforeEach } from "vitest";
import { generateRtcToken } from "../services/agora.service.js";
import { RtcRole, RtcTokenBuilder } from "agora-token";
import { AppError } from "../utils/api-error.js";

// Mock agora-token
vi.mock("agora-token", () => ({
  RtcRole: {
    PUBLISHER: 1,
    SUBSCRIBER: 2,
  },
  RtcTokenBuilder: {
    buildTokenWithUid: vi.fn().mockReturnValue("mocked_rtc_token_123"),
  },
}));

describe("Agora Service", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("throws AppError if AGORA_APP_ID or AGORA_APP_CERTIFICATE are missing", () => {
    vi.stubEnv("AGORA_APP_ID", "");
    vi.stubEnv("AGORA_APP_CERTIFICATE", "");

    expect(() => generateRtcToken("channel_1", RtcRole.PUBLISHER, 1234567890)).toThrow(AppError);
    expect(() => generateRtcToken("channel_1", RtcRole.PUBLISHER, 1234567890)).toThrow(/Agora credentials are not configured/);
  });

  it("successfully generates a token when credentials are present", () => {
    vi.stubEnv("AGORA_APP_ID", "test_app_id");
    vi.stubEnv("AGORA_APP_CERTIFICATE", "test_cert");

    const token = generateRtcToken("booking_123", RtcRole.PUBLISHER, 1600000000);

    expect(token).toBe("mocked_rtc_token_123");
    expect(RtcTokenBuilder.buildTokenWithUid).toHaveBeenCalledWith(
      "test_app_id",
      "test_cert",
      "booking_123",
      0, // default uid
      RtcRole.PUBLISHER,
      1600000000,
      1600000000
    );
  });
});
