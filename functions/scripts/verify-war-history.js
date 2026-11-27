/**
 * Offline verification: generateWarHistory never keeps tickets for a chronicle it didn't write.
 *
 * The client found (19 Nov 2026) that calling it without raceStats took 3 tickets, then failed with a
 * 500 and kept them: the inputs were checked only partly, and only an AI error gave the tickets back.
 * Now the inputs are checked before any charge, and any failure after the charge gives them back, once.
 *
 * Firestore, Auth and the AI are stubbed, so this runs with no emulator, no credentials and no network.
 * The callable is driven through firebase-functions-test, end to end.
 *
 * Run: npm run verify:warhistory
 */
process.env.GCLOUD_PROJECT = "demo-steelverdict";
process.env.CLAUDE_API_KEY = "test-key";

const admin = require("firebase-admin");
const ft = require("firebase-functions-test")();

let docs = {};
const db = {
  collection: () => ({
    doc: (id) => ({
      id,
      get: async () => ({ exists: docs[id] !== undefined, data: () => docs[id] }),
      create: async (data) => { docs[id] = data; },
    }),
  }),
  runTransaction: async (fn) => fn({
    get: async (ref) => ({ exists: docs[ref.id] !== undefined, data: () => docs[ref.id] }),
    update: (ref, patch) => { docs[ref.id] = { ...docs[ref.id], ...patch }; },
  }),
};
// Both are getter-only properties on the namespace: plain assignment no-ops.
Object.defineProperty(admin, "firestore", { value: () => db, configurable: true, writable: true });
Object.defineProperty(admin, "auth", { value: () => ({ getUser: async (uid) => ({ uid }) }), configurable: true, writable: true });

// The AI and the world's prompt, replaced before the function is loaded.
const ai = require("../lib/utils/ai");
const prompt = require("../lib/utils/prompt");
let aiResult = "";
let aiCalls = 0;
let aiModel = null;
ai.callClaude = async (_key, _system, _user, model) => {
  aiCalls++;
  aiModel = model;
  if (aiResult instanceof Error) throw aiResult;
  return aiResult;
};
prompt.assemblePrompt = async () => "";
// The daily AI limits have their own checks (verify-ai-limits.js); here every
// chronicle is within them.
require("../lib/limits/reserveAiCall").reserveAiCall = async () => {};

const { generateWarHistory } = require("../lib/history/generateWarHistory");
const wrapped = ft.wrap(generateWarHistory);

const VALID = {
  battleTitle: "決戦", playerStrategy: "左翼から包囲する", raceStats: { 攻撃: 8, 防御: 6 },
  raceName: "鉄の軍団", opponentName: "敵", outcome: "win", locale: "ja",
};

function reset(tickets, tier = "free") {
  docs = { u1: { uid: "u1", ticketCount: tickets, subscriptionTier: tier } };
  aiResult = "戦史の本文。";
  aiCalls = 0;
}

let fail = 0;
function check(name, actual, expected) {
  if (JSON.stringify(actual) === JSON.stringify(expected)) {
    console.log(`  ok   ${name}`);
  } else {
    fail++;
    console.log(`  FAIL ${name} - expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}
async function call(data) {
  try {
    const result = await wrapped({ auth: { uid: "u1", token: {} }, data });
    return { code: "ok", result };
  } catch (e) {
    return { code: e.code || e.message };
  }
}

(async () => {
  console.log("\ngenerateWarHistory: tickets are taken only for a chronicle that was written\n");

  reset(10);
  let r = await call(VALID);
  check("written -> ok", r.code, "ok");
  check("written -> 3 tickets taken", docs.u1.ticketCount, 7);
  check("written -> the text comes back", r.result?.chronicleText, "戦史の本文。");
  check("no 戦史 model set: Claude Haiku", aiModel, "claude-haiku-4-5-20251001");

  reset(10);
  const { raceStats, ...noStats } = VALID;
  r = await call(noStats);
  check("no raceStats (the client's call) -> invalid-argument", r.code, "invalid-argument");
  check("no raceStats -> no ticket taken", docs.u1.ticketCount, 10);
  check("no raceStats -> the AI isn't asked", aiCalls, 0);

  for (const [label, data] of [
    ["raceStats not an object", { ...VALID, raceStats: "8,6" }],
    ["no playerStrategy", { ...VALID, playerStrategy: "" }],
    ["raceName not text", { ...VALID, raceName: 42 }],
  ]) {
    reset(10);
    r = await call(data);
    check(`${label} -> invalid-argument, no ticket taken`, [r.code, docs.u1.ticketCount], ["invalid-argument", 10]);
  }

  reset(10);
  aiResult = new Error("Claude 529 overloaded");
  r = await call(VALID);
  check("AI error -> internal", r.code, "internal");
  check("AI error -> the 3 tickets given back, once", docs.u1.ticketCount, 10);

  reset(10);
  aiResult = "   ";
  r = await call(VALID);
  check("empty text -> internal", r.code, "internal");
  check("empty text -> the 3 tickets given back, once", docs.u1.ticketCount, 10);

  reset(10);
  aiResult = new TypeError("something unexpected");
  r = await call(VALID);
  check("any other failure after the charge -> internal", r.code, "internal");
  check("any other failure -> the 3 tickets given back, once", docs.u1.ticketCount, 10);

  reset(2);
  r = await call(VALID);
  check("2 tickets -> resource-exhausted, nothing taken", [r.code, docs.u1.ticketCount], ["resource-exhausted", 2]);

  reset(0, "sub3000");
  r = await call(VALID);
  check("Warlord (sub3000) -> free, written", [r.code, docs.u1.ticketCount, r.result?.ticketsConsumed], ["ok", 0, 0]);

  // Last: the config read here is then cached for 5 minutes.
  reset(10);
  docs.game_config = { model_config: { war_history: "claude-sonnet-4-5" } };
  r = await call(VALID);
  check("the 戦史 model set in the PC admin is used", [r.code, aiModel], ["ok", "claude-sonnet-4-5"]);

  ft.cleanup();
  console.log(fail ? `\n${fail} check(s) FAILED\n` : "\nall checks passed\n");
  process.exit(fail ? 1 : 0);
})();
