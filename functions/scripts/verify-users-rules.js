/**
 * Checks the users/{uid} rules (B10) against a running Firestore emulator.
 *
 * The client may change only displayName (up to 30 characters) and
 * lastLoginAt (a number). Everything else in a user document - tickets,
 * subscription, rewards, stats, unlocks, and any field added later - is
 * server-only. The old rule listed blocked fields instead, so a new field
 * (for example subscriptionExpiresAt) was writable by the client.
 *
 * Needs the emulator, started with this repo's rules, e.g.:
 *   java -jar cloud-firestore-emulator-v1.19.8.jar --host 127.0.0.1 --port 8080
 *     --project_id demo-steelverdict --rules firestore.rules --single_project_mode true
 * Then: npm run verify:rules   (FIRESTORE_EMULATOR_HOST overrides 127.0.0.1:8080)
 *
 * Requests go to the emulator's REST API: "Bearer owner" seeds data past the
 * rules, and an unsigned token (accepted only by the emulator) acts as a user.
 */
const HOST = process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";
const PROJECT = "demo-steelverdict";
const BASE = `http://${HOST}/v1/projects/${PROJECT}/databases/(default)/documents`;

function tokenFor(uid) {
  const b64 = (o) => Buffer.from(JSON.stringify(o)).toString("base64url");
  const now = Math.floor(Date.now() / 1000);
  return [
    b64({ alg: "none", typ: "JWT" }),
    b64({
      iss: `https://securetoken.google.com/${PROJECT}`,
      aud: PROJECT,
      sub: uid,
      user_id: uid,
      iat: now,
      exp: now + 3600,
      auth_time: now,
      firebase: { sign_in_provider: "password" },
    }),
    "",
  ].join(".");
}

function value(v) {
  if (typeof v === "string") return { stringValue: v };
  if (typeof v === "boolean") return { booleanValue: v };
  if (Number.isInteger(v)) return { integerValue: String(v) };
  return { doubleValue: v };
}

async function request(method, path, { as, fields, mask } = {}) {
  const query = mask ? "?" + mask.map((f) => `updateMask.fieldPaths=${f}`).join("&") : "";
  const headers = { "Content-Type": "application/json" };
  if (as) headers.Authorization = `Bearer ${as === "owner" ? "owner" : tokenFor(as)}`;
  const body = fields
    ? JSON.stringify({ fields: Object.fromEntries(Object.entries(fields).map(([k, v]) => [k, value(v)])) })
    : undefined;
  const res = await fetch(`${BASE}/${path}${query}`, { method, headers, body });
  return res.status;
}

// A fresh copy of a user document before every case, written past the rules.
const ALICE = {
  displayName: "Alice",
  lastLoginAt: 1000,
  ticketCount: 3,
  subscriptionTier: "free",
  isBossEnabled: false,
};
async function reset() {
  await request("DELETE", "users/uid-alice", { as: "owner" });
  await request("PATCH", "users/uid-alice", { as: "owner", fields: ALICE });
}

const update = (as, fields) =>
  request("PATCH", "users/uid-alice", { as, fields, mask: Object.keys(fields) });

let fail = 0;
async function expect(name, expected, run) {
  await reset();
  const status = await run();
  const got = status === 200 ? "allowed" : status === 403 ? "denied" : `HTTP ${status}`;
  if (got === expected) {
    console.log(`  ok   ${name}: ${got}`);
  } else {
    fail++;
    console.log(`  FAIL ${name}: expected ${expected}, got ${got}`);
  }
}

(async () => {
  console.log(`\n(B10) users/{uid} rules, emulator at ${HOST}\n`);
  const A = "uid-alice";

  await expect("change own displayName", "allowed", () => update(A, { displayName: "Alicia" }));
  await expect("change own lastLoginAt (a number)", "allowed", () => update(A, { lastLoginAt: 2000 }));
  await expect("displayName of 30 characters", "allowed", () => update(A, { displayName: "a".repeat(30) }));
  await expect("displayName of 31 characters", "denied", () => update(A, { displayName: "a".repeat(31) }));
  await expect("lastLoginAt as text", "denied", () => update(A, { lastLoginAt: "yesterday" }));
  await expect("own ticketCount", "denied", () => update(A, { ticketCount: 99 }));
  await expect("own subscriptionTier", "denied", () => update(A, { subscriptionTier: "sub3000" }));
  await expect("own isBossEnabled", "denied", () => update(A, { isBossEnabled: true }));
  await expect("a field added later (subscriptionExpiresAt)", "denied", () =>
    update(A, { subscriptionExpiresAt: 4102444800000 }));
  await expect("displayName together with ticketCount", "denied", () =>
    update(A, { displayName: "Alicia", ticketCount: 99 }));
  await expect("another player's displayName", "denied", () => update("uid-bob", { displayName: "Bob was here" }));
  await expect("signed out", "denied", () =>
    request("PATCH", "users/uid-alice", { fields: { displayName: "x" }, mask: ["displayName"] }));
  await expect("read own document", "allowed", () => request("GET", "users/uid-alice", { as: A }));
  await expect("read another player's document", "denied", () => request("GET", "users/uid-alice", { as: "uid-bob" }));
  await expect("create a user document", "denied", () =>
    request("PATCH", "users/uid-carol", { as: "uid-carol", fields: { displayName: "Carol", ticketCount: 999 } }));
  await expect("delete own document", "denied", () => request("DELETE", "users/uid-alice", { as: A }));

  console.log(fail ? `\n${fail} check(s) FAILED\n` : "\nall checks passed\n");
  process.exit(fail ? 1 : 0);
})();
