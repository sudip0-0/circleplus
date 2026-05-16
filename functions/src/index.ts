import * as admin from "firebase-admin";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/v2";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ─── Helpers ─────────────────────────────────────────────────────────────────

/**
 * Fetches FCM tokens for all members of a Circle, excluding one user.
 */
async function getMemberTokens(
  circleId: string,
  excludeUserId: string,
): Promise<string[]> {
  const membersSnap = await db
    .collection("circles")
    .doc(circleId)
    .collection("members")
    .get();

  const memberIds = membersSnap.docs
    .map((doc) => doc.data().userId as string)
    .filter((uid) => uid !== excludeUserId);

  if (memberIds.length === 0) return [];

  // Fetch FCM tokens in batches of 10 (Firestore 'in' limit).
  const tokens: string[] = [];
  for (let i = 0; i < memberIds.length; i += 10) {
    const batch = memberIds.slice(i, i + 10);
    const userSnaps = await db
      .collection("users")
      .where(admin.firestore.FieldPath.documentId(), "in", batch)
      .get();
    for (const userDoc of userSnaps.docs) {
      const fcmTokens = userDoc.data().fcmTokens as string[] | undefined;
      if (Array.isArray(fcmTokens)) {
        tokens.push(...fcmTokens);
      }
    }
  }
  return tokens;
}

/**
 * Sends a multicast FCM push to a list of tokens, removing stale ones.
 */
async function sendMulticast(
  tokens: string[],
  notification: admin.messaging.Notification,
  data?: Record<string, string>,
): Promise<void> {
  if (tokens.length === 0) return;

  // Firebase Messaging sendEachForMulticast supports up to 500 tokens.
  const chunks: string[][] = [];
  for (let i = 0; i < tokens.length; i += 500) {
    chunks.push(tokens.slice(i, i + 500));
  }

  for (const chunk of chunks) {
    const response = await messaging.sendEachForMulticast({
      tokens: chunk,
      notification,
      data,
      android: { priority: "high" },
      apns: { payload: { aps: { sound: "default" } } },
    });

    // Collect stale / invalid tokens for cleanup.
    const staleTokens: string[] = [];
    response.responses.forEach((resp, idx) => {
      if (!resp.success) {
        const code = resp.error?.code;
        if (
          code === "messaging/registration-token-not-registered" ||
          code === "messaging/invalid-registration-token"
        ) {
          staleTokens.push(chunk[idx]);
        }
      }
    });

    if (staleTokens.length > 0) {
      logger.info(`Removing ${staleTokens.length} stale FCM token(s).`);
      await removeStaleTokens(staleTokens);
    }
  }
}

/**
 * Removes stale FCM tokens from user documents by scanning affected users.
 */
async function removeStaleTokens(staleTokens: string[]): Promise<void> {
  // Query users whose fcmTokens array contains any of the stale values.
  // Firestore 'array-contains-any' is limited to 10 values per query.
  for (let i = 0; i < staleTokens.length; i += 10) {
    const batch = staleTokens.slice(i, i + 10);
    const snap = await db
      .collection("users")
      .where("fcmTokens", "array-contains-any", batch)
      .get();
    const writes = db.batch();
    for (const doc of snap.docs) {
      writes.update(doc.ref, {
        fcmTokens: admin.firestore.FieldValue.arrayRemove(...batch),
      });
    }
    await writes.commit();
  }
}

// ─── Trigger: new message ─────────────────────────────────────────────────────

export const onNewMessage = onDocumentCreated(
  "circles/{circleId}/messages/{messageId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    // Skip system messages and already-deleted messages.
    const type: string = data.type ?? "";
    if (type === "system" || type === "deleted") return;

    const circleId: string = event.params.circleId;
    const senderId: string = data.senderId ?? "";
    const senderName: string = data.senderName ?? "Someone";

    // Build a short notification body.
    let body: string;
    if (type === "photo") {
      body = data.text ? `📷 ${data.text}` : "📷 Sent a photo";
    } else {
      body = (data.text as string) ?? "";
      if (body.length > 120) body = body.slice(0, 117) + "…";
    }

    // Get the Circle name for the notification title.
    let circleNameStr = "Circle";
    try {
      const circleDoc = await db.collection("circles").doc(circleId).get();
      circleNameStr = (circleDoc.data()?.name as string) ?? "Circle";
    } catch {
      // Non-critical – fall back to "Circle".
    }

    const tokens = await getMemberTokens(circleId, senderId);

    await sendMulticast(
      tokens,
      { title: `${senderName} in ${circleNameStr}`, body },
      { circleId, type: "message" },
    );

    logger.info(`onNewMessage: notified ${tokens.length} member(s).`, {
      circleId,
      messageId: event.params.messageId,
    });
  },
);

// ─── Trigger: new plan ────────────────────────────────────────────────────────

export const onNewPlan = onDocumentCreated(
  "circles/{circleId}/plans/{planId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const circleId: string = event.params.circleId;
    const planId: string = event.params.planId;
    const creatorName: string = data.createdByName ?? "Someone";
    const title: string = data.title ?? "New plan";

    // Get the Circle name.
    let circleNameStr = "Circle";
    try {
      const circleDoc = await db.collection("circles").doc(circleId).get();
      circleNameStr = (circleDoc.data()?.name as string) ?? "Circle";
    } catch {
      // Non-critical.
    }

    const tokens = await getMemberTokens(circleId, data.createdBy ?? "");

    await sendMulticast(
      tokens,
      {
        title: `New plan in ${circleNameStr}`,
        body: `${creatorName} created "${title}"`,
      },
      { circleId, planId, type: "plan" },
    );

    logger.info(`onNewPlan: notified ${tokens.length} member(s).`, {
      circleId,
      planId,
    });
  },
);
