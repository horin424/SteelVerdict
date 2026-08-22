/**
 * Offline verification of client issue (2): PvP matches were never judged.
 *
 * Drives the real compiled trigger through firebase-functions-test in offline
 * mode - no emulator, no credentials, no network, no AI spend. judgePvpMatch is
 * stubbed, so what is under test is precisely what was broken: the guard that
 * decides whether judging runs at all.
 *
 * Run: npm run verify:pvp
 */
process.env.GEMINI_API_KEY = "not-used-judging-is-stubbed";
process.env.GCLOUD_PROJECT = "demo-steelverdict";

const assert = require("node:assert");
const ft = require("firebase-functions-test")();

// Stub before requiring the trigger. The compiled trigger calls
// (0, judgePvpMatch_1.judgePvpMatch)(...), reading the property at call time,
// so replacing it on the module exports is enough.
const jpmModule = require("../lib/battle/judgePvpMatch");
let judged = [];
jpmModule.judgePvpMatch = async (matchId, match) => {
  judged.push({ matchId, match });
};

const { judgeCompletedPvpMatch } = require("../lib/battle/judgeCompletedPvpMatch");
const wrapped = ft.wrap(judgeCompletedPvpMatch);

const PATH = "pvp_matches/m1";
const A = "uid-alice";
const B = "uid-bob";

async function fire(before, after) {
  judged = [];
  const change = ft.makeChange(
    ft.firestore.makeDocumentSnapshot(before, PATH),
    ft.firestore.makeDocumentSnapshot(after, PATH),
  );
  await wrapped({ data: change, params: { matchId: "m1" } });
  return judged.length;
}

/** The guard exactly as it shipped, to show the bug is really what we said. */
function oldGuardWouldJudge(before, after) {
  if (before.status === "active" || after.status !== "active") return false;
  if (!after.playerAStrategy || !after.playerBStrategy) return false;
  return true;
}

let pass = 0, fail = 0;
function check(name, actual, expected) {
  if (actual === expected) { pass++; console.log(`  ok   ${name}`); }
  else { fail++; console.log(`  FAIL ${name} - expected ${expected}, got ${actual}`); }
}

