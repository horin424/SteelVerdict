/**
 * Checks validatePurchase and the purchase ledger (A3, A5a, A5b) against the
 * Firestore and Auth emulators.
 *
 * Runs the real compiled function. Only the stores' answers are faked: the
 * Google Play API at the HTTPS level, and Apple's decoded transaction (the
 * signature check itself is Apple's library). Firestore transactions, the
 * ledger rows and the guest/deleted-account checks are the emulators' own.
 *
 * Needs both emulators (demo-steelverdict), e.g. from the repo root:
 *   java -jar cloud-firestore-emulator-v1.19.8.jar --host 127.0.0.1 --port 8080
 *     --project_id demo-steelverdict --rules firestore.rules --single_project_mode true
 *   firebase emulators:start --only auth --project demo-steelverdict
 * Then: npm run build && npm run verify:purchases
 */
process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";
process.env.FIREBASE_AUTH_EMULATOR_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST || "127.0.0.1:9099";
process.env.GCLOUD_PROJECT = "demo-steelverdict";
process.env.GOOGLE_PLAY_SERVICE_ACCOUNT = JSON.stringify({
  client_email: "verify@demo-steelverdict.iam.gserviceaccount.com",
  private_key: "not-used-the-token-request-is-stubbed",
});
process.env.APPLE_BUNDLE_ID = "app.steelverdict.game";

const { EventEmitter } = require("node:events");
const admin = require("firebase-admin");
admin.initializeApp({ projectId: "demo-steelverdict" });
const ft = require("firebase-functions-test")({ projectId: "demo-steelverdict" });

