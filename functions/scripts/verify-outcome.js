/* eslint-disable */
/**
 * Verification for parseOutcome. Run with:  npm run verify
 */
const assert = require("assert");
const { parseOutcome, stripResultMarkers } = require("../lib/utils/outcome");

let pass = 0;
const failures = [];

function check(label, text, expectedOutcome, expectedDays) {
  const actual = parseOutcome(text);
  try {
    if (expectedOutcome === null) {
      assert.strictEqual(actual, null);
    } else {
      assert.ok(actual, `expected outcome but got null for: ${label}`);
      assert.strictEqual(actual.outcome, expectedOutcome);
      if (expectedDays !== undefined) {
        assert.strictEqual(actual.survivalDays, expectedDays);
      }
    }
    pass++;
  } catch (e) {
    failures.push(`  ${label}\n     ${e.message}`);
  }
}

// Structured markers
check("marker VICTORY", "Long report.\n\n[[RESULT:VICTORY]]", "win");
check("marker DEFEAT", "Long report.\n\n[[RESULT:DEFEAT]]", "loss");
check("marker DRAW", "Long report.\n\n[[RESULT:DRAW]]", "draw");
check("marker STALEMATE", "Long report.\n\n[[RESULT:STALEMATE]]", "draw");
check(
  "marker SURVIVAL",
  "You held the walls for seventeen days.\n\n[[RESULT:SURVIVAL|days=17]]",
  "survival",
  17,
);

// Must not treat "wing" / "drawing" as victory
check(
  '"wing" with trailing DEFEAT',
  "The enemy's left wing collapsed, but our centre broke.\n\nDEFEAT",
  "loss",
);
check(
  '"drawing" with trailing DEFEAT',
  "Drawing the enemy into the valley cost us the day.\n\nDEFEAT",
  "loss",
);

// Japanese trailing keywords
check("JA victory", "敵の防衛線を突破し、砦を制圧した。\n\n勝利", "win");
check("JA defeat", "我が軍は包囲され、壊滅した。\n\n敗北", "loss");
check("JA stalemate", "両軍とも決定打を欠いた。\n\n引き分け", "draw");

// Legacy trailing English
check("trailing VICTORY", "A long report.\nMany lines.\n\nVICTORY", "win");
check("trailing DEFEAT", "A long report.\nMany lines.\n\nDEFEAT", "loss");
check("trailing STALEMATE", "A long report.\nMany lines.\n\nSTALEMATE", "draw");

// Marker preferred over narrative keywords
check(
  "narrative defeat word but marker victory",
  "The vanguard was defeated at the ford, then we took the ridge.\n\n[[RESULT:VICTORY]]",
  "win",
);

// Unparseable must be null — NOT draw
check("empty string", "", null);
check("no keywords", "The armies manoeuvred for three days.", null);

// strip markers
const stripped = stripResultMarkers("Report body.\n\n[[RESULT:VICTORY]]\n");
try {
  assert.strictEqual(stripped.includes("RESULT"), false);
  assert.ok(stripped.includes("Report body"));
  pass++;
} catch (e) {
  failures.push(`  stripResultMarkers\n     ${e.message}`);
}

console.log(`\nparseOutcome: ${pass} passed, ${failures.length} failed`);
if (failures.length) {
  console.error("\nFAILURES:\n" + failures.join("\n"));
  process.exit(1);
}
console.log("All outcome parsing checks passed.\n");
