/**
 * Offline verification of the scenario pack's choice (古代バトルパック).
 *
 * After buying the pack the player picks the scenarios it unlocks: exactly 5
 * different locked ones (all of them when fewer are locked), saved to the
 * account and final. This checks which scenarios count as locked and which
 * choices are refused. The saving itself (owner only, once only, moved with
 * the pack on a restore) is in verify-purchases.js, against the emulators.
 *
 * Run: npm run verify:pack
 */
const { PACK_SIZE, lockedScenarioIds, checkPicks } = require("../lib/purchase/scenarioPack");

let fail = 0;
function check(name, actual, expected) {
  if (JSON.stringify(actual) === JSON.stringify(expected)) {
    console.log(`  ok   ${name}`);
  } else {
    fail++;
    console.log(`  FAIL ${name} - expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

// The shape of system_config/game_config's scenarios (from the live copy, 28 Oct 2026).
const scenarios = {
  scenario_001: { isFree: true, isUnlocked: true },
  scenario_002: { isFree: false, isUnlocked: false },
  scenario_003: { isFree: false, isUnlocked: false },
  history_001: { isFree: false, isUnlocked: true },
  aces_004: { isFree: false, isUnlocked: false },
  aces_005: { is_free: false, is_unlocked: false },
  aces_006: {},
  aces_007: { scenarioId: "aces_007_real", isFree: false },
  broken: "not a scenario",
};
const locked = lockedScenarioIds(scenarios);

console.log("\nwhich scenarios are locked\n");
check("pack size is 5", PACK_SIZE, 5);
check("free or unlocked-for-everyone scenarios are not locked",
  ["scenario_001", "history_001"].map((id) => locked.has(id)), [false, false]);
check("snake_case flags and missing flags count as locked",
  ["aces_005", "aces_006"].map((id) => locked.has(id)), [true, true]);
check("the scenario's own scenarioId wins over its key (like the app)",
  [locked.has("aces_007_real"), locked.has("aces_007")], [true, false]);
check("6 locked scenarios", locked.size, 6);

console.log("\nwhich choices are accepted\n");
const five = ["scenario_002", "scenario_003", "aces_004", "aces_005", "aces_006"];
check("5 different locked scenarios: accepted", checkPicks(five, locked), { ids: five });
check("4: refused", checkPicks(five.slice(0, 4), locked), { reason: "wrong_count" });
check("6: refused", checkPicks([...five, "aces_007_real"], locked), { reason: "wrong_count" });
check("the same scenario twice: refused",
  checkPicks(["scenario_002", "scenario_002", "aces_004", "aces_005", "aces_006"], locked), { reason: "duplicate_picks" });
check("a free scenario: refused",
  checkPicks(["scenario_001", "scenario_003", "aces_004", "aces_005", "aces_006"], locked), { reason: "not_locked" });
check("an unknown scenario: refused",
  checkPicks(["nope", "scenario_003", "aces_004", "aces_005", "aces_006"], locked), { reason: "not_locked" });
check("not a list: refused", checkPicks("scenario_002", locked), { reason: "invalid_picks" });
check("an empty name: refused", checkPicks(["", "scenario_003", "aces_004", "aces_005", "aces_006"], locked), { reason: "invalid_picks" });
check("nothing sent: refused", checkPicks(undefined, locked), { reason: "invalid_picks" });

const three = lockedScenarioIds({ a: {}, b: {}, c: {}, d: { isFree: true } });
check("only 3 locked: all 3 are the choice", checkPicks(["a", "b", "c"], three), { ids: ["a", "b", "c"] });
check("only 3 locked: 2 is refused", checkPicks(["a", "b"], three), { reason: "wrong_count" });
check("nothing locked: nothing to pick", checkPicks([], new Set()), { reason: "nothing_to_pick" });

console.log(fail === 0 ? "\nAll checks passed.\n" : `\n${fail} check(s) failed.\n`);
process.exit(fail === 0 ? 0 : 1);
