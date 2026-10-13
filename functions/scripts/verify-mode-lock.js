/**
 * Offline verification of B31: Epic and Boss are enforced by the server.
 *
 * submitBattle used to charge tickets for any game mode without looking at the
 * player, so the Epic and Boss locks existed only in the app. Now Epic needs a
 * paid tier and Boss needs isBossEnabled, checked before any ticket is charged.
 *
 * Drives the real compiled submitBattle through firebase-functions-test in
 * offline mode. The user record, the ticket helpers, the game config and the AI
 * are stubbed, so this runs with no emulator, no credentials, no network and no
 * AI spend.
 *
 * Run: npm run verify:modes
 */
process.env.GEMINI_API_KEY = "not-used-the-ai-call-is-stubbed";
process.env.CLAUDE_API_KEY = "not-used-the-ai-call-is-stubbed";
process.env.GCLOUD_PROJECT = "demo-steelverdict";

const ft = require("firebase-functions-test")();

// Stub on the module exports before requiring submitBattle. The compiled code
// calls (0, firestore_1.getUser)(...), reading the property at call time.
const fsModule = require("../lib/utils/firestore");
let player = null;
let charged = [];
let refunded = [];
fsModule.ensureUserDoc = async () => {};
fsModule.getUser = async () => {
  if (!player) throw new Error("no user stubbed");
  return player;
};
fsModule.deductTickets = async (uid, cost) => {
  charged.push(cost);
  return 10;
};
fsModule.addTickets = async (uid, amount) => {
  refunded.push(amount);
  return 10;
};

const promptModule = require("../lib/utils/prompt");
promptModule.fetchRemoteConfigData = async () => ({
  ticket_costs: {},
  model_config: {},
  dev_uids: [],
});
promptModule.assemblePrompt = async () => "PROMPT";

// The AI call fails on purpose. A battle that got past the lock reaches it, is
// refunded and ends with "AI service error"; a refused one never gets there.
const aiModule = require("../lib/utils/ai");
aiModule.callGemini = async () => {
  throw new Error("stubbed AI");
};
aiModule.callClaude = async () => {
  throw new Error("stubbed AI");
};

const { submitBattle } = require("../lib/battle/submitBattle");
const wrapped = ft.wrap(submitBattle);

async function play(gameMode, who) {
  player = who;
  charged = [];
  refunded = [];
  try {
    await wrapped({
      auth: { uid: "uid-player", token: {} },
      data: {
        playerStrategy: "Hold the ridge and wait for dawn.",
        scenarioId: "s1",
        gameMode,
        raceStats: { strength: 5 },
      },
    });
    return { result: "played", charged: charged.length };
  } catch (e) {
    const locked = e.message === "MODE_LOCKED";
    return {
      result: locked ? "locked" : "played",
      code: locked ? e.code : undefined,
      charged: charged.length,
    };
  }
}

let fail = 0;
function check(name, actual, expected) {
  const ok = JSON.stringify(actual) === JSON.stringify(expected);
  if (ok) {
    console.log(`  ok   ${name}`);
  } else {
    fail++;
    console.log(`  FAIL ${name} - expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

const FREE = { subscriptionTier: "free", isBossEnabled: false };
const COMMANDER = { subscriptionTier: "sub500", isBossEnabled: false };
const WARLORD = { subscriptionTier: "sub3000", isBossEnabled: true };
const LEGACY = { isBossEnabled: false }; // no subscriptionTier field at all

(async () => {
  console.log("\n(B31) submitBattle: Epic and Boss are enforced by the server\n");

  const locked = { result: "locked", code: "permission-denied", charged: 0 };
  check("free player, Epic: refused, nothing charged", await play("epic", FREE), locked);
  check("free player, Boss: refused, nothing charged", await play("boss", FREE), locked);
  check("no tier recorded, Epic: refused as free", await play("epic", LEGACY), locked);
  check("Commander (¥500), Boss without the unlock: refused", await play("boss", COMMANDER), locked);

  const epicByCommander = await play("epic", COMMANDER);
  check("Commander (¥500), Epic: allowed and charged", epicByCommander.result === "played" && epicByCommander.charged === 1, true);
  const bossByWarlord = await play("boss", WARLORD);
  check("Warlord with the Boss unlock, Boss: allowed and charged", bossByWarlord.result === "played" && bossByWarlord.charged === 1, true);
  const normalByFree = await play("normal", FREE);
  check("free player, Normal: unaffected", normalByFree.result, "played");

  ft.cleanup();
  console.log(fail ? `\n${fail} check(s) FAILED\n` : "\nall checks passed\n");
  process.exit(fail ? 1 : 0);
})();
