import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { GEMINI_API_KEY, TICKET_COSTS } from "../utils/config";
import { judgePvpMatch } from "../battle/judgePvpMatch";
import { FirestorePvpMatch } from "../utils/firestore";
import { fetchRemoteConfigData } from "../utils/prompt";

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
 *
 * If judging fails here too, the match times out and both players get their
 * tickets back. Before, it stayed "active" and was retried every hour.
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
    let refunded = 0;
    for (const m of toJudge) {
      try {
        await judgePvpMatch(m.id, m.data, GEMINI_API_KEY.value());
        judged++;
      } catch (err) {
        console.error(`checkDeserters: failed to judge ${m.id}:`, err);
        try {
          await refundUnjudgedMatch(m.id, m.data, now);
          refunded++;
        } catch (refundErr) {
          console.error(`checkDeserters: failed to refund ${m.id}:`, refundErr);
        }
      }
    }

    console.log(
      `checkDeserters: ${batched} settled without judging, ${judged} judged, ` +
      `${refunded} could not be judged and were refunded.`,
    );
  },
);

/**
 * Ends a match that could not be judged: it times out, and both players get
 * back what they paid to submit (B2). Done in a transaction, so a match that
 * was settled in the meantime is left alone and nobody is refunded twice.
 */
async function refundUnjudgedMatch(matchId: string, match: FirestorePvpMatch, now: number) {
  const db = admin.firestore();

  // Matches from before the amount was kept: assume the current PvP price,
  // which developers never pay.
  const rc = await fetchRemoteConfigData();
  const price = rc.ticket_costs?.["pvp"] ?? TICKET_COSTS.pvp;
  const devUids = rc.dev_uids ?? [];
  const paid = (uid: string, kept: number | undefined) =>
    kept ?? (devUids.includes(uid) ? 0 : price);
  const refunds = [
    { uid: match.playerAUid, amount: paid(match.playerAUid, match.playerATicketsPaid) },
    { uid: match.playerBUid, amount: paid(match.playerBUid, match.playerBTicketsPaid) },
  ].filter((r) => r.uid && r.amount > 0);

  const matchRef = db.collection("pvp_matches").doc(matchId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(matchRef);
    if (!snap.exists || snap.data()?.status !== "active") return;
    const users = await Promise.all(
      refunds.map((r) => tx.get(db.collection("users").doc(r.uid))),
    );
    tx.update(matchRef, {
      status: "timeout",
      shortReport: "The match could not be judged. Tickets refunded.",
      resolvedAt: now,
    });
    users.forEach((user, i) => {
      if (user.exists) {
        tx.update(user.ref, {
          ticketCount: admin.firestore.FieldValue.increment(refunds[i].amount),
        });
      }
    });
  });
}
