/**
 * Offline verification of the daily AI limits (src/limits, release_scope 11).
 *
 * Part 1: the rules themselves (aiLimits.ts): reading the stored limits, the
 * counting per player and for the app, the new Japan day, dev_uids, each refusal.
 * Part 2: the wiring in submitBattle and generateWarHistory, driven end to end
 * through firebase-functions-test: which calls are counted and as what, where
 * the limits come from, and that a refused call reaches no AI and keeps no ticket.
 *
 * Firestore, the ticket helpers, the config, the AI and reserveAiCall itself are
 * stubbed, so this runs with no emulator, no credentials and no network. The
 * transaction in reserveAiCall is checked against the emulator in
 * verify-ai-limits-db.js.
 *
 * Run: npm run build && npm run verify:ailimits
 */
process.env.GEMINI_API_KEY = "not-used-the-ai-call-is-stubbed";
process.env.CLAUDE_API_KEY = "not-used-the-ai-call-is-stubbed";
process.env.GCLOUD_PROJECT = "demo-steelverdict";

const admin = require("firebase-admin");
const ft = require("firebase-functions-test")();
const { HttpsError } = require("firebase-functions/v2/https");
const { AI_LIMIT_DEFAULTS, readAiLimits, decideAiCall } = require("../lib/limits/aiLimits");

