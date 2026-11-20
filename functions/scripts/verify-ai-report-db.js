/**
 * Checks the saving of reports of AI output (src/reports/reportAiContent.ts)
 * against the Firestore emulator: the report and the day's counter in one
 * transaction, 20 a day per account (also under load), the counter starting
 * again on a new Japan day, nothing saved for a user without a document. Then
 * the callable itself (firebase-functions-test): signed out, a bad report,
 * a good one.
 *
 * Needs the Firestore emulator (demo-steelverdict), e.g. from the repo root:
 *   java -jar cloud-firestore-emulator-v1.19.8.jar --host 127.0.0.1 --port 8080
 *     --project_id demo-steelverdict --single_project_mode true
 * Then: npm run build && npm run verify:aireport-db
 */
process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";
process.env.GCLOUD_PROJECT = "demo-steelverdict";

const admin = require("firebase-admin");
admin.initializeApp({ projectId: "demo-steelverdict" });
const ft = require("firebase-functions-test")({ projectId: "demo-steelverdict" });
const { CONTENT_REPORTS, saveAiReport, reportAiContent } = require("../lib/reports/reportAiContent");

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

const NOON_JAPAN = new Date(Date.UTC(2026, 10, 20, 3)); // 20 Nov 12:00 in Japan
const report = (n = 1) => ({
  kind: "battle", reason: "offensive", aiText: `AIの文 ${n}`, strategy: "丘を守る", comment: "",
  gameMode: "normal", scenarioId: "aces_001", worldviewKey: "modern", appVersion: "1.0.0",
});
const outcome = (p) => p.then(() => "saved", (e) => e.code || e.message);
const reportsOf = async (uid) => (await db.collection(CONTENT_REPORTS).where("uid", "==", uid).get()).size;

(async () => {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  const cleared = await fetch(
    `http://${host}/emulator/v1/projects/demo-steelverdict/databases/(default)/documents`, { method: "DELETE" });
  if (!cleared.ok) throw new Error(`Couldn't clear the emulator at ${host}: ${cleared.status}`);

  console.log("\nsaving a report\n");
  await db.doc("users/p1").set({ uid: "p1", ticketCount: 3, displayName: "テスト" });
  const id = await saveAiReport(db, "p1", report(), NOON_JAPAN);
  const saved = (await db.doc(`${CONTENT_REPORTS}/${id}`).get()).data();
  check("the report with its uid, status, time and Japan day", [
    saved.uid, saved.status, saved.createdAt, saved.day, saved.kind, saved.reason, saved.aiText, saved.strategy,
  ], ["p1", "new", NOON_JAPAN.getTime(), "2026-11-20", "battle", "offensive", "AIの文 1", "丘を守る"]);
  const u1 = (await db.doc("users/p1").get()).data();
  check("the day's counter on the user", [u1.aiReportsDate, u1.aiReportsCount], ["2026-11-20", 1]);
  check("the user's other fields untouched", [u1.ticketCount, u1.displayName], [3, "テスト"]);

  for (let i = 2; i <= 20; i++) await saveAiReport(db, "p1", report(i), NOON_JAPAN);
  check("20 reports saved", await reportsOf("p1"), 20);
  check("the 21st: refused (resource-exhausted)", await outcome(saveAiReport(db, "p1", report(21), NOON_JAPAN)),
    "resource-exhausted");
  check("and not saved", await reportsOf("p1"), 20);
  const nextDay = new Date(Date.UTC(2026, 10, 20, 15, 0, 1)); // 21 Nov 0:00:01 in Japan
  check("one second after midnight in Japan: saved", await outcome(saveAiReport(db, "p1", report(22), nextDay)), "saved");
  const u2 = (await db.doc("users/p1").get()).data();
  check("the counter starts again", [u2.aiReportsDate, u2.aiReportsCount], ["2026-11-21", 1]);

  console.log("\nat the same moment\n");
  await db.doc("users/p2").set({ uid: "p2", aiReportsDate: "2026-11-20", aiReportsCount: 18 });
  const burst = await Promise.all([1, 2, 3, 4, 5].map((i) => outcome(saveAiReport(db, "p2", report(i), NOON_JAPAN))));
  check("5 reports at once with 2 left: 2 saved, 3 refused",
    [burst.filter((o) => o === "saved").length, burst.filter((o) => o === "resource-exhausted").length], [2, 3]);
  check("exactly 2 saved for p2", await reportsOf("p2"), 2);

  console.log("\nno player\n");
  check("a uid without a user document: not-found", await outcome(saveAiReport(db, "ghost", report(), NOON_JAPAN)),
    "not-found");
  check("nothing saved for it", await reportsOf("ghost"), 0);

  console.log("\nthe callable\n");
  const call = ft.wrap(reportAiContent);
  check("signed out: unauthenticated", await outcome(call({ data: report() })), "unauthenticated");
  check("an unknown kind: invalid-argument", await outcome(call({ data: { ...report(), kind: "pvp" }, auth: { uid: "p3" } })),
    "invalid-argument");
  await db.doc("users/p3").set({ uid: "p3", ticketCount: 0 });
  const answer = await call({ data: { ...report(), kind: "chronicle", reason: "violence", comment: "  怖い " }, auth: { uid: "p3" } });
  const viaCall = (await db.doc(`${CONTENT_REPORTS}/${answer.id}`).get()).data();
  check("a good report: saved, the comment trimmed", [viaCall.uid, viaCall.kind, viaCall.reason, viaCall.comment],
    ["p3", "chronicle", "violence", "怖い"]);

  console.log(fail === 0 ? "\nAll checks passed.\n" : `\n${fail} check(s) failed.\n`);
  ft.cleanup();
  process.exit(fail === 0 ? 0 : 1);
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
