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

  const verdict = parsePvpResponse(response, match.playerAUid, match.playerBUid);
  if (!verdict) {
    // Both players paid for a verdict, so an answer with none is a failed
    // judgment, not a draw (B2). The match stays open: the deadline sweep
    // (checkDeserters) tries once more and refunds both players if it fails.
    throw new Error(`no verdict in the model's answer: ${response.substring(0, 200)}`);
  }
  const { winner, shortReport } = verdict;

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

/**
 * Reads the model's verdict. Returns null when the answer names no winner and
 * no draw: that used to become a silent draw (B2).
 */
export function parsePvpResponse(
  text: string,
  playerAUid: string,
  playerBUid: string,
): { winner: string; shortReport: string } | null {
  // Models often write the lines in bold, "**WINNER:** PLAYER A". The
  // asterisks sat between the label and the value, so no pattern matched and
  // the match was declared a draw. They carry no meaning here, and would show
  // as literal asterisks in the short report.
  const plain = text.replace(/\*/g, "");

  let winner: string | null = null;
  if (
    /WINNER\s*[:：]\s*PLAYER\s*A/i.test(plain) ||
    /勝者\s*[:：]\s*(プレイヤー\s*)?A/i.test(plain)
  ) {
    winner = playerAUid;
  } else if (
    /WINNER\s*[:：]\s*PLAYER\s*B/i.test(plain) ||
    /勝者\s*[:：]\s*(プレイヤー\s*)?B/i.test(plain)
  ) {
    winner = playerBUid;
  } else if (
    /WINNER\s*[:：]\s*DRAW/i.test(plain) ||
    /勝者\s*[:：]\s*引き分け/i.test(plain)
  ) {
    winner = "draw";
  }
  if (winner === null) return null;

  const reportMatch = plain.match(/REPORT\s*[:：]\s*(.+)/i);
  const shortReport = reportMatch
    ? reportMatch[1].trim().substring(0, 60)
    : plain.trim().substring(0, 60);

  return { winner, shortReport };
}
