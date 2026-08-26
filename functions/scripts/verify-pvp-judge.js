/**
 * Offline verification of judgePvpMatch itself.
 *
 * verify-pvp-trigger.js stubs the judge, because what was broken there was the
 * guard deciding whether judging runs at all. That leaves the judge unproven:
 * whether it assembles a prompt, parses the model's verdict, and writes the
 * right document. This covers that half.
 *
 * The AI call and Firestore are stubbed, so this runs with no emulator, no
 * credentials, no network and no AI spend. What is under test is the real
 * compiled lib/battle/judgePvpMatch.
 *
 * Run: npm run verify:judge
 */
process.env.GEMINI_API_KEY = "not-used-the-ai-call-is-stubbed";
process.env.GCLOUD_PROJECT = "demo-steelverdict";

const admin = require("firebase-admin");

// ---------------------------------------------------------------- AI stub
const aiModule = require("../lib/utils/ai");
let aiCalls = [];
let nextAiResponse = "";
aiModule.callGeminiFlash = async (apiKey, systemPrompt, userMessage) => {
  aiCalls.push({ apiKey, systemPrompt, userMessage });
  return nextAiResponse;
};

// ------------------------------------------------------- game config stub
// assemblePrompt reads system_config/game_config. Serve a small config so the
// prompt assembles without network, and so we can assert what reached the model.
const promptModule = require("../lib/utils/prompt");

const CONFIG = {
  worldviews: {
    "1830_fantasy": {
      common_judgment: "JUDGMENT-RULES",
      worldview_description: "WORLD-DESCRIPTION",
    },
  },
  scenarios: {},
  mode_addons: { pvp: "PVP-MODE-ADDON" },
  ticket_costs: {},
  model_config: {},
  dev_uids: [],
};

// ------------------------------------------------------- firestore stub
// admin.firestore is a getter-only property, so plain assignment silently does
// nothing - the same trap as in verify-pvp-trigger.js.
let writes = [];
const originalFirestore = Object.getOwnPropertyDescriptor(admin, "firestore");

function installFirestoreStub() {
  const fake = () => ({
    collection: (col) => ({
      doc: (id) => ({
        update: async (patch) => {
          writes.push({ collection: col, id, patch });
        },
        get: async () => ({ exists: true, data: () => CONFIG }),
      }),
    }),
  });
  Object.defineProperty(admin, "firestore", {
    value: fake,
    configurable: true,
    writable: true,
  });
}

function restoreFirestore() {
  if (originalFirestore) {
    Object.defineProperty(admin, "firestore", originalFirestore);
  } else {
    delete admin.firestore;
  }
}

installFirestoreStub();

const { judgePvpMatch, parsePvpResponse } = require("../lib/battle/judgePvpMatch");

const A = "uid-alice";
const B = "uid-bob";

function match(extra) {
  return Object.assign(
    {
      playerAUid: A,
      playerBUid: B,
      playerAStrategy: "Hold the ridge with spearmen.",
      playerBStrategy: "Flank through the treeline at dawn.",
      playerAStats: { strength: 10, wisdom: 5 },
      playerBStats: { strength: 4, wisdom: 11 },
      playerARaceName: "Iron Kingdom",
      playerBRaceName: "Forest Clans",
      status: "active",
    },
    extra || {},
  );
}

