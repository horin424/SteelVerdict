/**
 * Offline verification: a missing player document is created on first use.
 *
 * onUserCreated creates users/{uid} at sign-up. When that trigger failed, every
 * callable failed for the account with "User not found", for good: no battle,
 * no daily reward, no purchase granted. ensureUserDoc now creates the document
 * with the starting values on the account's first call, and leaves deleted
 * accounts deleted.
 *
 * Firestore and Auth are stubbed, so this runs with no emulator, no
 * credentials and no network. skipAd is driven through firebase-functions-test
 * as one real callable end to end.
 *
 * Run: npm run verify:userdoc
 */
process.env.GCLOUD_PROJECT = "demo-steelverdict";

const admin = require("firebase-admin");
const ft = require("firebase-functions-test")();

let docs = {};
let created = [];
let authUsers = {};
let createError = null;

const db = {
  collection: () => ({
    doc: (id) => ({
      id,
      get: async () => ({ exists: docs[id] !== undefined, data: () => docs[id] }),
      create: async (data) => {
        if (createError) throw createError;
        created.push({ id, data });
        docs[id] = data;
      },
    }),
  }),
  runTransaction: async (fn) => fn({
    get: async (ref) => ({ exists: docs[ref.id] !== undefined, data: () => docs[ref.id] }),
    update: (ref, patch) => { docs[ref.id] = { ...docs[ref.id], ...patch }; },
  }),
};
const auth = {
  getUser: async (uid) => {
    if (!authUsers[uid]) throw Object.assign(new Error("no user record"), { code: "auth/user-not-found" });
    return authUsers[uid];
  },
};
// Both are getter-only properties on the namespace: plain assignment no-ops.
Object.defineProperty(admin, "firestore", { value: () => db, configurable: true, writable: true });
Object.defineProperty(admin, "auth", { value: () => auth, configurable: true, writable: true });

const { ensureUserDoc } = require("../lib/utils/firestore");
const { skipAd } = require("../lib/tickets/skipAd");
const wrappedSkipAd = ft.wrap(skipAd);

function reset(state) {
  docs = state.docs || {};
  authUsers = state.auth || {};
  createError = state.createError || null;
  created = [];
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
async function outcome(run) {
  try {
    await run();
    return "ok";
  } catch (e) {
    return e.code || e.message;
  }
}

(async () => {
  console.log("\nensureUserDoc: a missing player document is created on first use\n");

  reset({ docs: { u1: { ticketCount: 7 } }, auth: { u1: { uid: "u1" } } });
  await ensureUserDoc("u1");
  check("document exists -> left as it is", [created.length, docs.u1.ticketCount], [0, 7]);

  reset({ auth: { u1: { uid: "u1", displayName: "Alice" } } });
  await ensureUserDoc("u1");
  const made = created[0]?.data || {};
  check("missing -> created once", created.length, 1);
  check("missing -> the starting values",
    [made.uid, made.ticketCount, made.subscriptionTier, made.isBossEnabled, made.lastDailyRewardAt],
    ["u1", 3, "free", false, 0]);
  check("missing -> the account's name", made.displayName, "Alice");

  reset({ auth: { u1: { uid: "u1", email: "bob@example.com" } } });
  await ensureUserDoc("u1");
  check("name from the email, as at sign-up", created[0]?.data.displayName, "bob");

  reset({ auth: { u1: { uid: "u1" } } });
  await ensureUserDoc("u1");
  check("guest -> no name (the app shows 匿名司令官)", created[0]?.data.displayName, "");

  reset({});
  check("deleted account -> not-found", await outcome(() => ensureUserDoc("u1")), "not-found");
  check("deleted account -> not brought back", created.length, 0);

  reset({ auth: { u1: { uid: "u1" } }, createError: Object.assign(new Error("exists"), { code: 6 }) });
  check("created by a parallel call meanwhile -> fine", await outcome(() => ensureUserDoc("u1")), "ok");

  reset({ auth: { u1: { uid: "u1" } }, createError: Object.assign(new Error("unavailable"), { code: 14 }) });
  check("any other write error -> reported", await outcome(() => ensureUserDoc("u1")), 14);

  console.log("\none callable end to end (skipAd)\n");

  reset({ auth: { u1: { uid: "u1", displayName: "Alice" } } });
  let result = null;
  const end = await outcome(async () => {
    result = await wrappedSkipAd({ auth: { uid: "u1", token: {} }, data: {} });
  });
  check("missing document -> skipAd works instead of failing", end, "ok");
  check("the starting 3 tickets, minus the 1 spent", result?.newTicketCount, 2);
  check("the document now exists with that count", docs.u1?.ticketCount, 2);

  ft.cleanup();
  console.log(fail ? `\n${fail} check(s) FAILED\n` : "\nall checks passed\n");
  process.exit(fail ? 1 : 0);
})();
