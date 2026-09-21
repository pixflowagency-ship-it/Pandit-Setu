import { RtcTokenBuilder, RtcRole } from "agora-token";
import { AppError } from "../utils/api-error.js";

/**
 * Generates an Agora RTC token for a given channel and role.
 * Validates environment variables before generation.
 * @param channelName The unique channel name (e.g. 'booking_123')
 * @param role The role (PUBLISHER or SUBSCRIBER)
 * @param expireTimestamp The Unix timestamp (in seconds) when the token expires
 * @param uid The user ID (0 for random assignment)
 */
export function generateRtcToken(
  channelName: string,
  role: number = RtcRole.PUBLISHER,
  expireTimestamp: number,
  uid: number = 0
): string {
  const appId = process.env.AGORA_APP_ID;
  const appCertificate = process.env.AGORA_APP_CERTIFICATE;

  if (!appId || !appCertificate) {
    throw new AppError(500, "INTERNAL_ERROR", "Agora credentials are not configured on the server");
  }

  // Tokens require time in seconds
  return RtcTokenBuilder.buildTokenWithUid(
    appId,
    appCertificate,
    channelName,
    uid,
    role,
    expireTimestamp,
    expireTimestamp
  );
}
