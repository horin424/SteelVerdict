import * as admin from "firebase-admin";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { GEMINI_API_KEY } from "../utils/config";
import { callGeminiFlash } from "../utils/ai";
import { assemblePrompt, formatPvpUserMessage } from "../utils/prompt";

/**
 * Firestore trigger — fires when a pvp_matches document is updated.
 * When both players have submitted strategies (status becomes "active"),
 * calls Gemini Flash to judge the battle and writes the result.
 *
 * Using Gemini Flash for all PvP (fixed model for fairness — spec requirement).
 */
export const judgeCompletedPvpMatch = onDocumentUpdated(
  { document: "pvp_matches/{matchId}", secrets: [GEMINI_API_KEY] },
  async (event) => {
    const after = event.data?.after.data();
    const before = event.data?.before.data();

    if (!after || !before) return;

    // Only run when status transitions to "active"
    if (before.status === "active" || after.status !== "active") return;
    if (!after.playerAStrategy || !after.playerBStrategy) return;

    const matchId = event.params.matchId;
    console.log(`Judging PvP match ${matchId}`);

    try {
      // Assemble PvP prompt (no commander_definition for PvP)
      const systemPrompt = await assemblePrompt("1830_fantasy", "pvp", "pvp");
      const userMessage = formatPvpUserMessage(
        after.playerAStrategy,
        after.playerAStats,
        after.playerARaceName,
        after.playerBStrategy,
        after.playerBStats,
        after.playerBRaceName,
      );

      const response = await callGeminiFlash(
        GEMINI_API_KEY.value(),
        systemPrompt,
        userMessage,
      );

      // Parse winner and report from response
      const { winner, shortReport } = parsePvpResponse(
        response,
        after.playerAUid,
        after.playerBUid,
      );

      await admin.firestore()
        .collection("pvp_matches")
        .doc(matchId)
        .update({
          winner,
          shortReport,
          status: "resolved",
          resolvedAt: Date.now(),
        });

      console.log(`Match ${matchId} resolved. Winner: ${winner}`);
    } catch (err) {
      console.error(`Failed to judge match ${matchId}:`, err);
      // Don't throw — Firestore triggers don't benefit from rethrowing
    }
  },
);

function parsePvpResponse(
  text: string,
  playerAUid: string,
  playerBUid: string,
): { winner: string; shortReport: string } {
  const upper = text.toUpperCase();

  let winner = "draw";
  if (upper.includes("WINNER: PLAYER A")) {
    winner = playerAUid;
  } else if (upper.includes("WINNER: PLAYER B")) {
    winner = playerBUid;
  } else if (upper.includes("WINNER: DRAW")) {
    winner = "draw";
  }

  // Extract REPORT: line
  const reportMatch = text.match(/REPORT:\s*(.+)/i);
  const shortReport = reportMatch
    ? reportMatch[1].trim().substring(0, 60)
    : text.trim().substring(0, 60);

  return { winner, shortReport };
}
