/**
 * Checks the ad tickets' Firestore side (grantAdTickets in
 * src/tickets/admobRewardCallback.ts) against the Firestore emulator: tickets
 * and record in one transaction, once per transaction_id (also when AdMob
 * sends the same reward several times at once), 20 ads a day in Japan time,
 * nothing for a user without a document, other fields untouched. Then whole
 * callbacks, signed with a key made for the run, through the real handler.
 *
 * Needs the Firestore emulator (demo-steelverdict), e.g. from the repo root:
 *   java -jar cloud-firestore-emulator-v1.19.8.jar --host 127.0.0.1 --port 8080
 *     --project_id demo-steelverdict --single_project_mode true
 * Then: npm run build && npm run verify:adreward-db
 * (FIRESTORE_EMULATOR_HOST picks another port; with a proxy set, also
 * NO_PROXY=127.0.0.1,localhost.)
 */
process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";
process.env.GCLOUD_PROJECT = "demo-steelverdict";

const { generateKeyPairSync, sign } = require("crypto");
const admin = require("firebase-admin");
admin.initializeApp({ projectId: "demo-steelverdict" });
const { createKeyStore } = require("../lib/tickets/adReward");
const { grantAdTickets, handleAdRewardCallback } = require("../lib/tickets/admobRewardCallback");

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

const DAY = 24 * 3600 * 1000;
const NOON_JAPAN = new Date(Date.UTC(2026, 10, 20, 3, 0, 0)); // 20 Nov 12:00 in Japan
const reward = (transactionId, userId = "player1", at = NOON_JAPAN) => ({
  adUnit: "9303443517", customData: "tickets", userId, transactionId, rewardedAt: at.getTime() - 1000,
});
const user = async (uid) => (await db.doc(`users/${uid}`).get()).data();
const record = async (tx) => (await db.doc(`ad_rewards/${tx}`).get()).data();
const tickets = async (uid) => {
  const u = await user(uid);
  return [u.ticketCount, u.adTicketClaimsDate, u.adTicketClaimsCount];
};