let fail = 0;
function check(name, actual, expected) {
  if (JSON.stringify(actual) === JSON.stringify(expected)) {
    console.log(`  ok   ${name}`);
  } else {
    fail++;
    console.log(`  FAIL ${name} - expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

// ── Part 1: aiLimits.ts ─────────────────────────────────────────────────────────

function part1() {
  console.log("\nreading the stored limits (game_config ai_daily_limits)\n");
  const D = AI_LIMIT_DEFAULTS;
  check("the defaults are 30 / 100 / 3,000", D, { freePerUser: 30, allPerUser: 100, appTotal: 3000 });
  check("no section: the defaults", readAiLimits(undefined), D);
  check("null: the defaults", readAiLimits(null), D);
  check("an empty section: the defaults", readAiLimits({}), D);
  check("a list instead of a section: the defaults", readAiLimits([1, 2, 3]), D);
  check("all three set", readAiLimits({ free_per_user: 10, all_per_user: 50, app_total: 500 }),
    { freePerUser: 10, allPerUser: 50, appTotal: 500 });
  check("one set, the others default", readAiLimits({ app_total: 800 }),
    { freePerUser: 30, allPerUser: 100, appTotal: 800 });
  check("0 is kept (none allowed)", readAiLimits({ free_per_user: 0, all_per_user: 0, app_total: 0 }),
    { freePerUser: 0, allPerUser: 0, appTotal: 0 });
  check("negative, text and NaN: each its default",
    readAiLimits({ free_per_user: -1, all_per_user: "100", app_total: NaN }), D);
  check("Infinity: the default", readAiLimits({ app_total: Infinity }).appTotal, 3000);
  check("a fraction is rounded down", readAiLimits({ free_per_user: 12.7 }).freePerUser, 12);
  check("camelCase keys are not read", readAiLimits({ freePerUser: 1 }), D);

  console.log("\ncounting and refusing\n");
  const L = { freePerUser: 2, allPerUser: 3, appTotal: 5 };
  const TODAY = "2026-11-22";
  const NOW = 1795400000000;
  const FREE = { free: true, dev: false };
  const PAID = { free: false, dev: false };
  const user = (date, all, free) => ({ uid: "u1", ticketCount: 3, aiCallsDate: date, aiCallsCount: all, aiFreeCallsCount: free });
  const usage = (count, free) => ({ day: TODAY, count, free, updatedAt: 1 });
  const decide = (call, u, g, limits = L) => decideAiCall(call, limits, u, g, TODAY, NOW);

  check("first free call of the day: counted for the player and the app", decide(FREE, { uid: "u1" }, undefined), {
    allowed: true,
    user: { aiCallsDate: TODAY, aiCallsCount: 1, aiFreeCallsCount: 1 },
    usage: { day: TODAY, count: 1, free: 1, updatedAt: NOW },
  });
  check("first paid call: not in the free counts", decide(PAID, { uid: "u1" }, undefined), {
    allowed: true,
    user: { aiCallsDate: TODAY, aiCallsCount: 1, aiFreeCallsCount: 0 },
    usage: { day: TODAY, count: 1, free: 0, updatedAt: NOW },
  });
  check("adds to today's counts", decide(FREE, user(TODAY, 1, 1), usage(3, 2)), {
    allowed: true,
    user: { aiCallsDate: TODAY, aiCallsCount: 2, aiFreeCallsCount: 2 },
    usage: { day: TODAY, count: 4, free: 3, updatedAt: NOW },
  });
  check("free limit reached: a free call is refused", decide(FREE, user(TODAY, 2, 2), usage(2, 2)),
    { allowed: false, code: "DAILY_FREE_LIMIT", limit: 2 });
  check("free limit reached: a paid call still goes", decide(PAID, user(TODAY, 2, 2), usage(2, 2)).allowed, true);
  check("limit for all calls reached: a paid call is refused", decide(PAID, user(TODAY, 3, 0), usage(3, 0)),
    { allowed: false, code: "DAILY_AI_LIMIT", limit: 3 });
  check("limit for all calls reached: a free call is refused too", decide(FREE, user(TODAY, 3, 0), usage(3, 0)),
    { allowed: false, code: "DAILY_AI_LIMIT", limit: 3 });
  check("yesterday's counts don't count today", decide(FREE, user("2026-11-21", 3, 2), usage(0, 0)), {
    allowed: true,
    user: { aiCallsDate: TODAY, aiCallsCount: 1, aiFreeCallsCount: 1 },
    usage: { day: TODAY, count: 1, free: 1, updatedAt: NOW },
  });
  check("the app's limit reached: refused for a player with none used", decide(PAID, { uid: "u2" }, usage(5, 0)),
    { allowed: false, code: "APP_AI_LIMIT", limit: 5 });
  check("both reached: the player's own limit is named", decide(FREE, user(TODAY, 2, 2), usage(5, 5)),
    { allowed: false, code: "DAILY_FREE_LIMIT", limit: 2 });
  check("dev_uids: past the player's limits, still allowed and counted",
    decide({ free: true, dev: true }, user(TODAY, 50, 40), usage(4, 1)), {
      allowed: true,
      user: { aiCallsDate: TODAY, aiCallsCount: 51, aiFreeCallsCount: 41 },
      usage: { day: TODAY, count: 5, free: 2, updatedAt: NOW },
    });
  check("dev_uids: the app's limit still applies", decide({ free: false, dev: true }, user(TODAY, 0, 0), usage(5, 0)),
    { allowed: false, code: "APP_AI_LIMIT", limit: 5 });
  const ZERO = { freePerUser: 0, allPerUser: 0, appTotal: 0 };
  check("free limit 0: no free call", decide(FREE, { uid: "u1" }, undefined, { ...L, freePerUser: 0 }).code,
    "DAILY_FREE_LIMIT");
  check("limit for all calls 0: no call", decide(PAID, { uid: "u1" }, undefined, { ...L, allPerUser: 0 }).code,
    "DAILY_AI_LIMIT");
  check("app limit 0: no call, even for dev_uids", decide({ free: false, dev: true }, { uid: "u1" }, undefined, ZERO).code,
    "APP_AI_LIMIT");
  check("stored counts that aren't numbers count as 0", decide(PAID, { aiCallsDate: TODAY, aiCallsCount: "7", aiFreeCallsCount: -3 },
    { count: null, free: "x" }), {
    allowed: true,
    user: { aiCallsDate: TODAY, aiCallsCount: 1, aiFreeCallsCount: 0 },
    usage: { day: TODAY, count: 1, free: 0, updatedAt: NOW },
  });
}

// ── Part 2: the wiring in the two callables ─────────────────────────────────────

// Firestore is reached only by submitBattle's lastLoginAt and win/loss writes here.
// admin.firestore is a getter-only property on the namespace: plain assignment no-ops.
const quietDb = { collection: () => ({ doc: () => ({ update: async () => {} }) }) };
const firestoreStub = () => quietDb;
firestoreStub.FieldValue = { increment: (n) => n };
Object.defineProperty(admin, "firestore", { value: firestoreStub, configurable: true, writable: true });

const fsModule = require("../lib/utils/firestore");
let player = null;
let charged = [];
let refunded = [];
fsModule.ensureUserDoc = async () => {};
fsModule.getUser = async () => player;
fsModule.deductTickets = async (uid, cost) => { charged.push(cost); return 10; };
fsModule.addTickets = async (uid, amount) => { refunded.push(amount); return 10; };

const promptModule = require("../lib/utils/prompt");
let config = {};
promptModule.fetchRemoteConfigData = async () => config;
promptModule.assemblePrompt = async () => "PROMPT";

const aiModule = require("../lib/utils/ai");
let aiCalls = 0;
let aiFails = false;
const answer = (text) => async () => {
  aiCalls++;
  if (aiFails) throw new Error("stubbed AI failure");
  return text;
};
aiModule.callGemini = answer("The ridge held until dawn.\n[[RESULT:VICTORY]]");
aiModule.callClaude = answer("The ridge held until dawn.\n[[RESULT:VICTORY]]");

const limitsModule = require("../lib/limits/reserveAiCall");
let reserved = [];
let limitAnswer = "allow"; // "allow", "refuse" or "fail"
limitsModule.reserveAiCall = async (uid, call, limits) => {
  reserved.push({ uid, ...call, limits });
  if (limitAnswer === "refuse") throw new HttpsError("resource-exhausted", "DAILY_AI_LIMIT:100");
  if (limitAnswer === "fail") throw new Error("Firestore is down");
};

const { submitBattle } = require("../lib/battle/submitBattle");
const { generateWarHistory } = require("../lib/history/generateWarHistory");
const battle = ft.wrap(submitBattle);
const chronicle = ft.wrap(generateWarHistory);

const FREE_PLAYER = { uid: "u1", ticketCount: 10, subscriptionTier: "free", isBossEnabled: false };
const COMMANDER = { ...FREE_PLAYER, subscriptionTier: "sub500" };
const WARLORD = { ...FREE_PLAYER, subscriptionTier: "sub3000", isBossEnabled: true };
const DEFAULTS = { freePerUser: 30, allPerUser: 100, appTotal: 3000 };

function setUp({ who = FREE_PLAYER, cfg = {}, limit = "allow", aiFail = false } = {}) {
  player = who;
  config = { ticket_costs: {}, model_config: {}, dev_uids: [], ...cfg };
  limitAnswer = limit;
  aiFails = aiFail;
  charged = [];
  refunded = [];
  reserved = [];
  aiCalls = 0;
}

async function outcome(run, data) {
  try {
    await run({ auth: { uid: "u1", token: {} }, data });
    return { code: "ok" };
  } catch (e) {
    return { code: e.code, message: e.message };
  }
}

const playBattle = (gameMode, extra = {}) => outcome(battle, {
  playerStrategy: "Hold the ridge and wait for dawn.", scenarioId: "s1", gameMode, raceStats: { strength: 5 }, ...extra,
});
const writeChronicle = (extra = {}) => outcome(chronicle, {
  battleTitle: "決戦", playerStrategy: "左翼から包囲する", raceStats: { 攻撃: 8, 防御: 6 },
  raceName: "鉄の軍団", opponentName: "敵", outcome: "win", locale: "ja", ...extra,
});
const counted = () => reserved.map(({ free, dev }) => ({ free, dev }));

async function part2() {
  console.log("\nsubmitBattle: what is counted\n");
  for (const mode of ["practice", "tabletop", "history_puzzle"]) {
    setUp();
    const r = await playBattle(mode);
    check(`${mode}: played, counted once as free, no ticket`, [r.code, counted(), charged, aiCalls],
      ["ok", [{ free: true, dev: false }], [], 1]);
  }
  setUp();
  let r = await playBattle("normal");
  check("normal: played, counted once as paid, 1 ticket", [r.code, counted(), charged, aiCalls],
    ["ok", [{ free: false, dev: false }], [1], 1]);
  setUp({ who: COMMANDER });
  r = await playBattle("epic");
  check("epic (Commander): counted as paid, 3 tickets", [r.code, counted(), charged], ["ok", [{ free: false, dev: false }], [3]]);
  setUp({ cfg: { ticket_costs: { practice: 1 } } });
  r = await playBattle("practice");
  check("practice made to cost 1 ticket: counted as paid", [r.code, counted(), charged], ["ok", [{ free: false, dev: false }], [1]]);
  setUp({ cfg: { dev_uids: ["u1"] } });
  r = await playBattle("normal");
  check("dev_uids, normal: no ticket, counted as dev", [r.code, counted(), charged], ["ok", [{ free: false, dev: true }], []]);
  setUp({ cfg: { dev_uids: ["u1"] } });
  r = await playBattle("practice");
  check("dev_uids, practice: counted as free and dev", counted(), [{ free: true, dev: true }]);

  console.log("\nsubmitBattle: the limits come from game_config\n");
  setUp();
  await playBattle("practice");
  check("no ai_daily_limits: the defaults", reserved[0].limits, DEFAULTS);
  setUp({ cfg: { ai_daily_limits: { free_per_user: 5, app_total: "lots" } } });
  await playBattle("practice");
  check("free_per_user 5 is used, an invalid app_total falls back", reserved[0].limits,
    { freePerUser: 5, allPerUser: 100, appTotal: 3000 });

  console.log("\nsubmitBattle: a refused or failed count\n");
  setUp({ limit: "refuse" });
  r = await playBattle("normal");
  check("normal, refused: the code reaches the app, the ticket comes back, no AI",
    [r.code, r.message, charged, refunded, aiCalls], ["resource-exhausted", "DAILY_AI_LIMIT:100", [1], [1], 0]);
  setUp({ limit: "refuse" });
  r = await playBattle("practice");
  check("practice, refused: nothing to give back, no AI", [r.code, charged, refunded, aiCalls],
    ["resource-exhausted", [], [], 0]);
  setUp({ limit: "fail" });
  r = await playBattle("normal");
  check("the count itself fails: an error, the ticket comes back, no AI", [r.code, charged, refunded, aiCalls],
    ["internal", [1], [1], 0]);
  setUp({ aiFail: true });
  r = await playBattle("normal");
  check("the AI fails after the count: the ticket comes back, the count stays", [r.code, reserved.length, refunded],
    ["internal", 1, [1]]);

  console.log("\nsubmitBattle: not counted when refused before the AI\n");
  setUp();
  r = await playBattle("normal", { playerStrategy: "Go." });
  check("strategy too short: refused, not counted", [r.code, reserved.length, charged], ["invalid-argument", 0, []]);
  setUp();
  r = await playBattle("epic");
  check("epic without the perk: refused, not counted", [r.message, reserved.length, charged], ["MODE_LOCKED", 0, []]);
  setUp({ who: WARLORD });
  r = await playBattle("boss");
  check("boss with the perk: counted once", [r.code, reserved.length], ["ok", 1]);

  console.log("\ngenerateWarHistory\n");
  setUp();
  r = await writeChronicle();
  check("a chronicle: counted once as paid, 3 tickets, the AI once", [r.code, counted(), charged, aiCalls],
    ["ok", [{ free: false, dev: false }], [3], 1]);
  setUp({ who: WARLORD });
  r = await writeChronicle();
  check("on the unlimited plan: no ticket, still counted as paid", [r.code, counted(), charged],
    ["ok", [{ free: false, dev: false }], []]);
  setUp({ cfg: { dev_uids: ["u1"] } });
  r = await writeChronicle();
  check("dev_uids: counted as dev (and charged as today)", [r.code, counted(), charged], ["ok", [{ free: false, dev: true }], [3]]);
  setUp({ cfg: { ai_daily_limits: { all_per_user: 40 } } });
  await writeChronicle();
  check("the limits from game_config", reserved[0].limits, { freePerUser: 30, allPerUser: 40, appTotal: 3000 });
  setUp({ limit: "refuse" });
  r = await writeChronicle();
  check("refused: the code reaches the app, the 3 tickets come back, no AI",
    [r.code, r.message, charged, refunded, aiCalls], ["resource-exhausted", "DAILY_AI_LIMIT:100", [3], [3], 0]);
  setUp({ who: WARLORD, limit: "refuse" });
  r = await writeChronicle();
  check("refused on the unlimited plan: nothing to give back", [r.code, refunded, aiCalls], ["resource-exhausted", [], 0]);
  setUp({ limit: "fail" });
  r = await writeChronicle();
  check("the count itself fails: an error, the tickets come back, no AI", [r.code, refunded, aiCalls], ["internal", [3], 0]);
  setUp();
  r = await writeChronicle({ raceStats: undefined });
  check("missing raceStats: refused, not counted, nothing charged", [r.code, reserved.length, charged],
    ["invalid-argument", 0, []]);
}

(async () => {
  part1();
  await part2();
  ft.cleanup();
  console.log(fail ? `\n${fail} check(s) FAILED\n` : "\nall checks passed\n");
  process.exit(fail ? 1 : 0);
})();
