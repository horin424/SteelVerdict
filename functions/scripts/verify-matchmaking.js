/**
 * Offline verification of B3: PvP matchmaking checks the race and joins safely.
 *
 * findOrCreatePvpMatch took any stats and any name, so a modified client could
 * enter PvP with 999 points. It also joined a waiting match with a plain
 * update: two players who found the same match at once both "joined", and the
 * second replaced the first as player B. Now the race gets solo play's checks,
 * and joining runs in a transaction that moves on when the match is taken.
 *
 * Drives the real compiled function through firebase-functions-test in offline
 * mode, with Firestore stubbed: no emulator, no credentials, no network.
 *
 * Run: npm run verify:matchmaking
 */
process.env.GCLOUD_PROJECT = "demo-steelverdict";

const admin = require("firebase-admin");
const ft = require("firebase-functions-test")();
const { findOrCreatePvpMatch } = require("../lib/pvp/findOrCreatePvpMatch");
const wrapped = ft.wrap(findOrCreatePvpMatch);

const ME = "uid-me";
const NOW = Date.now();

// `waiting` is what the query returns; `current` is what a transaction reads
// a moment later (another player may have joined in between).
function fakeDb({ waiting = [], current = {}, users = {} } = {}) {
  const joins = [];
  const created = [];
  const state = Object.fromEntries(waiting.map((m) => [m.matchId, m]));
  Object.assign(state, current);
  const query = {
    where: () => query,
    orderBy: () => query,
    limit: () => query,
    get: async () => ({
      docs: waiting.map((m) => ({ id: m.matchId, ref: { id: m.matchId }, data: () => m })),
    }),
  };
  return {
    joins,
    created,
    collection: (col) => col === "users"
      ? { doc: (id) => ({ get: async () => ({ data: () => users[id] }) }) }
      : { ...query, doc: (id) => ({ id, set: async (d) => created.push(d) }) },
    runTransaction: async (fn) => fn({
      get: async (ref) => ({ data: () => state[ref.id] }),
      update: (ref, patch) => joins.push({ id: ref.id, patch }),
    }),
  };
}

async function find(data, dbSetup) {
  const db = fakeDb(dbSetup);
  const original = Object.getOwnPropertyDescriptor(admin, "firestore");
  Object.defineProperty(admin, "firestore", { value: () => db, configurable: true, writable: true });
  try {
    const result = await wrapped({ auth: { uid: ME, token: {} }, data });
    return { result, joins: db.joins, created: db.created };
  } catch (e) {
    return { error: e.message, code: e.code, joins: db.joins, created: db.created };
  } finally {
    if (original) Object.defineProperty(admin, "firestore", original);
    else delete admin.firestore;
  }
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

const RACE = { raceName: " Iron Kingdom ", raceStats: { strength: 10, wisdom: 10, speed: 10 } };
const waitingMatch = (id, extra) => Object.assign({
  matchId: id,
  playerAUid: `uid-${id}`,
  playerBUid: "",
  playerARaceName: `Race ${id}`,
  playerAStats: { strength: 5 },
  status: "waiting",
  createdAt: NOW - 1000,
  expiresAt: NOW + 3600_000,
}, extra || {});

(async () => {
  console.log("\n(B3) PvP matchmaking: the race is checked\n");

  const refused = async (name, data, message) => {
    const r = await find(data, { waiting: [waitingMatch("m1")] });
    check(name, [r.code, r.error], ["invalid-argument", message]);
    check(`${name} -> nothing joined or created`, r.joins.length + r.created.length, 0);
  };
  await refused("31 points", { ...RACE, raceStats: { strength: 10, wisdom: 10, speed: 11 } }, "Invalid raceStats.");
  await refused("one stat above 10", { ...RACE, raceStats: { strength: 11 } }, "Invalid raceStats.");
  await refused("a negative stat", { ...RACE, raceStats: { strength: -1, wisdom: 10 } }, "Invalid raceStats.");
  await refused("a stat sent as text", { ...RACE, raceStats: { strength: "5" } }, "Invalid raceStats.");
  await refused("a stat with a fraction", { ...RACE, raceStats: { strength: 2.5 } }, "Invalid raceStats.");
  await refused("stats as a list", { ...RACE, raceStats: [10, 10, 10] }, "Invalid raceStats.");
  await refused("a one-letter name", { ...RACE, raceName: "X" }, "Invalid raceName.");
  await refused("a 21-letter name", { ...RACE, raceName: "a".repeat(21) }, "Invalid raceName.");
  await refused("a blocked word in the name", { ...RACE, raceName: "Shit Army" }, "CONTENT_FILTER_BLOCKED");

  console.log("\n(B3) PvP matchmaking: joining is safe\n");

  let r = await find(RACE, { waiting: [waitingMatch("m1")] });
  check("an open match -> joined", r.result?.matchId, "m1");
  check("joined as player B", r.joins[0]?.patch.playerBUid, ME);
  check("the name is stored trimmed", r.joins[0]?.patch.playerBRaceName, "Iron Kingdom");
  check("the match becomes active", r.joins[0]?.patch.status, "active");
  check("nothing created", r.created.length, 0);

  r = await find(RACE, {
    waiting: [waitingMatch("m1"), waitingMatch("m2")],
    current: { m1: waitingMatch("m1", { playerBUid: "uid-faster", status: "active" }) },
  });
  check("first match taken meanwhile -> joins the next one", r.result?.matchId, "m2");
  check("first match taken meanwhile -> its player B is not replaced",
    r.joins.some((j) => j.id === "m1"), false);

  r = await find(RACE, {
    waiting: [waitingMatch("m1")],
    current: { m1: waitingMatch("m1", { playerBUid: "uid-faster", status: "active" }) },
  });
  check("every match taken meanwhile -> a new match", r.result?.isNewMatch, true);
  check("every match taken meanwhile -> nothing joined", r.joins.length, 0);
  check("the new match carries the trimmed name", r.created[0]?.playerARaceName, "Iron Kingdom");

  r = await find(RACE, { waiting: [] });
  check("no open match -> a new match", r.result?.isNewMatch, true);

  r = await find(RACE, { waiting: [waitingMatch("own", { playerAUid: ME })] });
  check("only my own waiting match -> not joined, a new one", r.result?.isNewMatch, true);

  ft.cleanup();
  console.log(fail ? `\n${fail} check(s) FAILED\n` : "\nall checks passed\n");
  process.exit(fail ? 1 : 0);
})();
