import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { deductTickets, addTickets } from "../utils/firestore";
import { fetchRemoteConfigData } from "../utils/prompt";
import { TICKET_COSTS } from "../utils/config";

const MAX_STRATEGY_LENGTH = 2000;
const MIN_STRATEGY_LENGTH = 5;

interface SubmitPvpStrategyRequest {
  matchId: string;
  strategy: string;
}

/**
 * submitPvpStrategy — deduct PvP ticket cost, then write the caller's strategy.
 *
 * Replaces direct client writes so ticket charging cannot be bypassed and
 * strategy length is enforced server-side.
 */
export const submitPvpStrategy = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  const uid = request.auth.uid;
  const data = request.data as SubmitPvpStrategyRequest;

  if (!data.matchId || typeof data.strategy !== "string") {
    throw new HttpsError("invalid-argument", "matchId and strategy are required.");
  }

  const strategy = data.strategy.trim();
  if (strategy.length < MIN_STRATEGY_LENGTH) {
    throw new HttpsError("invalid-argument", "Strategy is too short.");
  }
  if (strategy.length > MAX_STRATEGY_LENGTH) {
    throw new HttpsError(
      "invalid-argument",
      `Strategy exceeds ${MAX_STRATEGY_LENGTH} characters.`,
    );
  }

  const db = admin.firestore();
  const matchRef = db.collection("pvp_matches").doc(data.matchId);
  const snap = await matchRef.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Match not found.");
  }

  const match = snap.data()!;
  if (match.status !== "waiting" && match.status !== "active") {
    throw new HttpsError("failed-precondition", "Match is no longer open.");
  }

  let strategyField: "playerAStrategy" | "playerBStrategy";
  if (match.playerAUid === uid) {
    strategyField = "playerAStrategy";
  } else if (match.playerBUid === uid) {
    strategyField = "playerBStrategy";
  } else {
    throw new HttpsError("permission-denied", "Not a participant of this match.");
  }

  if (match[strategyField]) {
    throw new HttpsError("already-exists", "Strategy already submitted.");
  }

  const rcData = await fetchRemoteConfigData();
  const rcCosts = rcData.ticket_costs ?? {};
  const cost = (rcCosts["pvp"] as number | undefined) ?? TICKET_COSTS.pvp;
  const devUids: string[] = (rcData as { dev_uids?: string[] }).dev_uids ?? [];
  const isDevUser = devUids.includes(uid);

  if (cost > 0 && !isDevUser) {
    await deductTickets(uid, cost);
  }

  try {
    await matchRef.update({ [strategyField]: strategy });
  } catch (err) {
    if (cost > 0 && !isDevUser) {
      try {
        await addTickets(uid, cost);
      } catch (refundErr) {
        console.error("PvP ticket refund failed:", refundErr);
      }
    }
    throw err;
  }

  return { submitted: true, ticketsConsumed: isDevUser ? 0 : cost };
});
