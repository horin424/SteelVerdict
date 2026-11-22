/**
 * Checks the users/{uid} rules (B10), the pvp_matches rules (B1), the
 * content_reports rules (reports of AI output: admins read them and may only
 * mark them handled) and the ai_usage rules (the daily AI limits: admins read
 * the day's count, nobody writes it) against a running Firestore emulator.
 *
 * PvP matches are written only by Cloud Functions. Players used to be allowed
 * to write their own strategy directly, which skipped submitPvpStrategy's
 * ticket charge.
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
  if (Array.isArray(v)) return { arrayValue: { values: v.map(value) } };
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
// Alice and Bob's match, also fresh before every case.
const MATCH = {
  playerAUid: "uid-alice",
  playerBUid: "uid-bob",
  playerAStrategy: "",
  playerBStrategy: "",
  winner: "",
  status: "active",
};
// A report of AI output (the 「報告」 button) and the admin list, also fresh.
const REPORT = {
  uid: "uid-alice",
  kind: "battle",
  reason: "offensive",
  aiText: "The enemy ...",
  status: "new",
  createdAt: 1000,
};
// A day's count of AI calls (the daily AI limits), also fresh.
const USAGE = { day: "2026-11-22", count: 5, free: 2, updatedAt: 1000 };
async function reset() {
  await request("DELETE", "users/uid-alice", { as: "owner" });
  await request("PATCH", "users/uid-alice", { as: "owner", fields: ALICE });
  await request("DELETE", "pvp_matches/m1", { as: "owner" });
  await request("PATCH", "pvp_matches/m1", { as: "owner", fields: MATCH });
  await request("PATCH", "system_config/admin_uids", { as: "owner", fields: { uids: ["uid-admin"] } });
  await request("DELETE", "content_reports/r1", { as: "owner" });
  await request("PATCH", "content_reports/r1", { as: "owner", fields: REPORT });
  await request("DELETE", "ai_usage/2026-11-22", { as: "owner" });
  await request("PATCH", "ai_usage/2026-11-22", { as: "owner", fields: USAGE });
}

const update = (as, fields) =>
  request("PATCH", "users/uid-alice", { as, fields, mask: Object.keys(fields) });
const updateMatch = (as, fields) =>
  request("PATCH", "pvp_matches/m1", { as, fields, mask: Object.keys(fields) });

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

  console.log("\n(B1) pvp_matches rules\n");
  await expect("write own strategy directly (skips the charge)", "denied", () =>
    updateMatch(A, { playerAStrategy: "Hold the ridge." }));
  await expect("write the opponent's strategy", "denied", () =>
    updateMatch(A, { playerBStrategy: "Retreat." }));
  await expect("set the winner", "denied", () => updateMatch(A, { winner: A }));
  await expect("create a match", "denied", () =>
    request("PATCH", "pvp_matches/m2", { as: A, fields: { playerAUid: A, playerBUid: "" } }));
  await expect("delete own match", "denied", () => request("DELETE", "pvp_matches/m1", { as: A }));
  await expect("read own match", "allowed", () => request("GET", "pvp_matches/m1", { as: A }));
  await expect("read another pair's match", "denied", () =>
    request("GET", "pvp_matches/m1", { as: "uid-carol" }));

  console.log("\ncontent_reports rules (the 「報告」 button)\n");
  const ADMIN = "uid-admin";
  const markReport = (as, fields) =>
    request("PATCH", "content_reports/r1", { as, fields, mask: Object.keys(fields) });
  await expect("an admin reads a report", "allowed", () => request("GET", "content_reports/r1", { as: ADMIN }));
  await expect("an admin lists the reports", "allowed", () => request("GET", "content_reports", { as: ADMIN }));
  await expect("the reporter reads their own report", "denied", () => request("GET", "content_reports/r1", { as: A }));
  await expect("a player lists the reports", "denied", () => request("GET", "content_reports", { as: A }));
  await expect("signed out", "denied", () => request("GET", "content_reports/r1"));
  await expect("a player writes a report directly (skips the daily limit)", "denied", () =>
    request("PATCH", "content_reports/r2", { as: A, fields: { ...REPORT } }));
  await expect("an admin writes a report directly", "denied", () =>
    request("PATCH", "content_reports/r2", { as: ADMIN, fields: { ...REPORT } }));
  await expect("an admin marks it handled", "allowed", () =>
    markReport(ADMIN, { status: "done", reviewedAt: 2000, reviewedBy: ADMIN }));
  await expect("an admin sets it back to new", "allowed", () => markReport(ADMIN, { status: "new" }));
  await expect("an admin marks it handled in another admin's name", "denied", () =>
    markReport(ADMIN, { status: "done", reviewedBy: "uid-someone" }));
  await expect("reviewedAt as text", "denied", () => markReport(ADMIN, { status: "done", reviewedAt: "today" }));
  await expect("a status that isn't new or done", "denied", () => markReport(ADMIN, { status: "deleted" }));
  await expect("an admin changes the reported text", "denied", () => markReport(ADMIN, { aiText: "nothing here" }));
  await expect("an admin deletes a report", "denied", () => request("DELETE", "content_reports/r1", { as: ADMIN }));
  await expect("a player marks it handled", "denied", () => markReport(A, { status: "done", reviewedBy: A }));

  console.log("\nthe daily AI limits: the player's counters and ai_usage\n");
  await expect("own AI counter (aiCallsCount)", "denied", () => update(A, { aiCallsCount: 0 }));
  await expect("own AI day and free counter", "denied", () =>
    update(A, { aiCallsDate: "2000-01-01", aiFreeCallsCount: 0 }));
  const writeUsage = (as, fields) =>
    request("PATCH", "ai_usage/2026-11-22", { as, fields, mask: Object.keys(fields) });
  await expect("an admin reads a day's count", "allowed", () => request("GET", "ai_usage/2026-11-22", { as: ADMIN }));
  await expect("an admin lists the days", "allowed", () => request("GET", "ai_usage", { as: ADMIN }));
  await expect("a player reads a day's count", "denied", () => request("GET", "ai_usage/2026-11-22", { as: A }));
  await expect("a player lists the days", "denied", () => request("GET", "ai_usage", { as: A }));
  await expect("signed out", "denied", () => request("GET", "ai_usage/2026-11-22"));
  await expect("a player resets the day's count", "denied", () => writeUsage(A, { count: 0 }));
  await expect("a player starts a new day", "denied", () =>
    request("PATCH", "ai_usage/2026-11-23", { as: A, fields: { ...USAGE, day: "2026-11-23", count: 0 } }));
  await expect("an admin changes the day's count", "denied", () => writeUsage(ADMIN, { count: 0 }));
  await expect("an admin deletes a day", "denied", () => request("DELETE", "ai_usage/2026-11-22", { as: ADMIN }));

  console.log(fail ? `\n${fail} check(s) FAILED\n` : "\nall checks passed\n");
  process.exit(fail ? 1 : 0);
})();
