import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { getUser } from "../utils/firestore";

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
 * Checks lastDailyRewardAt against current date (UTC).
 * Prevents multiple claims per day regardless of client state.
 */
export const claimDailyReward = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  const uid = request.auth.uid;
  const user = await getUser(uid);

  const nowUtc = new Date();
  const todayUtc = toUtcDateString(nowUtc);
  const lastClaimUtc = user.lastDailyRewardAt
    ? toUtcDateString(new Date(user.lastDailyRewardAt))
    : "";

  if (lastClaimUtc === todayUtc) {
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
      ? toUtcDateString(new Date(data.lastDailyRewardAt))
      : "";
    if (lastInTx === todayUtc) {
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

/** Soft daily cap — prevents unauthenticated spam / API abuse while still
 *  allowing generous rewarded-ad farming. Adjust via code if product wants more. */
const MAX_AD_TICKET_CLAIMS_PER_DAY = 20;
const TICKETS_PER_AD = 2;

/**
 * earnAdTickets — grant tickets for watching a rewarded ad.
 * Server-side daily claim cap (client cannot bypass).
 */
export const earnAdTickets = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  const uid = request.auth.uid;
  const ref = admin.firestore().collection("users").doc(uid);
  const todayUtc = toUtcDateString(new Date());

  let newCount = 0;
  let ticketsAdded = 0;
  await admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "User not found.");
    const data = snap.data() as {
      ticketCount: number;
      adTicketClaimsDate?: string;
      adTicketClaimsCount?: number;
    };

    const claimsDate = data.adTicketClaimsDate ?? "";
    const claimsCount = claimsDate === todayUtc ? (data.adTicketClaimsCount ?? 0) : 0;
    if (claimsCount >= MAX_AD_TICKET_CLAIMS_PER_DAY) {
      throw new HttpsError(
        "resource-exhausted",
        "Daily ad ticket limit reached. Try again tomorrow.",
      );
    }

    ticketsAdded = TICKETS_PER_AD;
    newCount = (data.ticketCount ?? 0) + ticketsAdded;
    tx.update(ref, {
      ticketCount: newCount,
      adTicketClaimsDate: todayUtc,
      adTicketClaimsCount: claimsCount + 1,
    });
  });

  return { ticketsAdded, newTicketCount: newCount };
});

function toUtcDateString(date: Date): string {
  return date.toISOString().substring(0, 10); // "YYYY-MM-DD"
}
