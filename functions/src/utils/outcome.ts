export type Outcome = "win" | "loss" | "draw";

/**
 * Parses the battle outcome out of an AI-written report.
 *
 * The previous implementation did `text.toUpperCase().includes("WIN")` and
 * checked win before loss. Two things were wrong with that:
 *
 *   - "WIN" is a substring of WING, DRAWING, WINDING, SWING, TWIN, WINTER.
 *     A report saying "the enemy's left wing collapsed ... DEFEAT" parsed as a
 *     player *victory*, because the win branch ran first.
 *   - Only English was recognised, so a Japanese report could never be anything
 *     but a draw - which is exactly what the client reported.
 *
 * Strategy here, in order of confidence:
 *
 *   1. The prompts (see PROMPT_CONFIG_GUIDE.md) instruct the model to end its
 *      response with VICTORY / DEFEAT / STALEMATE on its own line. If one of the
 *      last few lines is a bare outcome keyword, trust that above everything.
 *   2. Otherwise take the *last* outcome keyword in the text, matched on word
 *      boundaries. Last rather than first, because reports narrate the battle
 *      and then announce the result.
 *   3. If nothing matches at all, "draw" - same fallback as before.
 *
 * Known limit: a report can legitimately contain "the enemy was defeated",
 * which is a player win phrased with a loss keyword. No keyword scan can settle
 * that. Keeping the model disciplined about the trailing keyword (rule 1) is
 * what makes this reliable; rules 2-3 are a safety net.
 */

// Standalone keywords, used for rule 1 - a whole line that is just the verdict.
const STANDALONE: Array<[RegExp, Outcome]> = [
  [/^(VICTORY|WIN|WON|TRIUMPH)$/i, "win"],
  [/^(DEFEAT|DEFEATED|LOSS|LOST)$/i, "loss"],
  [/^(STALEMATE|DRAW|TIE|INCONCLUSIVE)$/i, "draw"],
  [/^(勝利|勝ち|大勝)$/u, "win"],
  [/^(敗北|敗戦|負け|惨敗)$/u, "loss"],
  [/^(引き分け|引分|痛み分け|膠着)$/u, "draw"],
];

// In-text keywords, used for rule 2.
//
// Note the omission of a bare English "DRAW": "draw the enemy into the valley"
// is ordinary strategy prose, and treating it as a verdict caused false draws.
// STALEMATE and the Japanese terms are unambiguous, so those stay.
const IN_TEXT: Array<[RegExp, Outcome]> = [
  [/\b(VICTORY|VICTORIOUS|WINS?|WON|WINNING|TRIUMPHED)\b/gi, "win"],
  [/\b(DEFEAT|DEFEATED|LOSS|LOST|ROUTED|ANNIHILATED)\b/gi, "loss"],
  [/\b(STALEMATE|DRAWN|INCONCLUSIVE)\b/gi, "draw"],
  [/(勝利|勝ち|大勝)/gu, "win"],
  [/(敗北|敗戦|負け|惨敗)/gu, "loss"],
  [/(引き分け|引分|痛み分け|膠着)/gu, "draw"],
];

/** Strips markdown emphasis, list bullets and trailing punctuation from a line. */
function bareLine(line: string): string {
  return line
    .replace(/[*_#>`\-\s]/gu, "")
    .replace(/[.!?:。！？：]+$/u, "")
    .trim();
}

export function parseOutcome(text: string): Outcome {
  if (!text) return "draw";

  // Rule 1 - a trailing line that is nothing but the verdict.
  const lines = text
    .split(/\r?\n/)
    .map((l) => l.trim())
    .filter((l) => l.length > 0);

  for (const line of lines.slice(-4).reverse()) {
    const bare = bareLine(line);
    if (!bare) continue;
    for (const [re, outcome] of STANDALONE) {
      if (re.test(bare)) return outcome;
    }
  }

  // Rule 2 - last keyword anywhere in the text.
  let bestIndex = -1;
  let bestOutcome: Outcome = "draw";
  for (const [re, outcome] of IN_TEXT) {
    re.lastIndex = 0;
    let match: RegExpExecArray | null;
    while ((match = re.exec(text)) !== null) {
      if (match.index >= bestIndex) {
        bestIndex = match.index;
        bestOutcome = outcome;
      }
      if (match.index === re.lastIndex) re.lastIndex++; // guard zero-width
    }
  }

  // Rule 3 - nothing recognised.
  return bestIndex === -1 ? "draw" : bestOutcome;
}
