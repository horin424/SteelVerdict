/**
 * Checks reserveAiCall (src/limits/reserveAiCall.ts) against the Firestore
 * emulator: the player's counters and the day's ai_usage document written in one
 * transaction, each limit refusing with its code and writing nothing, a new Japan
 * day starting from zero, dev_uids, a player with no document, and the counts
 * holding exactly when many calls arrive at once.
 *
 * Needs the Firestore emulator (demo-steelverdict), e.g. from the repo root:
 *   java -jar cloud-firestore-emulator-v1.19.8.jar --host 127.0.0.1 --port 8080
 *     --project_id demo-steelverdict --single_project_mode true
 * Then: npm run build && npm run verify:ailimits-db
 */
process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";
process.env.GCLOUD_PROJECT = "demo-steelverdict";

const admin = require("firebase-admin");
admin.initializeApp({ projectId: "demo-steelverdict" });
const { AI_USAGE, reserveAiCall } = require("../lib/limits/reserveAiCall");

const db = admin.firestore();
let fail = 0;
function check(name, actual, expected) {
  if (JSON.stringify(actual) === JSON.stringify(expected)) {
    console.log(`  ok   ${name}`);
  } else {
    fail++;
    console.log(`  FAIL ${name} - expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

const L = { freePerUser: 2, allPerUser: 3, appTotal: 5 };
const FREE = { free: true, dev: false };
const PAID = { free: false, dev: false };
const NOON_22 = new Date(Date.UTC(2026, 10, 22, 3)); // 22 Nov 12:00 in Japan
const LAST_MS_22 = new Date(Date.UTC(2026, 10, 22, 14, 59, 59, 999)); // 22 Nov 23:59:59.999 in Japan
const MIDNIGHT_23 = new Date(Date.UTC(2026, 10, 22, 15)); // 23 Nov 00:00 in Japan
const NOON_24 = new Date(Date.UTC(2026, 10, 24, 3));
const NOON_25 = new Date(Date.UTC(2026, 10, 25, 3));

const reserve = (uid, call, limits = L, now = NOON_22) =>
  reserveAiCall(uid, call, limits, db, now).then(() => "allowed", (e) => (e.code === "resource-exhausted" ? e.message : e.code || e.message));
const counts = async (uid) => {
  const u = (await db.doc(`users/${uid}`).get()).data();
  return [u.aiCallsDate, u.aiCallsCount, u.aiFreeCallsCount];
};
const usage = async (day) => {
  const g = await db.doc(`${AI_USAGE}/${day}`).get();
  return g.exists ? [g.data().count, g.data().free] : null;
};

(async () => {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  const cleared = await fetch(
    `http://${host}/emulator/v1/projects/demo-steelverdict/databases/(default)/documents`, { method: "DELETE" });
  if (!cleared.ok) throw new Error(`Couldn't clear the emulator at ${host}: ${cleared.status}`);
  for (const uid of ["p1", "p2", "d1", "solo"]) {
    await db.doc(`users/${uid}`).set({ uid, ticketCount: 3, displayName: "テスト" });
  }

  console.log("\ncounting (limits: free 2, all 3, app 5)\n");
  check("p1, a free call: allowed", await reserve("p1", FREE), "allowed");
  check("p1's counters", await counts("p1"), ["2026-11-22", 1, 1]);
  const day = (await db.doc(`${AI_USAGE}/2026-11-22`).get()).data();
  check("the day's document: day, count, free, time", [day.day, day.count, day.free, day.updatedAt],
    ["2026-11-22", 1, 1, NOON_22.getTime()]);
  const p1 = (await db.doc("users/p1").get()).data();
  check("p1's other fields untouched", [p1.ticketCount, p1.displayName], [3, "テスト"]);

  check("p1, a second free call: allowed", await reserve("p1", FREE), "allowed");
  check("p1, a third free call: refused", await reserve("p1", FREE), "DAILY_FREE_LIMIT:2");
  check("the refusal wrote nothing", [await counts("p1"), await usage("2026-11-22")], [["2026-11-22", 2, 2], [2, 2]]);
  check("p1, a paid call: allowed", await reserve("p1", PAID), "allowed");
  check("p1, another paid call: refused (3 in all)", await reserve("p1", PAID), "DAILY_AI_LIMIT:3");
  check("p1's counters at the limit", await counts("p1"), ["2026-11-22", 3, 2]);

  check("p2, a paid call: allowed", await reserve("p2", PAID), "allowed");
  check("p2, a second: allowed (the app's 5th)", await reserve("p2", PAID), "allowed");
  check("p2, a third: refused by the app's limit", await reserve("p2", PAID), "APP_AI_LIMIT:5");
  check("the day's count: 5, 2 of them free", await usage("2026-11-22"), [5, 2]);
  check("one ms before midnight in Japan: still the 22nd, refused",
    await reserve("p2", PAID, L, LAST_MS_22), "APP_AI_LIMIT:5");

  console.log("\na new day in Japan\n");
  check("p1 at 0:00 on the 23rd: allowed", await reserve("p1", PAID, L, MIDNIGHT_23), "allowed");
  check("p1's counters start again", await counts("p1"), ["2026-11-23", 1, 0]);
  check("a new document for the 23rd", await usage("2026-11-23"), [1, 0]);
  check("the 22nd is left as it was", await usage("2026-11-22"), [5, 2]);

  console.log("\ndev_uids and a missing player\n");
  const NONE = { freePerUser: 0, allPerUser: 0, appTotal: 100 };
  check("a dev account with player limits of 0: a free call allowed",
    await reserve("d1", { free: true, dev: true }, NONE, NOON_24), "allowed");
  check("and a paid one", await reserve("d1", { free: false, dev: true }, NONE, NOON_24), "allowed");
  check("still counted, for the player and the app", [await counts("d1"), await usage("2026-11-24")],
    [["2026-11-24", 2, 1], [2, 1]]);
  check("the same limits for a normal player: refused", await reserve("p2", FREE, NONE, NOON_24), "DAILY_FREE_LIMIT:0");
  check("no user document: not-found", await reserve("ghost", PAID, L, NOON_24), "not-found");
  check("and nothing counted for it", await usage("2026-11-24"), [2, 1]);

  console.log("\nmany calls at once\n");
  const crowd = Array.from({ length: 20 }, (_, i) => `c${i}`);
  for (const uid of crowd) await db.doc(`users/${uid}`).set({ uid, ticketCount: 3 });
  const WIDE = { freePerUser: 100, allPerUser: 100, appTotal: 7 };
  const results = await Promise.all(crowd.map((uid) => reserve(uid, PAID, WIDE, NOON_25)));
  check("20 players at once, app limit 7: 7 allowed", results.filter((r) => r === "allowed").length, 7);
  check("the other 13 refused by the app's limit", results.filter((r) => r === "APP_AI_LIMIT:7").length, 13);
  check("the day's count is exactly 7", await usage("2026-11-25"), [7, 0]);
  let sum = 0;
  for (const uid of crowd) sum += (await db.doc(`users/${uid}`).get()).data().aiCallsCount ?? 0;
  check("and the players' counters add up to 7", sum, 7);

  const SOLO = { freePerUser: 4, allPerUser: 100, appTotal: 100 };
  const NOON_26 = new Date(Date.UTC(2026, 10, 26, 3));
  const mine = await Promise.all(Array.from({ length: 10 }, () => reserve("solo", FREE, SOLO, NOON_26)));
  check("one player, 10 free calls at once, limit 4: 4 allowed",
    [mine.filter((r) => r === "allowed").length, mine.filter((r) => r === "DAILY_FREE_LIMIT:4").length], [4, 6]);
  check("their counters say 4", await counts("solo"), ["2026-11-26", 4, 4]);

  console.log("\nthe default database and time\n");
  const today = new Date(Date.now() + 9 * 3600 * 1000).toISOString().substring(0, 10);
  await reserveAiCall("p2", PAID, { freePerUser: 30, allPerUser: 100, appTotal: 3000 });
  check("without db and time: today's Japan day in the default database", (await counts("p2"))[0], today);

  console.log(fail ? `\n${fail} check(s) FAILED\n` : "\nall checks passed\n");
  process.exit(fail ? 1 : 0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
