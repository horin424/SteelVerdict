import * as admin from "firebase-admin";
import { callGeminiFlash } from "../utils/ai";
import { assemblePrompt, formatPvpUserMessage } from "../utils/prompt";
import { FirestorePvpMatch } from "../utils/firestore";

/**
 * Judges one PvP match and writes the result.
 *
 * Extracted so it can be driven from two places:
 *   - judgeCompletedPvpMatch, the Firestore trigger, on the update that
 *     completes both strategies (the normal path)
 *   - checkDeserters, the hourly sweep, as a safety net for any match that
 *     reached its deadline with both strategies present but no verdict
 *
 * Gemini Flash is fixed for all PvP so both players are judged by the same
 * model regardless of what either of them paid for elsewhere.
 */
export async function judgePvpMatch(
  matchId: string,
  match: FirestorePvpMatch,
  geminiApiKey: string,
): Promise<void> {
  const systemPrompt = await assemblePrompt("1830_fantasy", "pvp", "pvp");
  const userMessage = formatPvpUserMessage(
    match.playerAStrategy,
    match.playerAStats,
    match.playerARaceName,
    match.playerBStrategy,
    match.playerBStats,
    match.playerBRaceName,
  );

  const response = await callGeminiFlash(geminiApiKey, systemPrompt, userMessage);

  const { winner, shortReport } = parsePvpResponse(
    response,
    match.playerAUid,
    match.playerBUid,
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
}

export function parsePvpResponse(
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

  const reportMatch = text.match(/REPORT:\s*(.+)/i);
  const shortReport = reportMatch
    ? reportMatch[1].trim().substring(0, 60)
    : text.trim().substring(0, 60);

  return { winner, shortReport };
}