let pass = 0;
let fail = 0;
function check(name, actual, expected) {
  if (actual === expected) {
    pass++;
    console.log(`  ok   ${name}`);
  } else {
    fail++;
    console.log(`  FAIL ${name} - expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}
function checkTrue(name, actual) {
  check(name, !!actual, true);
}

async function judge(response, m) {
  writes = [];
  aiCalls = [];
  nextAiResponse = response;
  // Clear the assembled-prompt cache between cases so each run reassembles.
  if (typeof promptModule.__clearForTests === "function") {
    promptModule.__clearForTests();
  }
  await judgePvpMatch("m1", m || match(), "key");
  return { write: writes[0], ai: aiCalls[0] };
}

(async () => {
  console.log("\n(2d) judgePvpMatch: what the judge actually writes\n");

  // --- the winning path -------------------------------------------------
  let r = await judge("WINNER: PLAYER A\nREPORT: Alice holds the ridge and breaks the flank.");
  check("writes to pvp_matches", r.write?.collection, "pvp_matches");
  check("writes to the right document", r.write?.id, "m1");
  check("player A wins -> winner is A's uid", r.write?.patch.winner, A);
  check("status becomes resolved", r.write?.patch.status, "resolved");
  check("short report is stored", r.write?.patch.shortReport,
    "Alice holds the ridge and breaks the flank.");
  checkTrue("resolvedAt is stamped", typeof r.write?.patch.resolvedAt === "number");
  check("exactly one write", writes.length, 1);

  r = await judge("WINNER: PLAYER B\nREPORT: Bob's flank lands first.");
  check("player B wins -> winner is B's uid", r.write?.patch.winner, B);

  r = await judge("WINNER: DRAW\nREPORT: Neither line breaks.");
  check("draw -> winner is the literal draw", r.write?.patch.winner, "draw");

  // --- the model going off-script ---------------------------------------
  r = await judge("The battle was long and neither side gave ground.");
  check("no verdict line -> draw, not a crash", r.write?.patch.winner, "draw");
  check("no REPORT line -> falls back to the text", r.write?.patch.shortReport,
    "The battle was long and neither side gave ground.");
  check("still resolves the match", r.write?.patch.status, "resolved");

  r = await judge("");
  check("empty response -> draw", r.write?.patch.winner, "draw");
  check("empty response -> still resolved, not stuck", r.write?.patch.status, "resolved");

  // A report longer than the 60-char cap
  const long = "WINNER: PLAYER A\nREPORT: " + "x".repeat(200);
  r = await judge(long);
  check("long report is capped at 60", r.write?.patch.shortReport.length, 60);

  // --- what reached the model -------------------------------------------
  r = await judge("WINNER: DRAW\nREPORT: even.");
  checkTrue("prompt carries the judgment rules", r.ai?.systemPrompt.includes("JUDGMENT-RULES"));
  checkTrue("prompt carries the world description", r.ai?.systemPrompt.includes("WORLD-DESCRIPTION"));
  checkTrue("prompt carries the pvp mode addon", r.ai?.systemPrompt.includes("PVP-MODE-ADDON"));
  checkTrue("both strategies reach the model",
    r.ai?.userMessage.includes("Hold the ridge") &&
    r.ai?.userMessage.includes("Flank through the treeline"));
  checkTrue("both race names reach the model",
    r.ai?.userMessage.includes("Iron Kingdom") &&
    r.ai?.userMessage.includes("Forest Clans"));

  // --- uid mapping is not positional ------------------------------------
  r = await judge("WINNER: PLAYER A\nREPORT: a wins.",
    match({ playerAUid: "uid-zoe", playerBUid: "uid-yan" }));
  check("winner uid follows the match, not a fixed value", r.write?.patch.winner, "uid-zoe");

  // --- parser directly ---------------------------------------------------
  console.log("\n  parsePvpResponse, directly:\n");
  check("lowercase verdict parses", parsePvpResponse("winner: player b\nreport: x", A, B).winner, B);
  check("verdict inside prose still parses",
    parsePvpResponse("After much fighting, WINNER: PLAYER B\nREPORT: x", A, B).winner, B);
  check("unknown player token -> draw",
    parsePvpResponse("WINNER: PLAYER C\nREPORT: x", A, B).winner, "draw");

  restoreFirestore();

  console.log(`\n${pass} passed, ${fail} failed\n`);
  process.exit(fail === 0 ? 0 : 1);
})().catch((e) => {
  restoreFirestore();
  console.error("harness error:", e);
  process.exit(1);
});
