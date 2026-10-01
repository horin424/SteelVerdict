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
  // Prefer the match's worldview when present; never silently force fantasy
  // when both players fought under another world.
  const worldviewKey =
    (match as FirestorePvpMatch & { worldviewKey?: string }).worldviewKey ||
    "1830_fantasy";
  const systemPrompt = await assemblePrompt(worldviewKey, "pvp", "pvp");
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
  let winner = "draw";
  if (
    /WINNER\s*:\s*PLAYER\s*A/i.test(text) ||
    /勝者\s*[:：]\s*(プレイヤー\s*)?A/i.test(text)
  ) {
    winner = playerAUid;
  } else if (
    /WINNER\s*:\s*PLAYER\s*B/i.test(text) ||
    /勝者\s*[:：]\s*(プレイヤー\s*)?B/i.test(text)
  ) {
    winner = playerBUid;
  } else if (
    /WINNER\s*:\s*DRAW/i.test(text) ||
    /勝者\s*[:：]\s*引き分け/i.test(text)
  ) {
    winner = "draw";
  }

  const reportMatch = text.match(/REPORT:\s*(.+)/i);
  const shortReport = reportMatch
    ? reportMatch[1].trim().substring(0, 60)
    : text.trim().substring(0, 60);

  return { winner, shortReport };
}
