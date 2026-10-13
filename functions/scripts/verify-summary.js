/**
 * Offline verification of the battle summary (B22).
 *
 * The result card shows submitBattle's shortSummary as plain text. It was the
 * report's first sentence as written, markdown and all, so the card read
 * "# BATTLE REPORT ## The Siege ..." with literal **. Heading lines and rules
 * are now skipped and the marks removed.
 *
 * Run: npm run verify:summary
 */
process.env.GEMINI_API_KEY = "not-used";
process.env.CLAUDE_API_KEY = "not-used";
process.env.GCLOUD_PROJECT = "demo-steelverdict";

const { extractShortSummary } = require("../lib/battle/submitBattle");

let fail = 0;
function check(name, actual, expected) {
  if (actual === expected) {
    console.log(`  ok   ${name}`);
  } else {
    fail++;
    console.log(`  FAIL ${name} - expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

console.log("\n(B22) the summary on the result card is plain text\n");

check("headings skipped, bold marks removed",
  extractShortSummary("# BATTLE REPORT\n## The Siege of Aldric\n\nThe **left flank** held. Then the rain came.", "normal"),
  "The left flank held");
check("a list mark is not part of the sentence",
  extractShortSummary("# REPORT\n- Your cavalry broke through. More followed.", "normal"),
  "Your cavalry broke through");
check("a rule line is skipped",
  extractShortSummary("---\n*Dawn.* The walls fell.", "normal"),
  "Dawn");
check("Japanese heading and bold",
  extractShortSummary("# 戦闘報告\n\n**左翼**が崩れた。敵は退いた。", "normal"),
  "左翼が崩れた");
check("lines are joined with a space, not kept as breaks",
  extractShortSummary("The army\nadvanced at dawn. Later.", "normal"),
  "The army advanced at dawn");
check("plain text is unchanged",
  extractShortSummary("Victory at dawn. The enemy fled.", "normal"),
  "Victory at dawn");
check("tabletop: 60 characters of the plain text",
  extractShortSummary("# Tabletop\n" + "x".repeat(100), "tabletop"),
  "x".repeat(60));
const long = "word ".repeat(40).trim() + ".";
const cut = extractShortSummary(long, "normal");
check("a long sentence still ends on a whole word", cut.endsWith("word…"), true);

console.log(fail ? `\n${fail} check(s) FAILED\n` : "\nall checks passed\n");
process.exit(fail ? 1 : 0);
