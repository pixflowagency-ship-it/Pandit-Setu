import crypto from "crypto";

const KEY_LEN = 64;

/**
 * Hashes a plaintext password using crypto.scryptSync with a cryptographically random salt.
 * Returns { hash: string, salt: string }
 */
export function hashPassword(password: string): { hash: string; salt: string } {
  const salt = crypto.randomBytes(16).toString("hex");
  const derivedKey = crypto.scryptSync(password, salt, KEY_LEN);
  return {
    hash: derivedKey.toString("hex"),
    salt,
  };
}

/**
 * Constant-time comparison between plaintext password attempt and stored hash+salt.
 */
export function verifyPassword(password: string, hash: string, salt: string): boolean {
  if (!password || !hash || !salt) return false;
  try {
    const derivedKey = crypto.scryptSync(password, salt, KEY_LEN);
    const storedKeyBuffer = Buffer.from(hash, "hex");
    if (derivedKey.length !== storedKeyBuffer.length) {
      return false;
    }
    return crypto.timingSafeEqual(derivedKey, storedKeyBuffer);
  } catch {
    return false;
  }
}
