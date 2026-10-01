export type Outcome = "win" | "loss" | "draw" | "survival";

export interface ParsedOutcome {
  outcome: Outcome;
  /** Present when outcome === "survival". */
  survivalDays?: number;
}

/**
 * Parses the battle outcome out of an AI-written report.
 *
 * Preferred format (instructed in prompt.ts):
 *   [[RESULT:VICTORY]] | [[RESULT:DEFEAT]] | [[RESULT:DRAW]]
 *   [[RESULT:SURVIVAL|days=17]]
 *
 * Legacy: trailing VICTORY / DEFEAT / STALEMATE (EN) or 勝利 / 敗北 / 引き分け (JA).
 *
 * IMPORTANT: an unparseable response is NOT a draw. Callers must treat
 * `null` as a parsing error (refund + retry), never silently store a draw.
 */

const RESULT_MARKER =
  /\[\[\s*RESULT\s*:\s*(VICTORY|DEFEAT|DRAW|STALEMATE|SURVIVAL|WIN|LOSS)(?:\s*[|,]\s*days\s*=\s*(\d+))?\s*\]\]/i;

// Standalone keywords, used for legacy trailing-line detection.
const STANDALONE: Array<[RegExp, Outcome]> = [
  [/^(VICTORY|WIN|WON|TRIUMPH)$/i, "win"],
  [/^(DEFEAT|DEFEATED|LOSS|LOST)$/i, "loss"],
  [/^(STALEMATE|DRAW|TIE|INCONCLUSIVE)$/i, "draw"],
  [/^(勝利|勝ち|大勝)$/u, "win"],
  [/^(敗北|敗戦|負け|惨敗)$/u, "loss"],
  [/^(引き分け|引分|痛み分け|膠着)$/u, "draw"],
];

// In-text keywords — last match wins. Used only as legacy fallback.
const IN_TEXT: Array<[RegExp, Outcome]> = [
  [/\b(VICTORY|VICTORIOUS|TRIUMPHED)\b/gi, "win"],
  [/\b(DEFEAT|DEFEATED|ROUTED|ANNIHILATED)\b/gi, "loss"],
  [/\b(STALEMATE|INCONCLUSIVE)\b/gi, "draw"],
  [/(勝利|大勝)/gu, "win"],
  [/(敗北|敗戦|惨敗)/gu, "loss"],
  [/(引き分け|引分|痛み分け|膠着)/gu, "draw"],
];

/** Strips markdown emphasis, list bullets and trailing punctuation from a line. */
function bareLine(line: string): string {
  return line
    .replace(/[*_#>`\-\s]/gu, "")
    .replace(/[.!?:。！？：]+$/u, "")
    .trim();
}

/**
 * Returns the parsed outcome, or null if nothing reliable was found.
 * Does NOT default to draw.
 */
export function parseOutcome(text: string): ParsedOutcome | null {
  if (!text || !text.trim()) return null;

  // Rule 0 — structured marker (highest confidence). Prefer the last marker.
  let markerMatch: RegExpExecArray | null = null;
  RESULT_MARKER.lastIndex = 0;
  let m: RegExpExecArray | null;
  const markerRe = new RegExp(RESULT_MARKER.source, "gi");
  while ((m = markerRe.exec(text)) !== null) {
    markerMatch = m;
  }
  if (markerMatch) {
    const token = markerMatch[1].toUpperCase();
    if (token === "SURVIVAL") {
      const days = markerMatch[2] ? parseInt(markerMatch[2], 10) : undefined;
      return { outcome: "survival", survivalDays: Number.isFinite(days) ? days : undefined };
    }
    if (token === "VICTORY" || token === "WIN") return { outcome: "win" };
    if (token === "DEFEAT" || token === "LOSS") return { outcome: "loss" };
    if (token === "DRAW" || token === "STALEMATE") return { outcome: "draw" };
  }

  // Rule 1 — a trailing line that is nothing but the verdict.
  const lines = text
    .split(/\r?\n/)
    .map((l) => l.trim())
    .filter((l) => l.length > 0);

  for (const line of lines.slice(-4).reverse()) {
    // Skip the structured marker line itself if still present.
    if (RESULT_MARKER.test(line)) continue;
    const bare = bareLine(line);
    if (!bare) continue;
    for (const [re, outcome] of STANDALONE) {
      if (re.test(bare)) return { outcome };
    }
  }

  // Rule 2 — last keyword anywhere in the text (legacy only).
  let bestIndex = -1;
  let bestOutcome: Outcome | null = null;
  for (const [re, outcome] of IN_TEXT) {
    re.lastIndex = 0;
    let match: RegExpExecArray | null;
    while ((match = re.exec(text)) !== null) {
      if (match.index >= bestIndex) {
        bestIndex = match.index;
        bestOutcome = outcome;
      }
      if (match.index === re.lastIndex) re.lastIndex++;
    }
  }

  if (bestOutcome !== null) return { outcome: bestOutcome };

  // Rule 3 — unparseable. Caller must error, not invent a draw.
  return null;
}

/** Remove structured result markers from player-facing report text. */
export function stripResultMarkers(text: string): string {
  return text
    .replace(new RegExp(RESULT_MARKER.source, "gi"), "")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}
