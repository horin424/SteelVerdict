import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";

/**
 * checkDeserters — runs every hour via Cloud Scheduler.
 *
 * Finds all "waiting" or "active" matches past their expiresAt timestamp.
 * - "waiting" (no opponent joined): mark as timeout, no winner.
 * - "active" (one player didn't submit): the player who submitted wins;
 *   the non-submitter is the deserter and completely loses.
 */
export const checkDeserters = onSchedule("every 60 minutes", async () => {
  const db = admin.firestore();
  const now = Date.now();

  const expiredQuery = await db
    .collection("pvp_matches")
    .where("status", "in", ["waiting", "active"])
    .where("expiresAt", "<", now)
    .get();

  if (expiredQuery.empty) {
    console.log("checkDeserters: no expired matches found.");
    return;
  }

  const batch = db.batch();
  let count = 0;

  for (const doc of expiredQuery.docs) {
    const match = doc.data();

    if (match.status === "waiting") {
      // Nobody joined — just time out
      batch.update(doc.ref, {
        status: "timeout",
        shortReport: "Match timed out — no opponent found.",
        resolvedAt: now,
      });
    } else if (match.status === "active") {
      // Determine deserter: whoever has no strategy submitted
      const aSubmitted = !!match.playerAStrategy;
      const bSubmitted = !!match.playerBStrategy;

      let winner = "draw";
      let report = "Both players failed to submit. Draw.";

      if (aSubmitted && !bSubmitted) {
        winner = match.playerAUid;
        report = "Player B failed to submit a strategy. Player A wins by desertion.";
      } else if (!aSubmitted && bSubmitted) {
        winner = match.playerBUid;
        report = "Player A failed to submit a strategy. Player B wins by desertion.";
      }

      batch.update(doc.ref, {
        status: "resolved",
        winner,
        shortReport: report,
        resolvedAt: now,
      });
    }

    count++;
  }

  await batch.commit();
  console.log(`checkDeserters: resolved ${count} expired match(es).`);
});
