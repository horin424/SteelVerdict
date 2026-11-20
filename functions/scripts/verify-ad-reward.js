/**
 * Offline checks of the ad tickets from AdMob's server-side verification
 * (src/tickets/adReward.ts and the callback's answers in
 * src/tickets/admobRewardCallback.ts).
 *
 * The callbacks are signed here with a key pair made for the run, the way
 * Google signs them (ECDSA P-256, SHA-256, DER, URL-safe base64), so no
 * network is needed. The tickets themselves (Firestore transaction, once per
 * transaction_id, the daily cap) are in verify-ad-reward-db.js, against the
 * Firestore emulator.
 *
 * Run: npm run verify:adreward
 */
const { generateKeyPairSync, sign } = require("crypto");
const {
  TICKETS_PER_AD, MAX_AD_TICKET_CLAIMS_PER_DAY, MAX_REWARD_AGE_MS,
  splitSignedQuery, signatureValid, readReward, isRewardedAdUnit, rewardRefusal,
  adTicketDecision, createKeyStore,
} = require("../lib/tickets/adReward");
const { handleAdRewardCallback } = require("../lib/tickets/admobRewardCallback");

let fail = 0;
function check(name, actual, expected) {
  if (JSON.stringify(actual) === JSON.stringify(expected)) {
    console.log(`  ok   ${name}`);
  } else {
    fail++;
    console.log(`  FAIL ${name} - expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

// ----------------------------------------------------------- callbacks
const google = generateKeyPairSync("ec", { namedCurve: "prime256v1" });
const stranger = generateKeyPairSync("ec", { namedCurve: "prime256v1" });
const googlePem = google.publicKey.export({ type: "spki", format: "pem" });
const KEY_ID = "3335741209";
const NOW = Date.UTC(2026, 10, 20, 12, 0, 0);
const UID = "Ab3dEf6hIj9kLm2nOp5qRs8tUv1w";

const reward = (over = {}) => ({
  ad_network: "5450213213286189855",
  ad_unit: "9303443517",
  custom_data: "tickets",
  reward_amount: "1",
  reward_item: "Reward",
  timestamp: String(NOW - 5000),
  transaction_id: "18fa792de1bca816048293fc71035638",
  user_id: UID,
  ...over,
});
/** The query string as AdMob sends it: parameters in alphabetical order, then signature and key_id. */
function callback(params, { key = google.privateKey, keyId = KEY_ID } = {}) {
  const message = Object.keys(params).filter((k) => params[k] !== undefined).sort()
    .map((k) => `${k}=${encodeURIComponent(params[k])}`).join("&");
  const signature = sign("sha256", Buffer.from(message), { key, dsaEncoding: "der" }).toString("base64url");
  return `${message}&signature=${signature}&key_id=${keyId}`;
}

console.log("\nthe signed part of the query\n");
const good = callback(reward());
const split = splitSignedQuery(good);
check("a callback splits into message, signature and key_id",
  [split.message === good.slice(0, good.indexOf("&signature=")), split.keyId, split.signature.length > 60],
  [true, KEY_ID, true]);
check("no signature: refused", splitSignedQuery(good.slice(0, good.indexOf("&signature="))), null);
check("key_id before signature: refused",
  splitSignedQuery(good.replace(/&signature=([^&]*)&key_id=(\d+)$/, "&key_id=$2&signature=$1")), null);
check("a parameter after key_id: refused", splitSignedQuery(`${good}&user_id=someoneElse`), null);
check("a key_id that isn't a number: refused", splitSignedQuery(good.replace(/key_id=\d+$/, "key_id=abc")), null);
check("an empty signature: refused", splitSignedQuery(good.replace(/signature=[^&]*/, "signature=")), null);
check("nothing before the signature: refused", splitSignedQuery(good.slice(good.indexOf("&signature=") + 1)), null);
const padded = good.replace(/(signature=[^&]*)/, "$1%3D");
check("base64 padding (=, escaped) is accepted", splitSignedQuery(padded) !== null, true);
check("a malformed escape: refused", splitSignedQuery(good.replace(/key_id=\d+$/, "key_id=%E0%A4%A")), null);

console.log("\nGoogle's signature\n");
const googleKey = google.publicKey;
check("signed by Google's key: valid", signatureValid(split.message, split.signature, googleKey), true);
check("a changed user_id: invalid",
  signatureValid(split.message.replace(UID, "someoneElse0000000000000000"), split.signature, googleKey), false);
check("a changed custom_data: invalid",
  signatureValid(split.message.replace("custom_data=tickets", "custom_data=unlock"), split.signature, googleKey), false);
const forged = splitSignedQuery(callback(reward(), { key: stranger.privateKey }));
check("signed by another key: invalid", signatureValid(forged.message, forged.signature, googleKey), false);
check("a cut signature: invalid",
  signatureValid(split.message, split.signature.subarray(0, split.signature.length - 3), googleKey), false);
check("garbage: invalid", signatureValid(split.message, Buffer.from("not a signature"), googleKey), false);

console.log("\nthe reward's values\n");
check("values read from the signed part", readReward(split.message), {
  adUnit: "9303443517", customData: "tickets", userId: UID,
  transactionId: "18fa792de1bca816048293fc71035638", rewardedAt: NOW - 5000,
});
check("custom_data percent-escaped is read decoded",
  readReward("ad_unit=1&custom_data=tick%65ts&timestamp=1").customData, "tickets");
check("missing values are empty", readReward("ad_network=1"),
  { adUnit: "", customData: "", userId: "", transactionId: "", rewardedAt: null });
check("our ad unit, number only or full", [isRewardedAdUnit("9303443517"),
  isRewardedAdUnit("ca-app-pub-1628452493399507/9303443517")], [true, true]);
check("other ad units", [isRewardedAdUnit("8704677710"), isRewardedAdUnit("ca-app-pub-3940256099942544/5224354917"),
  isRewardedAdUnit(""), isRewardedAdUnit("ca-app-pub-1628452493399507/")], [false, false, false, false]);

const refusal = (over) => rewardRefusal(readReward(splitSignedQuery(callback(reward(over))).message), NOW);
check("a good reward: tickets", refusal({}), null);
check("the interstitial or another unit: no tickets", refusal({ ad_unit: "8704677710" }), "unknown_ad_unit");
check("the scenario unlock's ad: no tickets", refusal({ custom_data: "unlock" }), "not_tickets");
check("no custom_data: no tickets", refusal({ custom_data: undefined }), "not_tickets");
check("no user_id: no tickets", refusal({ user_id: undefined }), "bad_user");
check("a user_id with a slash: no tickets", refusal({ user_id: "users/x" }), "bad_user");
check("no transaction_id: no tickets", refusal({ transaction_id: undefined }), "bad_transaction");
check("a transaction_id with a slash: no tickets", refusal({ transaction_id: "a/b" }), "bad_transaction");
check("no timestamp: no tickets", refusal({ timestamp: undefined }), "bad_time");
check("2 hours in the future: no tickets", refusal({ timestamp: String(NOW + 2 * 3600e3) }), "bad_time");
check("8 days old: no tickets", refusal({ timestamp: String(NOW - 8 * 24 * 3600e3) }), "too_old");
check("6 days old: tickets", refusal({ timestamp: String(NOW - 6 * 24 * 3600e3) }), null);
check("the age limit is 7 days", MAX_REWARD_AGE_MS, 7 * 24 * 3600e3);

console.log("\nthe tickets (2 per ad, 20 ads a day in Japan)\n");
check("2 tickets per ad, 20 a day", [TICKETS_PER_AD, MAX_AD_TICKET_CLAIMS_PER_DAY], [2, 20]);
check("first ad of the day", adTicketDecision({ ticketCount: 3 }, "2026-11-20"),
  { granted: true, update: { ticketCount: 5, adTicketClaimsDate: "2026-11-20", adTicketClaimsCount: 1 } });
check("the 20th ad", adTicketDecision(
  { ticketCount: 10, adTicketClaimsDate: "2026-11-20", adTicketClaimsCount: 19 }, "2026-11-20"),
{ granted: true, update: { ticketCount: 12, adTicketClaimsDate: "2026-11-20", adTicketClaimsCount: 20 } });
check("the 21st ad: nothing", adTicketDecision(
  { ticketCount: 10, adTicketClaimsDate: "2026-11-20", adTicketClaimsCount: 20 }, "2026-11-20"), { granted: false });
check("a new day starts again at 1", adTicketDecision(
  { ticketCount: 10, adTicketClaimsDate: "2026-11-19", adTicketClaimsCount: 20 }, "2026-11-20"),
{ granted: true, update: { ticketCount: 12, adTicketClaimsDate: "2026-11-20", adTicketClaimsCount: 1 } });
check("no ticketCount yet", adTicketDecision({}, "2026-11-20").update.ticketCount, 2);

(async () => {
  console.log("\nGoogle's keys\n");
  let clock = NOW;
  let fetches = 0;
  let answer = async () => [{ keyId: Number(KEY_ID), pem: googlePem }];
  const store = createKeyStore(async () => { fetches++; return answer(); }, () => clock);
  check("the first callback loads the keys", [(await store.get(KEY_ID)) !== undefined, fetches], [true, 1]);
  check("the next one uses them", [(await store.get(KEY_ID)) !== undefined, fetches], [true, 1]);
  check("an unknown key_id right after loading: not loaded again", [await store.get("999"), fetches], [undefined, 1]);
  clock += 61 * 1000;
  check("a minute later an unknown key_id loads them again", [await store.get("999"), fetches], [undefined, 2]);
  check("but not twice within a minute", [await store.get("999"), fetches], [undefined, 2]);
  clock += 13 * 3600e3;
  check("after 12 hours they load again", [(await store.get(KEY_ID)) !== undefined, fetches], [true, 3]);
  clock += 13 * 3600e3;
  answer = async () => { throw new Error("gstatic down"); };
  const origError = console.error;
  console.error = () => {};
  check("loading fails: the previous keys are used", [(await store.get(KEY_ID)) !== undefined, fetches], [true, 4]);
  check("and it isn't tried again within a minute", [(await store.get(KEY_ID)) !== undefined, fetches], [true, 4]);
  clock += 61 * 1000;
  answer = async () => [{ keyId: Number(KEY_ID), pem: googlePem }];
  check("a minute later it tries again, and works", [(await store.get(KEY_ID)) !== undefined, fetches], [true, 5]);
  check("then it's fresh for 12 hours", [(await store.get(KEY_ID)) !== undefined, fetches], [true, 5]);
  console.error = origError;

  let fresh = 0;
  const failing = createKeyStore(async () => { fresh++; throw new Error("offline"); }, () => NOW);
  let threw = false;
  try { await failing.get(KEY_ID); } catch { threw = true; }
  check("no keys at all: get() throws", threw, true);
  threw = false;
  try { await failing.get(KEY_ID); } catch { threw = true; }
  check("and tries again on the next callback", [threw, fresh], [true, 2]);

  let parallel = 0;
  const once = createKeyStore(async () => {
    parallel++;
    await new Promise((r) => setTimeout(r, 20));
    return [{ keyId: KEY_ID, pem: googlePem }];
  }, () => NOW);
  await Promise.all([once.get(KEY_ID), once.get(KEY_ID), once.get(KEY_ID)]);
  check("callbacks at the same moment load the keys once", parallel, 1);

  console.error = () => {};
  const mixed = createKeyStore(async () => [{ keyId: 1, pem: "not a key" }, { keyId: KEY_ID, pem: googlePem }], () => NOW);
  check("a broken key is skipped, the others kept",
    [await mixed.get("1"), (await mixed.get(KEY_ID)) !== undefined], [undefined, true]);
  const broken = createKeyStore(async () => [{ keyId: 1, pem: "not a key" }], () => NOW);
  threw = false;
  try { await broken.get("1"); } catch { threw = true; }
  check("only broken keys: get() throws", threw, true);
  console.error = origError;

  console.log("\nthe callback's answers\n");
  const keys = createKeyStore(async () => [{ keyId: KEY_ID, pem: googlePem }], () => NOW);
  async function call(url, { method = "GET", grant, keyStore = keys } = {}) {
    const granted = [];
    let status = 0;
    const res = { status(code) { status = code; return { send() {} }; } };
    const deps = {
      keys: keyStore,
      grant: grant || (async (r) => { granted.push(r); return "granted"; }),
      now: () => NOW,
    };
    const quiet = [console.log, console.warn, console.error];
    console.log = console.warn = console.error = () => {};
    try {
      await handleAdRewardCallback({ method, originalUrl: url }, res, deps);
    } finally {
      [console.log, console.warn, console.error] = quiet;
    }
    return { status, granted: granted.map((r) => r.transactionId) };
  }
  check("a good callback: 200 and the tickets", await call(`/?${good}`),
    { status: 200, granted: ["18fa792de1bca816048293fc71035638"] });
  check("under the function's own path too", (await call(`/admobRewardCallback?${good}`)).status, 200);
  check("POST: 405, nothing", await call(`/?${good}`, { method: "POST" }), { status: 405, granted: [] });
  check("no query: 400", await call("/"), { status: 400, granted: [] });
  check("another key's signature: 403, nothing",
    await call(`/?${callback(reward(), { key: stranger.privateKey })}`), { status: 403, granted: [] });
  check("a key_id Google doesn't have: 403, nothing",
    await call(`/?${callback(reward(), { keyId: "42" })}`), { status: 403, granted: [] });
  check("a changed user_id: 403, nothing", await call(`/?${good.replace(UID, "Zz3dEf6hIj9kLm2nOp5qRs8tUv1w")}`),
    { status: 403, granted: [] });
  check("the scenario unlock's ad: 200, no tickets",
    await call(`/?${callback(reward({ custom_data: "unlock" }))}`), { status: 200, granted: [] });
  check("another ad unit: 200, no tickets",
    await call(`/?${callback(reward({ ad_unit: "8704677710" }))}`), { status: 200, granted: [] });
  check("Google's keys can't be loaded: 500 (AdMob tries again)", await call(`/?${good}`, {
    keyStore: { get: async () => { throw new Error("offline"); } },
  }), { status: 500, granted: [] });
  check("Firestore fails: 500 (AdMob tries again)", await call(`/?${good}`, {
    grant: async () => { throw new Error("unavailable"); },
  }), { status: 500, granted: [] });
  for (const outcome of ["daily_cap", "duplicate", "no_user"]) {
    check(`${outcome}: 200 (not sent again)`, (await call(`/?${good}`, { grant: async () => outcome })).status, 200);
  }

  console.log(fail === 0 ? "\nAll checks passed.\n" : `\n${fail} check(s) failed.\n`);
  process.exit(fail === 0 ? 0 : 1);
})();