(async () => {
  console.log("\n(2) PvP judging trigger\n");

  // --- the states a real match moves through ---
  const waiting = { status: "waiting", playerAUid: A };
  const joined  = { status: "active", playerAUid: A, playerBUid: B };
  const aOnly   = { ...joined, playerAStrategy: "Hold the ridge." };
  const bOnly   = { ...joined, playerBStrategy: "Flank at dawn." };
  const both    = { ...joined, playerAStrategy: "Hold the ridge.", playerBStrategy: "Flank at dawn." };
  const settled = { ...both, status: "resolved", winner: A, shortReport: "Alice holds." };

  check("player B joins, no strategies yet -> no judging",
    await fire(waiting, joined), 0);

  check("player A submits, still waiting on B -> no judging",
    await fire(joined, aOnly), 0);

  check("player B submits, pair complete -> JUDGES",
    await fire(aOnly, both), 1);

  check("submitted in the other order (B then A) -> JUDGES",
    await fire(bOnly, both), 1);

  check("both arrive in one write -> JUDGES",
    await fire(joined, both), 1);

  check("the judge's own result write -> does not re-enter",
    await fire(both, settled), 0);

  check("sweep already resolved it -> leaves it alone",
    await fire({ ...aOnly, status: "resolved" }, { ...both, status: "resolved" }), 0);

  check("match already timed out -> leaves it alone",
    await fire({ ...aOnly, status: "timeout" }, { ...both, status: "timeout" }), 0);

  // --- the match is handed to the judge intact ---
  await fire(aOnly, both);
  check("judge receives the match id", judged[0]?.matchId, "m1");
  check("judge receives player A's strategy", judged[0]?.match.playerAStrategy, "Hold the ridge.");
  check("judge receives player B's strategy", judged[0]?.match.playerBStrategy, "Flank at dawn.");

  // --- proof the reported bug was real ---
  console.log("\n  the shipped guard, on the same transitions:\n");
  check("  old guard: B joins -> no judging (agreed)",
    oldGuardWouldJudge(waiting, joined), false);
  check("  old guard: pair completes -> NEVER JUDGED  <- client issue (2)",
    oldGuardWouldJudge(aOnly, both), false);
  check("  old guard: other order -> NEVER JUDGED",
    oldGuardWouldJudge(bOnly, both), false);
  check("  old guard: one write -> NEVER JUDGED",
    oldGuardWouldJudge(joined, both), false);

  // --- winner parsing ---
  console.log("\n(2b) PvP winner parsing\n");
  const { parsePvpResponse } = jpmModule;
  const p = (t) => parsePvpResponse(t, A, B).winner;
  check("WINNER: PLAYER A", p("WINNER: PLAYER A\nREPORT: Alice holds the ridge."), A);
  check("WINNER: PLAYER B", p("WINNER: PLAYER B\nREPORT: Bob flanks."), B);
  check("WINNER: DRAW", p("WINNER: DRAW\nREPORT: Stalemate."), "draw");
  check("lowercase still parses", p("winner: player b\nreport: bob wins"), B);
  check("no verdict line -> draw", p("The battle was inconclusive."), "draw");
  check("report is extracted",
    parsePvpResponse("WINNER: DRAW\nREPORT: Both lines held.", A, B).shortReport,
    "Both lines held.");

  // ------------------------------------------------------------------
  // (2c) the hourly sweep. Same client issue: with both strategies
  // present it fell through and wrote "Both players failed to submit."
  // ------------------------------------------------------------------
  console.log("\n(2c) checkDeserters sweep\n");

  const admin = require("firebase-admin");
  const NOW = 1_700_000_000_000;

  function fakeDb(docs) {
    const writes = [];
    const chain = {
      where: () => chain,
      get: async () => ({
        empty: docs.length === 0,
        docs: docs.map((d) => ({ id: d.id, ref: { id: d.id }, data: () => d.data })),
      }),
    };
    return {
      writes,
      collection: () => chain,
      batch: () => ({
        update: (ref, patch) => writes.push({ id: ref.id, patch }),
        commit: async () => {},
      }),
    };
  }

  async function sweep(docs) {
    const db = fakeDb(docs);
    // admin.firestore is a getter-only property, so plain assignment silently
    // no-ops and the real SDK gets called instead.
    const original = Object.getOwnPropertyDescriptor(admin, "firestore");
    Object.defineProperty(admin, "firestore", {
      value: () => db,
      configurable: true,
      writable: true,
    });
    judged = [];
    try {
      const { checkDeserters } = require("../lib/pvp/checkDeserters");
      const wrappedSweep = ft.wrap(checkDeserters);
      await wrappedSweep({});
    } finally {
      // firestore is inherited from the namespace prototype, not an own
      // property, so there is usually nothing to put back - just unshadow it.
      if (original) Object.defineProperty(admin, "firestore", original);
      else delete admin.firestore;
    }
    return { writes: db.writes, judged };
  }

  const expired = { expiresAt: NOW - 1000, playerAUid: A, playerBUid: B };

  let r = await sweep([{ id: "w1", data: { ...expired, status: "waiting" } }]);
  check("waiting past deadline -> timeout", r.writes[0]?.patch.status, "timeout");
  check("waiting past deadline -> not judged", r.judged.length, 0);

  r = await sweep([{ id: "a1", data: { ...expired, status: "active", playerAStrategy: "Hold." } }]);
  check("only A submitted -> A wins by desertion", r.writes[0]?.patch.winner, A);
  check("only A submitted -> not judged", r.judged.length, 0);

  r = await sweep([{ id: "b1", data: { ...expired, status: "active", playerBStrategy: "Flank." } }]);
  check("only B submitted -> B wins by desertion", r.writes[0]?.patch.winner, B);

  r = await sweep([{ id: "n1", data: { ...expired, status: "active" } }]);
  check("genuinely nobody submitted -> draw", r.writes[0]?.patch.winner, "draw");
  check("genuinely nobody submitted -> honest report",
    r.writes[0]?.patch.shortReport, "Neither player submitted a strategy. No result.");

  r = await sweep([{
    id: "both1",
    data: { ...expired, status: "active", playerAStrategy: "Hold.", playerBStrategy: "Flank." },
  }]);
  check("BOTH submitted -> JUDGED, not written off", r.judged.length, 1);
  check("BOTH submitted -> no false-draw write", r.writes.length, 0);

  r = await sweep([
    { id: "m1", data: { ...expired, status: "active", playerAStrategy: "a", playerBStrategy: "b" } },
    { id: "m2", data: { ...expired, status: "active", playerAStrategy: "a", playerBStrategy: "b" } },
    { id: "m3", data: { ...expired, status: "waiting" } },
  ]);
  check("mixed batch -> both playable matches judged", r.judged.length, 2);
  check("mixed batch -> the waiting one still timed out", r.writes.length, 1);

  ft.cleanup();
  console.log(`\n${pass} passed, ${fail} failed\n`);
  process.exit(fail ? 1 : 0);
})().catch((e) => { console.error(e); process.exit(1); });