// ------------------------------------------------------------ Google Play
// The access token request and the Play API's HTTPS calls are answered here.
require("google-auth-library").JWT.prototype.authorize = async () => ({ access_token: "test-token" });
const play = new Map(); // purchase token -> answer body, or a status number
const httpsModule = require("https");
httpsModule.get = (url, options, callback) => {
  const token = decodeURIComponent(String(url).split("/tokens/")[1] || "");
  // Like Play: a one-time token asked about under another product is unknown.
  const askedProduct = (String(url).match(/\/purchases\/products\/([^/]+)\/tokens\//) || [])[1];
  let answer = play.has(token) ? play.get(token) : 404;
  if (askedProduct && typeof answer === "object" && answer.productId !== askedProduct && !answer.answerAnyProduct) {
    answer = 404;
  }
  const res = new EventEmitter();
  res.statusCode = typeof answer === "number" ? answer : 200;
  const req = new EventEmitter();
  req.setTimeout = () => req;
  process.nextTick(() => {
    callback(res);
    res.emit("data", typeof answer === "number" ? "{\"error\":{}}" : JSON.stringify(answer));
    res.emit("end");
  });
  return req;
};

// ----------------------------------------------------------------- Apple
const apple = new Map(); // JWS -> decoded transaction
const { StoreRefusal } = require("../lib/purchase/stores");
require("../lib/purchase/appleVerifier").decodeAppleTransaction = async (jws) => {
  if (!apple.has(jws)) throw new StoreRefusal("invalid_signature");
  return apple.get(jws);
};

const { purchaseAccountId } = require("../lib/purchase/accountId");
const { validatePurchase } = require("../lib/purchase/validatePurchase");
const wrapped = ft.wrap(validatePurchase);
const db = admin.firestore();

// --------------------------------------------------------------- helpers
const DAY = 24 * 3600 * 1000;
const future = () => new Date(Date.now() + 30 * DAY).toISOString();
const past = () => new Date(Date.now() - DAY).toISOString();

function playProduct(token, productId, ownerUid, extra = {}) {
  play.set(token, {
    purchaseState: 0, purchaseType: 0, orderId: `GPA.${token}`, productId,
    ...(ownerUid ? { obfuscatedExternalAccountId: purchaseAccountId(ownerUid) } : {}),
    ...extra,
  });
}
function playSubscription(token, productId, ownerUid, extra = {}) {
  play.set(token, {
    subscriptionState: "SUBSCRIPTION_STATE_ACTIVE",
    lineItems: [{ productId, expiryTime: future() }],
    latestOrderId: `GPA.${token}`,
    testPurchase: {},
    ...(ownerUid ? { externalAccountIdentifiers: { obfuscatedExternalAccountId: purchaseAccountId(ownerUid) } } : {}),
    ...extra,
  });
}

async function claim(uid, data) {
  try {
    return await wrapped({ auth: { uid, token: {} }, data });
  } catch (e) {
    return { error: e.code || e.message };
  }
}
const android = (uid, productId, purchaseToken) => claim(uid, { platform: "android", productId, purchaseToken });
const ios = (uid, productId, receiptData) => claim(uid, { platform: "ios", productId, receiptData });
const user = async (uid) => (await db.collection("users").doc(uid).get()).data();

let fail = 0;
function check(name, actual, expected) {
  if (JSON.stringify(actual) === JSON.stringify(expected)) {
    console.log(`  ok   ${name}`);
  } else {
    fail++;
    console.log(`  FAIL ${name} - expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}
const pick = (o, ...keys) => Object.fromEntries(keys.map((k) => [k, o?.[k]]));

async function resetEmulators() {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/demo-steelverdict/databases/(default)/documents`, { method: "DELETE" });
  await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/demo-steelverdict/accounts`, { method: "DELETE" });
}
async function makeUser(uid, { guest = false } = {}) {
  await admin.auth().createUser(guest ? { uid } : { uid, email: `${uid}@example.test`, password: "emulator-only-1" });
  await db.collection("users").doc(uid).set({
    displayName: "", ticketCount: 3, subscriptionTier: "free", isBossEnabled: false, lastLoginAt: 1,
  });
}

// ----------------------------------------------------------------- cases
(async () => {
  await resetEmulators();
  for (const uid of ["alice", "bob", "carol"]) await makeUser(uid);
  await makeUser("guest-1", { guest: true });
  await makeUser("reinstalled");

  console.log("\nAccount ID");
  check("test-uid-123 gives the pinned UUID (same as the app)",
    purchaseAccountId("test-uid-123"), "6c038dfe-22ce-5098-b65d-42d915deaa7a");

  console.log("\nTicket packs (Android)");
  playProduct("t10-a", "strategy_game_tickets_10", "alice");
  check("first claim grants 10 tickets",
    pick(await android("alice", "strategy_game_tickets_10", "t10-a"), "status", "granted", "amount"),
    { status: "granted", granted: "tickets", amount: 10 });
  check("balance 3 -> 13", (await user("alice")).ticketCount, 13);
  check("the same purchase again: already granted",
    pick(await android("alice", "strategy_game_tickets_10", "t10-a"), "status", "granted"),
    { status: "already_granted", granted: "tickets" });
  check("balance unchanged at 13 (A5a)", (await user("alice")).ticketCount, 13);
  check("bob sends alice's purchase: refused",
    (await android("bob", "strategy_game_tickets_10", "t10-a")).status, "refused");
  check("bob's balance unchanged", (await user("bob")).ticketCount, 3);
  check("asking for 30 with a 10-ticket purchase: refused (A5b)",
    pick(await android("alice", "strategy_game_tickets_30", "t10-a"), "status", "reason"),
    { status: "refused", reason: "store_unknown_purchase" });
  playProduct("t10-odd", "strategy_game_tickets_10", "alice", { answerAnyProduct: true });
  check("Play's answer names another product: refused (A5b)",
    pick(await android("alice", "strategy_game_tickets_30", "t10-odd"), "status", "reason"),
    { status: "refused", reason: "product_mismatch" });
  check("a product the table doesn't know: refused",
    (await android("alice", "strategy_game_gems_999", "t10-a")).reason, "unknown_product");
  check("a token Play doesn't know: refused",
    pick(await android("alice", "strategy_game_tickets_10", "forged"), "status", "reason"),
    { status: "refused", reason: "store_unknown_purchase" });
  playProduct("t30-pending", "strategy_game_tickets_30", "alice", { purchaseState: 2 });
  check("a pending payment: pending, nothing granted",
    (await android("alice", "strategy_game_tickets_30", "t30-pending")).status, "pending");
  check("balance still 13", (await user("alice")).ticketCount, 13);
  play.set("t30-outage", 503);
  check("Play down: the call fails so the app retries",
    (await android("alice", "strategy_game_tickets_30", "t30-outage")).error, "unavailable");

  console.log("\nSubscriptions (Android)");
  playSubscription("s1000-a", "strategy_game_sub_1000_monthly", "alice");
  check("General (¥1,000): granted, tier sub1000",
    pick(await android("alice", "strategy_game_sub_1000_monthly", "s1000-a"), "status", "tier"),
    { status: "granted", tier: "sub1000" });
  check("user record: sub1000, no Boss",
    pick(await user("alice"), "subscriptionTier", "isBossEnabled"),
    { subscriptionTier: "sub1000", isBossEnabled: false });
  check("expiry recorded", typeof (await user("alice")).subscriptionExpiresAt, "number");
  check("same subscription again: already granted",
    (await android("alice", "strategy_game_sub_1000_monthly", "s1000-a")).status, "already_granted");
  playSubscription("s3000-a", "strategy_game_sub_3000_monthly", "alice", { linkedPurchaseToken: "s1000-a" });
  check("upgrade to Warlord (¥3,000): granted, tier sub3000",
    pick(await android("alice", "strategy_game_sub_3000_monthly", "s3000-a"), "status", "tier"),
    { status: "granted", tier: "sub3000" });
  check("user record: sub3000 with Boss",
    pick(await user("alice"), "subscriptionTier", "isBossEnabled"),
    { subscriptionTier: "sub3000", isBossEnabled: true });
  const rows = await db.collection("purchases").where("uid", "==", "alice").where("kind", "==", "subscription").get();
  check("the ¥1,000 row is marked replaced",
    rows.docs.map((d) => d.data()).find((r) => r.productId === "strategy_game_sub_1000_monthly").state, "replaced");
  playSubscription("s3000-a", "strategy_game_sub_3000_monthly", "alice",
    { subscriptionState: "SUBSCRIPTION_STATE_EXPIRED", lineItems: [{ productId: "strategy_game_sub_3000_monthly", expiryTime: past() }] });
  check("the store now says expired: refused",
    pick(await android("alice", "strategy_game_sub_3000_monthly", "s3000-a"), "status", "reason", "tier"),
    { status: "refused", reason: "expired", tier: "free" });
  check("user record back to free, no Boss",
    pick(await user("alice"), "subscriptionTier", "isBossEnabled", "subscriptionExpiresAt"),
    { subscriptionTier: "free", isBossEnabled: false, subscriptionExpiresAt: null });
  playSubscription("s500-b", "strategy_game_sub_500_monthly", "bob");
  check("carol sends bob's subscription: refused",
    pick(await android("carol", "strategy_game_sub_500_monthly", "s500-b"), "status", "reason"),
    { status: "refused", reason: "other_account" });
  check("carol stays free", (await user("carol")).subscriptionTier, "free");
  playSubscription("s500-old", "strategy_game_sub_500_monthly", null);
  check("no account ID (bought before this change): first claim wins",
    (await android("bob", "strategy_game_sub_500_monthly", "s500-old")).status, "granted");
  check("then another account: refused",
    pick(await android("carol", "strategy_game_sub_500_monthly", "s500-old"), "status", "reason"),
    { status: "refused", reason: "claimed_by_other_account" });

  console.log("\nScenario pack and restore after a reinstall");
  playProduct("pack-guest", "strategy_game_scenario_pack_1", "guest-1");
  check("a guest buys the scenario pack: granted",
    (await android("guest-1", "strategy_game_scenario_pack_1", "pack-guest")).status, "granted");
  check("guest has it", (await user("guest-1")).scenarioPack1Unlocked, true);
  check("the same person reinstalls (new account) and restores: moved here",
    pick(await android("reinstalled", "strategy_game_scenario_pack_1", "pack-guest"), "status", "moved"),
    { status: "granted", moved: true });
  check("new account has it", (await user("reinstalled")).scenarioPack1Unlocked, true);
  check("the old guest account no longer has it (moved, not copied)",
    (await user("guest-1")).scenarioPack1Unlocked, false);
  playProduct("pack-alice", "strategy_game_scenario_pack_1", "alice");
  await android("alice", "strategy_game_scenario_pack_1", "pack-alice");
  check("bob sends alice's pack (alice is not a guest): refused",
    pick(await android("bob", "strategy_game_scenario_pack_1", "pack-alice"), "status", "reason"),
    { status: "refused", reason: "claimed_by_other_account" });
  playSubscription("s1000-carol", "strategy_game_sub_1000_monthly", "carol");
  await db.collection("purchases").doc(require("../lib/purchase/stores").androidLedgerId("s1000-carol")).set({
    uid: "bob", productId: "strategy_game_sub_1000_monthly", kind: "subscription", state: "active",
    expiresAt: Date.now() + 30 * DAY, platform: "android",
  });
  check("carol's subscription, claimed by bob before owner checks: carol gets it back",
    pick(await android("carol", "strategy_game_sub_1000_monthly", "s1000-carol"), "status", "moved", "tier"),
    { status: "granted", moved: true, tier: "sub1000" });
  check("bob's tier recomputed without it", (await user("bob")).subscriptionTier, "sub500");
  playProduct("pack-deleted", "strategy_game_scenario_pack_1", "ghost");
  await db.collection("purchases").doc(require("../lib/purchase/stores").androidLedgerId("pack-deleted")).set({
    uid: "ghost", productId: "strategy_game_scenario_pack_1", kind: "non_consumable", state: "active",
    platform: "android",
  });
  check("pack held by a deleted account: moved to the restorer",
    pick(await android("reinstalled", "strategy_game_scenario_pack_1", "pack-deleted"), "status", "moved"),
    { status: "granted", moved: true });

  console.log("\nApp Store (iOS)");
  const tx = (o) => ({
    productId: "strategy_game_tickets_30", transactionId: "1000", originalTransactionId: "1000",
    environment: "Sandbox", appAccountToken: purchaseAccountId("alice").toUpperCase(), ...o,
  });
  apple.set("jws-t30", tx({}));
  check("30 tickets: granted",
    pick(await ios("alice", "strategy_game_tickets_30", "jws-t30"), "status", "amount"),
    { status: "granted", amount: 30 });
  check("sent again: already granted",
    (await ios("alice", "strategy_game_tickets_30", "jws-t30")).status, "already_granted");
  check("balance 13 + 30 = 43", (await user("alice")).ticketCount, 43);
  check("a forged transaction: refused",
    pick(await ios("alice", "strategy_game_tickets_30", "jws-forged"), "status", "reason"),
    { status: "refused", reason: "invalid_signature" });
  apple.set("jws-wrong-product", tx({ productId: "strategy_game_tickets_10", transactionId: "1001" }));
  check("asking for 30 with a 10-ticket transaction: refused (A5b)",
    (await ios("alice", "strategy_game_tickets_30", "jws-wrong-product")).reason, "product_mismatch");
  apple.set("jws-sub-1", tx({
    productId: "strategy_game_sub_500_monthly", transactionId: "2001", originalTransactionId: "2000",
    expiresDate: Date.now() + 30 * DAY, appAccountToken: purchaseAccountId("carol"),
  }));
  apple.set("jws-sub-2", tx({
    productId: "strategy_game_sub_500_monthly", transactionId: "2002", originalTransactionId: "2000",
    expiresDate: Date.now() + 60 * DAY, appAccountToken: purchaseAccountId("carol"),
  }));
  await ios("carol", "strategy_game_sub_500_monthly", "jws-sub-1");
  check("a renewal (new transaction, same original): the same row",
    (await ios("carol", "strategy_game_sub_500_monthly", "jws-sub-2")).status, "already_granted");
  check("carol: General (¥1,000) still ranks above Commander (¥500)", (await user("carol")).subscriptionTier, "sub1000");
  apple.set("jws-refunded", tx({ transactionId: "3000", originalTransactionId: "3000", revocationDate: Date.now() }));
  check("a refunded transaction: refused",
    pick(await ios("alice", "strategy_game_tickets_30", "jws-refunded"), "status", "reason"),
    { status: "refused", reason: "refunded" });

  const ledger = await db.collection("purchases").get();
  // 10 purchases reached the ledger; the refused ones (forged, foreign, refunded) left no row.
  check("one ledger row per purchase", ledger.size, 10);

  ft.cleanup();
  console.log(fail ? `\n${fail} check(s) FAILED\n` : "\nall checks passed\n");
  process.exit(fail ? 1 : 0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
