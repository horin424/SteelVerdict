import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { GEMINI_API_KEY } from "../utils/config";
import { judgePvpMatch } from "./judgePvpMatch";
import { FirestorePvpMatch } from "../utils/firestore";

/**
 * Firestore trigger — judges a PvP match once both players have submitted.
 *
 * The previous version fired only on the status transition into "active":
 *
 *   if (before.status === "active" || after.status !== "active") return;
 *   if (!after.playerAStrategy || !after.playerBStrategy) return;
 *
 * findOrCreatePvpMatch sets status to "active" the moment player B *joins*,
 * before either strategy exists — so at the only instant the first guard let
 * through, the second guard always returned. Every later strategy write had
 * before.status === "active" and was rejected by the first. The result: the
 * judge never ran, matches sat until the 24h sweep, and the sweep then told two
 * players who had both submitted that neither of them had.
 *
 * Now the condition is what it should always have been: fire on the update that
 * completes the pair of strategies, whatever the status was doing.
 */
export const judgeCompletedPvpMatch = onDocumentUpdated(
  { document: "pvp_matches/{matchId}", secrets: [GEMINI_API_KEY] },
  async (event) => {
    const after = event.data?.after.data();
    const before = event.data?.before.data();

    if (!after || !before) return;

    const bothNow = !!after.playerAStrategy && !!after.playerBStrategy;
    const bothBefore = !!before.playerAStrategy && !!before.playerBStrategy;

    // Only the update that completes the pair. bothBefore also stops this
    // trigger re-entering on its own result write.
    if (!bothNow || bothBefore) return;

    // Already settled (e.g. by the deserter sweep) — leave it alone.
    if (after.status === "resolved" || after.status === "timeout") return;

    const matchId = event.params.matchId;
    console.log(`Judging PvP match ${matchId}`);

    try {
      await judgePvpMatch(matchId, after as FirestorePvpMatch, GEMINI_API_KEY.value());
    } catch (err) {
      // Don't rethrow — a retry would re-run the AI call and double the cost.
      // checkDeserters picks up anything left unresolved at the deadline.
      console.error(`Failed to judge match ${matchId}:`, err);
    }
  },
);
