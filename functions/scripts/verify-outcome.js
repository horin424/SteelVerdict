/* eslint-disable */
/**
 * Verification for parseOutcome. Run with:  npm run verify
 *
 * Deliberately dependency-free (node:assert only) so it works without adding a
 * test framework to a functions package that never had one.
 */
const assert = require("assert");
const { parseOutcome } = require("../lib/utils/outcome");

let pass = 0;
const failures = [];

function check(label, text, expected) {
  const actual = parseOutcome(text);
  try {
    assert.strictEqual(actual, expected);
    pass++;
  } catch {
    failures.push(`  ${label}\n     expected "${expected}", got "${actual}"`);
  }
}

// ── The bugs this replaces ───────────────────────────────────────────────────
// "WIN" is a substring of WING and DRAWING, and the old parser checked win
// first, so both of these returned "win" regardless of how the battle ended.

check(
  '"wing" must not read as a win',
  "The enemy's left wing collapsed, but our centre broke and the field was lost.\n\nDEFEAT",
  "loss",
);
check(
  '"drawing" must not read as a win',
  "Drawing the enemy into the valley cost us the initiative and the day.\n\nDEFEAT",
  "loss",
);
check(
  '"wing" alone is not a verdict',
  "The cavalry held the right wing throughout the engagement.",
  "draw",
);
check(
  '"drawing" alone is not a verdict',
  "Winter closed in while drawing up the siege lines.",
  "draw",
);

// ── Japanese: previously impossible to get anything but "draw" ───────────────

check("JA victory", "敵の防衛線を突破し、砦を制圧した。\n\n勝利", "win");
check("JA defeat", "我が軍は包囲され、壊滅した。\n\n敗北", "loss");
check("JA stalemate", "両軍とも決定打を欠いた。\n\n引き分け", "draw");
check("JA victory, in prose", "この戦いは我が軍の勝利に終わった。", "win");
check("JA defeat, in prose", "結果は惨敗であった。", "loss");

// ── The documented format: trailing keyword on its own line ──────────────────

check("trailing VICTORY", "A long report.\nMany lines.\n\nVICTORY", "win");
check("trailing DEFEAT", "A long report.\nMany lines.\n\nDEFEAT", "loss");
check("trailing STALEMATE", "A long report.\nMany lines.\n\nSTALEMATE", "draw");
check("trailing keyword in markdown bold", "Report text.\n\n**VICTORY**", "win");
check("trailing keyword with punctuation", "Report text.\n\nVICTORY!", "win");

// ── Last keyword wins, because reports narrate then conclude ─────────────────

check(
  "narrated loss then final victory",
  "Our vanguard was defeated at the ford. We regrouped and took the ridge. VICTORY",
  "win",
);
check(
  "narrated win then final defeat",
  "We won the first exchange, then the line broke entirely. DEFEAT",
  "loss",
);

// ── Fallbacks ────────────────────────────────────────────────────────────────

check("empty string", "", "draw");
check("no keywords at all", "The armies manoeuvred for three days.", "draw");

// ── Report ───────────────────────────────────────────────────────────────────

console.log(`\nparseOutcome: ${pass} passed, ${failures.length} failed`);
if (failures.length) {
  console.error("\nFAILURES:\n" + failures.join("\n"));
  process.exit(1);
}
console.log("All outcome parsing checks passed.\n");
