import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { getUser, ensureUserDoc } from "../utils/firestore";
import { japanDateString } from "../utils/japanDay";

// Daily ticket amounts per subscription tier — must match app_constants.dart
// AppConstants.dailyTicketsFree=1, sub500=10, sub1000=15, sub3000=50
const DAILY_TICKETS: Record<string, number> = {
  free: 1,
  sub500: 10,
  sub1000: 15,
  sub3000: 50,
};

/**
 * claimDailyReward — server-side daily ticket grant.
 *
 * Checks lastDailyRewardAt against the current date in Japan (utils/japanDay).
 * Prevents multiple claims per day regardless of client state.
 */
export const claimDailyReward = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  const uid = request.auth.uid;
  await ensureUserDoc(uid);
  const user = await getUser(uid);

  const today = japanDateString(new Date());
  const lastClaim = user.lastDailyRewardAt
    ? japanDateString(new Date(user.lastDailyRewardAt))
    : "";

  if (lastClaim === today) {
    throw new HttpsError("already-exists", "Daily reward already claimed today.");
  }

  const tier = user.subscriptionTier ?? "free";
  const amount = DAILY_TICKETS[tier] ?? DAILY_TICKETS.free;

  // Update lastDailyRewardAt and add tickets atomically
  const ref = admin.firestore().collection("users").doc(uid);
  let newCount = 0;
  await admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "User not found.");
    const data = snap.data() as { ticketCount: number; lastDailyRewardAt: number };

    // Double-check inside transaction to be safe
    const lastInTx = data.lastDailyRewardAt
      ? japanDateString(new Date(data.lastDailyRewardAt))
      : "";
    if (lastInTx === today) {
      throw new HttpsError("already-exists", "Daily reward already claimed today.");
    }

    newCount = data.ticketCount + amount;
    tx.update(ref, {
      ticketCount: newCount,
      lastDailyRewardAt: Date.now(),
    });
  });

  return { ticketsAdded: amount, newTicketCount: newCount };
});

/**
 * earnAdTickets — adds no tickets any more (20 Nov 2026). It gave +2 to any
 * signed-in caller, 20 times a day, with nothing to show that an ad was
 * watched. The ad tickets now come from admobRewardCallback, when Google
 * confirms the ad (tickets/adReward.ts). Kept so older app builds get a clear
 * answer instead of "not found".
 */
export const earnAdTickets = onCall(async () => {
  throw new HttpsError(
    "failed-precondition",
    "Ad tickets now come when Google confirms the ad. Please update the app.",
  );
});