(async () => {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  const cleared = await fetch(
    `http://${host}/emulator/v1/projects/demo-steelverdict/databases/(default)/documents`, { method: "DELETE" });
  if (!cleared.ok) throw new Error(`Couldn't clear the emulator at ${host}: ${cleared.status}`);

  console.log("\none player's ads in a day\n");
  await db.doc("users/player1").set({ uid: "player1", displayName: "テスト", ticketCount: 3, subscriptionTier: "free" });
  check("the first reward: granted", await grantAdTickets(db, reward("tx01"), NOON_JAPAN), "granted");
  check("+2 tickets, 1 ad today (Japan date)", await tickets("player1"), [5, "2026-11-20", 1]);
  const first = await record("tx01");
  check("the reward's record", [first.granted, first.adUnit, first.rewardedAt, first.receivedAt],
    [true, "9303443517", NOON_JAPAN.getTime() - 1000, NOON_JAPAN.getTime()]);
  check("it expires after 30 days, and holds no uid",
    [first.expireAt.toMillis() - NOON_JAPAN.getTime(), "uid" in first], [30 * DAY, false]);
  check("the same reward again: duplicate", await grantAdTickets(db, reward("tx01"), NOON_JAPAN), "duplicate");
  check("still 5 tickets", await tickets("player1"), [5, "2026-11-20", 1]);

  const outcomes = [];
  for (let i = 2; i <= 20; i++) outcomes.push(await grantAdTickets(db, reward(`tx${String(i).padStart(2, "0")}`), NOON_JAPAN));
  check("ads 2 to 20: granted", outcomes.every((o) => o === "granted"), true);
  check("43 tickets after 20 ads", await tickets("player1"), [43, "2026-11-20", 20]);
  check("the 21st ad: daily_cap", await grantAdTickets(db, reward("tx21"), NOON_JAPAN), "daily_cap");
  check("still 43, and the 21st is recorded as not granted",
    [(await tickets("player1"))[0], (await record("tx21")).granted], [43, false]);
  check("the 21st sent again: duplicate", await grantAdTickets(db, reward("tx21"), NOON_JAPAN), "duplicate");

  const afterMidnight = new Date(Date.UTC(2026, 10, 20, 15, 0, 1)); // 21 Nov 0:00:01 in Japan
  check("one second after midnight in Japan: granted",
    await grantAdTickets(db, reward("tx22", "player1", afterMidnight), afterMidnight), "granted");
  check("45 tickets, 1 ad on the new day", await tickets("player1"), [45, "2026-11-21", 1]);
  const p1 = await user("player1");
  check("the player's other fields are untouched", [p1.uid, p1.displayName, p1.subscriptionTier],
    ["player1", "テスト", "free"]);

  console.log("\nat the same moment\n");
  await db.doc("users/player2").set({ uid: "player2", ticketCount: 0 });
  const burst = await Promise.all([1, 2, 3, 4, 5].map(() => grantAdTickets(db, reward("txBurst", "player2"), NOON_JAPAN)));
  check("the same reward 5 times at once: granted once, duplicate 4 times",
    [burst.filter((o) => o === "granted").length, burst.filter((o) => o === "duplicate").length], [1, 4]);
  check("2 tickets for it", await tickets("player2"), [2, "2026-11-20", 1]);
  const many = await Promise.all([1, 2, 3, 4, 5].map((i) => grantAdTickets(db, reward(`txMany${i}`, "player2"), NOON_JAPAN)));
  check("5 different rewards at once: all granted", many.every((o) => o === "granted"), true);
  check("12 tickets, 6 ads", await tickets("player2"), [12, "2026-11-20", 6]);

  await db.doc("users/player3").set({ uid: "player3", ticketCount: 0, adTicketClaimsDate: "2026-11-20", adTicketClaimsCount: 18 });
  const lastOnes = await Promise.all([1, 2, 3, 4].map((i) => grantAdTickets(db, reward(`txLast${i}`, "player3"), NOON_JAPAN)));
  check("4 rewards at once with 2 ads left: 2 granted, 2 over the cap",
    [lastOnes.filter((o) => o === "granted").length, lastOnes.filter((o) => o === "daily_cap").length], [2, 2]);
  check("4 tickets, 20 ads", await tickets("player3"), [4, "2026-11-20", 20]);

  console.log("\na uid with no player\n");
  check("a user without a document: no_user", await grantAdTickets(db, reward("txGhost", "ghost"), NOON_JAPAN), "no_user");
  check("no document is made for it, and no record is kept",
    [(await db.doc("users/ghost").get()).exists, (await db.doc("ad_rewards/txGhost").get()).exists], [false, false]);

  console.log("\nwhole callbacks through the handler\n");
  const google = generateKeyPairSync("ec", { namedCurve: "prime256v1" });
  const pem = google.publicKey.export({ type: "spki", format: "pem" });
  const keys = createKeyStore(async () => [{ keyId: 7, pem }]);
  const signedUrl = (params) => {
    const message = Object.keys(params).sort().map((k) => `${k}=${encodeURIComponent(params[k])}`).join("&");
    const sig = sign("sha256", Buffer.from(message), { key: google.privateKey, dsaEncoding: "der" }).toString("base64url");
    return `/?${message}&signature=${sig}&key_id=7`;
  };
  async function call(url) {
    let status = 0;
    const quiet = [console.log, console.warn, console.error];
    console.log = console.warn = console.error = () => {};
    try {
      await handleAdRewardCallback({ method: "GET", originalUrl: url },
        { status(code) { status = code; return { send() {} }; } },
        { keys, grant: (r) => grantAdTickets(db, r) });
    } finally {
      [console.log, console.warn, console.error] = quiet;
    }
    return status;
  }
  await db.doc("users/player4").set({ uid: "player4", ticketCount: 1 });
  const params = (tx, extra = {}) => ({
    ad_network: "5450213213286189855", ad_unit: "9303443517", custom_data: "tickets", reward_amount: "1",
    reward_item: "Reward", timestamp: String(Date.now() - 2000), transaction_id: tx, user_id: "player4", ...extra,
  });
  const url = signedUrl(params("a1b2c3d4e5f6"));
  check("Google's callback: 200", await call(url), 200);
  check("player4 got 2 tickets", (await user("player4")).ticketCount, 3);
  check("AdMob sends it again: 200", await call(url), 200);
  check("still 3 tickets", (await user("player4")).ticketCount, 3);
  check("a scenario-unlock ad: 200", await call(signedUrl(params("f6e5d4c3b2a1", { custom_data: "unlock" }))), 200);
  check("no tickets, no record for it",
    [(await user("player4")).ticketCount, (await db.doc("ad_rewards/f6e5d4c3b2a1").get()).exists], [3, false]);
  check("a changed user_id: 403", await call(url.replace("user_id=player4", "user_id=player1")), 403);
  check("player1's tickets unchanged", (await user("player1")).ticketCount, 45);

  console.log(fail === 0 ? "\nAll checks passed.\n" : `\n${fail} check(s) failed.\n`);
  process.exit(fail === 0 ? 0 : 1);
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
