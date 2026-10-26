import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { sendSmsOtp } from "../services/sms.service.js";

describe("SMS Service — Provider Integration & Delivery Verification", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.unstubAllEnvs();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe("when FAST2SMS_API_KEY is NOT configured", () => {
    it("safely falls back to local logging and does NOT invoke external HTTP request", async () => {
      vi.stubEnv("FAST2SMS_API_KEY", "");
      const fetchSpy = vi.spyOn(globalThis, "fetch");

      await expect(sendSmsOtp("+919876543210", "654321")).resolves.toBeUndefined();

      expect(fetchSpy).not.toHaveBeenCalled();
    });
  });

  describe("when FAST2SMS_API_KEY is configured", () => {
    it("sanitizes Indian phone numbers and posts payload to Fast2SMS Bulk V2 endpoint", async () => {
      vi.stubEnv("FAST2SMS_API_KEY", "test_fast2sms_api_key_valid");
      const mockResponse = {
        ok: true,
        status: 200,
        json: vi.fn().mockResolvedValue({
          return: true,
          request_id: "req_sms_123",
          message: ["SMS sent successfully."],
        }),
      };
      const fetchSpy = vi.spyOn(globalThis, "fetch").mockResolvedValue(mockResponse as any);

      await sendSmsOtp("+91 98765 43210", "123456");

      expect(fetchSpy).toHaveBeenCalledWith(
        "https://www.fast2sms.com/dev/bulkV2",
        expect.objectContaining({
          method: "POST",
          headers: {
            authorization: "test_fast2sms_api_key_valid",
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            variables_values: "123456",
            route: "otp",
            numbers: "9876543210",
          }),
        })
      );
    });

    it("handles Fast2SMS rejection (return: false) without crashing dev environment", async () => {
      vi.stubEnv("FAST2SMS_API_KEY", "test_fast2sms_api_key_invalid");
      vi.stubEnv("NODE_ENV", "development");

      const mockResponse = {
        ok: true,
        status: 200,
        json: vi.fn().mockResolvedValue({
          return: false,
          status_code: 411,
          message: "Invalid numbers or account credit exhausted",
        }),
      };
      vi.spyOn(globalThis, "fetch").mockResolvedValue(mockResponse as any);

      await expect(sendSmsOtp("9876543210", "123456")).resolves.toBeUndefined();
    });

    it("handles HTTP error status from Fast2SMS gracefully in non-production", async () => {
      vi.stubEnv("FAST2SMS_API_KEY", "test_fast2sms_api_key");
      vi.stubEnv("NODE_ENV", "development");

      const mockResponse = {
        ok: false,
        status: 403,
        json: vi.fn().mockResolvedValue({ message: "Forbidden" }),
      };
      vi.spyOn(globalThis, "fetch").mockResolvedValue(mockResponse as any);

      await expect(sendSmsOtp("9876543210", "123456")).resolves.toBeUndefined();
    });

    it("throws Error in production when Fast2SMS network fetch fails", async () => {
      vi.stubEnv("FAST2SMS_API_KEY", "test_fast2sms_api_key");
      vi.stubEnv("NODE_ENV", "production");

      vi.spyOn(globalThis, "fetch").mockRejectedValue(new Error("Connection timeout to fast2sms"));

      await expect(sendSmsOtp("9876543210", "123456")).rejects.toThrow("Failed to dispatch SMS OTP");
    });
  });
});
