import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { GEMINI_API_KEY } from "../utils/config";
import { judgePvpMatch } from "../battle/judgePvpMatch";
import { FirestorePvpMatch } from "../utils/firestore";

/**
 * checkDeserters — runs every hour via Cloud Scheduler.
 *
 * Finds all "waiting" or "active" matches past their expiresAt timestamp.
 * - "waiting" (no opponent joined): mark as timeout, no winner.
 * - "active", one strategy missing: the player who submitted wins; the
 *   non-submitter deserted.
 * - "active", BOTH strategies present: judge it properly.
 *
 * That last case used to fall through to the default branch and write
 * winner: "draw" with the report "Both players failed to submit. Draw." — shown
 * to two players who had both, in fact, submitted. It happened to every single
 * match, because the judging trigger never fired (see judgeCompletedPvpMatch).
 * The trigger is fixed now, so reaching this branch should be rare; it stays as
 * a safety net for matches whose AI call failed.
 */
export const checkDeserters = onSchedule(
  { schedule: "every 60 minutes", secrets: [GEMINI_API_KEY] },
  async () => {
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
    let batched = 0;
    let judged = 0;
    const toJudge: Array<{ id: string; data: FirestorePvpMatch }> = [];

    for (const doc of expiredQuery.docs) {
      const match = doc.data();

      if (match.status === "waiting") {
        batch.update(doc.ref, {
          status: "timeout",
          shortReport: "Match timed out — no opponent found.",
          resolvedAt: now,
        });
        batched++;
        continue;
      }

      const aSubmitted = !!match.playerAStrategy;
      const bSubmitted = !!match.playerBStrategy;

      if (aSubmitted && bSubmitted) {
        // Both played. Judge it rather than declaring a false draw.
        toJudge.push({ id: doc.id, data: match as FirestorePvpMatch });
        continue;
      }

      let winner = "draw";
      let report = "Neither player submitted a strategy. No result.";

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
      batched++;
    }

    if (batched > 0) {
      await batch.commit();
    }

    // Judged one at a time: each is an AI call, and one failure must not stop
    // the rest from being settled.
    for (const m of toJudge) {
      try {
        await judgePvpMatch(m.id, m.data, GEMINI_API_KEY.value());
        judged++;
      } catch (err) {
        console.error(`checkDeserters: failed to judge ${m.id}:`, err);
      }
    }

    console.log(
      `checkDeserters: ${batched} settled without judging, ${judged} judged, ` +
      `${toJudge.length - judged} failed.`,
    );
  },
);
