import { initializeApp, getApps, getApp, cert } from "firebase-admin/app";
import { getMessaging, type Message } from "firebase-admin/messaging";
import { db } from "../db/index.js";
import { users } from "../db/schema/users.js";
import { eq } from "drizzle-orm";

const initializeFirebaseAdmin = () => {
  if (getApps().length > 0) {
    return getApp();
  }

  try {
    const base64ServiceAccount = process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;
    
    if (base64ServiceAccount) {
      const serviceAccountJson = Buffer.from(base64ServiceAccount, "base64").toString("utf-8");
      const serviceAccount = JSON.parse(serviceAccountJson);

      return initializeApp({
        credential: cert(serviceAccount),
      });
    }

    // Fallback to local path for dev
    const localPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
    if (localPath) {
      return initializeApp({
        credential: cert(localPath),
      });
    }

    console.warn("Firebase Admin not initialized: Missing FIREBASE_SERVICE_ACCOUNT_BASE64 or FIREBASE_SERVICE_ACCOUNT_PATH");
    return null;
  } catch (error) {
    console.error("Failed to initialize Firebase Admin:", error);
    return null;
  }
};

const app = initializeFirebaseAdmin();

/**
 * Sends a push notification to a user via Firebase Cloud Messaging.
 * Automatically clears the FCM token if it is found to be invalid/expired.
 */
export async function sendPush(
  userId: string,
  title: string,
  body: string,
  data?: Record<string, string>
) {
  if (!app) {
    console.warn("Skipping push notification: Firebase Admin is not initialized.");
    return;
  }

  try {
    const user = await db.query.users.findFirst({
      where: eq(users.id, userId),
      columns: {
        fcmToken: true,
      },
    });

    if (!user || !user.fcmToken) {
      // No token registered, nothing to do
      return;
    }

    const message: Message = {
      token: user.fcmToken,
      notification: {
        title,
        body,
      },
      data,
    };

    await getMessaging().send(message);
    console.log(`Push notification sent successfully to user ${userId}`);

  } catch (error: any) {
    // Handle invalid or expired tokens
    if (
      error.code === "messaging/invalid-registration-token" ||
      error.code === "messaging/registration-token-not-registered"
    ) {
      console.warn(`Invalid FCM token for user ${userId}. Clearing token from DB...`);
      await db.update(users)
        .set({ fcmToken: null })
        .where(eq(users.id, userId));
    } else {
      console.error(`Failed to send push notification to user ${userId}:`, error);
    }
  }
}
