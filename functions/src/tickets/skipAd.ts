import { onCall, HttpsError } from "firebase-functions/v2/https";
import { deductTickets } from "../utils/firestore";

/**
 * skipAd — deducts 1 ticket so the user can skip an interstitial ad.
 * Used in Practice mode (every 3rd play) and Tabletop mode overlay.
 */
export const skipAd = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  const uid = request.auth.uid;

  try {
    const newCount = await deductTickets(uid, 1);
    return { ticketsDeducted: 1, newTicketCount: newCount };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg.includes("Not enough tickets")) {
      throw new HttpsError("failed-precondition", "Not enough tickets to skip.");
    }
    throw new HttpsError("internal", "Failed to skip ad.");
  }
});
