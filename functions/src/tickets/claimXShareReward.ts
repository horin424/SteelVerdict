import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

/**
 * claimXShareReward — grant 1 ticket for sharing to X once per day.
 * Checked server-side via lastXShareRewardAt field.
 */
export const claimXShareReward = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  const uid = request.auth.uid;
  const ref = admin.firestore().collection("users").doc(uid);

  const nowUtc = new Date();
  const todayUtc = toUtcDateString(nowUtc);

  let newCount = 0;
  await admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "User not found.");
    const data = snap.data() as { ticketCount: number; lastXShareRewardAt?: number };

    const lastClaim = data.lastXShareRewardAt
      ? toUtcDateString(new Date(data.lastXShareRewardAt))
      : "";

    if (lastClaim === todayUtc) {
      throw new HttpsError("already-exists", "X share reward already claimed today.");
    }

    newCount = data.ticketCount + 1;
    tx.update(ref, {
      ticketCount: newCount,
      lastXShareRewardAt: Date.now(),
    });
  });

  return { ticketsAdded: 1, newTicketCount: newCount };
});

function toUtcDateString(date: Date): string {
  return date.toISOString().substring(0, 10); // "YYYY-MM-DD"
}
