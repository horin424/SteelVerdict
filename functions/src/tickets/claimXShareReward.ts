import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { ensureUserDoc } from "../utils/firestore";
import { japanDateString } from "../utils/japanDay";

/**
 * claimXShareReward — grant 1 ticket for sharing to X once per day.
 * Checked server-side via lastXShareRewardAt field; the day is Japan's (utils/japanDay).
 */
export const claimXShareReward = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  const uid = request.auth.uid;
  await ensureUserDoc(uid);
  const ref = admin.firestore().collection("users").doc(uid);

  const today = japanDateString(new Date());

  let newCount = 0;
  await admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "User not found.");
    const data = snap.data() as { ticketCount: number; lastXShareRewardAt?: number };

    const lastClaim = data.lastXShareRewardAt
      ? japanDateString(new Date(data.lastXShareRewardAt))
      : "";

    if (lastClaim === today) {
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
