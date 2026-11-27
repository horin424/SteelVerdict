/**
 * Offline checks of the AI keys and models set from the PC admin (client point
 * ②, 27 Nov 2026):
 * - src/ai/keys.ts: key formats, the last 4 characters, and the run-time key
 *   reader (its cache, the fallback to the deployed key, no key in the logs);
 * - src/ai/models.ts: which model each AI use gets;
 * - src/ai/providers.ts: the tiny check call and the model lists, against a
 *   fake fetch (what is sent, and how each answer is read);
 * - src/ai/aiSettings.ts: the three admin callables, with a fake Secret Manager;
 * - that every AI call reads its key through aiKey().
 * No network, no credentials, no AI spend.
 *
 * Run: npm run verify:aikeys
 */
const fs = require("fs");
const path = require("path");

delete process.env.K_SERVICE; // not on Cloud Functions: aiKey() must use the deployed key
process.env.GEMINI_API_KEY = "deployed-gemini-key-for-tests";
process.env.CLAUDE_API_KEY = "deployed-claude-key-for-tests";

const keys = require("../lib/ai/keys");
const models = require("../lib/ai/models");
const providers = require("../lib/ai/providers");
const settings = require("../lib/ai/aiSettings");
const { versionId } = require("../lib/ai/secretStore");
const { aiKey } = require("../lib/ai/apiKey");

let fail = 0;
function check(name, actual, expected) {
  if (JSON.stringify(actual) === JSON.stringify(expected)) {
    console.log(`  ok   ${name}`);
  } else {
    fail++;
    console.log(`  FAIL ${name} - expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

// Key-shaped values are built here, so no key-like text sits in the source.
const GEMINI_KEY = "AI" + "za" + "A".repeat(31) + "1234";
const GEMINI_KEY_2 = "AI" + "za" + "B".repeat(31) + "5678";
const CLAUDE_KEY = "sk-" + "ant-api03-" + "x".repeat(80) + "AbCd";
const CLAUDE_KEY_2 = "sk-" + "ant-api03-" + "y".repeat(80) + "WxYz";
const ALL_KEYS = [GEMINI_KEY, GEMINI_KEY_2, CLAUDE_KEY, CLAUDE_KEY_2];
const holdsAKey = (v) => ALL_KEYS.some((k) => JSON.stringify(v).includes(k));

/** A Secret Manager with versions in memory. */
function fakeStore(start = { GEMINI_API_KEY: GEMINI_KEY, CLAUDE_API_KEY: CLAUDE_KEY }) {
  const versions = {};
  for (const [secret, value] of Object.entries(start)) {
    versions[secret] = [{ value, createTime: "2026-11-01T00:00:00Z" }];
  }
  const s = {
    versions,
    accessCalls: 0,
    failAccess: new Set(),
    failAdd: false,
    permissions: ["secretmanager.versions.access", "secretmanager.versions.add", "secretmanager.versions.get"],
    async accessLatest(secret) {
      s.accessCalls++;
      if (s.failAccess.has(secret)) throw Object.assign(new Error("Permission denied on the secret"), { code: 403 });
      const v = versions[secret];
      if (!v) throw Object.assign(new Error("Secret not found"), { code: 404 });
      return { value: v[v.length - 1].value, version: String(v.length) };
    },
    async addVersion(secret, value) {
      if (s.failAdd) throw Object.assign(new Error("Permission 'secretmanager.versions.add' denied"), { code: 403 });
      versions[secret].push({ value, createTime: "2026-11-27T10:00:00Z" });
      return { version: String(versions[secret].length), createTime: "2026-11-27T10:00:00Z" };
    },
    async getVersion(secret, version) {
      const v = versions[secret][Number(version) - 1];
      if (!v) throw new Error("no such version");
      return { createTime: v.createTime, state: "ENABLED" };
    },
    async testPermissions(_secret, wanted) {
      return wanted.filter((p) => s.permissions.includes(p));
    },
  };
  return s;
}

async function rejection(promise) {
  try {
    await promise;
    return "no error";
  } catch (err) {
    return { code: err.code ?? null, message: err.message, details: err.details ?? null };
  }
}

/** A fetch that answers [status] with [body] and records what was sent. */
function fakeFetch(status, body) {
  const sent = [];
  const fn = async (url, init = {}) => {
    sent.push({ url, method: init.method ?? "GET", headers: init.headers ?? {}, body: init.body ? JSON.parse(init.body) : null });
    if (status === "throw") throw new Error("getaddrinfo ENOTFOUND");
    return { ok: status >= 200 && status < 300, status, json: async () => body };
  };
  return { fn, sent };
}

(async () => {
  console.log("\nkey formats and the last 4 characters\n");
  check("a Gemini key is taken", keys.checkKeyFormat("gemini", GEMINI_KEY), { key: GEMINI_KEY });
  check("spaces and a line break around it are trimmed", keys.checkKeyFormat("gemini", `  ${GEMINI_KEY}\n`), { key: GEMINI_KEY });
  check("a Gemini key one character short", keys.checkKeyFormat("gemini", GEMINI_KEY.slice(0, -1)), { refusal: "invalid_key_format" });
  check("a Gemini key with a stray character", keys.checkKeyFormat("gemini", GEMINI_KEY.slice(0, -1) + "!"), { refusal: "invalid_key_format" });
  check("a Claude key pasted as Gemini's", keys.checkKeyFormat("gemini", CLAUDE_KEY), { refusal: "invalid_key_format" });
  check("a Claude key is taken", keys.checkKeyFormat("claude", CLAUDE_KEY), { key: CLAUDE_KEY });
  check("a Gemini key pasted as Claude's", keys.checkKeyFormat("claude", GEMINI_KEY), { refusal: "invalid_key_format" });
  check("a too short Claude key", keys.checkKeyFormat("claude", "sk-" + "ant-abc"), { refusal: "invalid_key_format" });
  check("nothing", keys.checkKeyFormat("claude", ""), { refusal: "empty_key" });
  check("only spaces", keys.checkKeyFormat("gemini", "   "), { refusal: "empty_key" });
  check("not text", keys.checkKeyFormat("gemini", 42), { refusal: "empty_key" });
  check("last 4 of a key", keys.lastFour(GEMINI_KEY), "1234");
  check("nothing of a short value", keys.lastFour("abcdefg"), "");
  check("an error is described with its status", keys.describe({ response: { status: 403 }, message: "Permission denied" }), "403 Permission denied");
  check("a long message is cut", keys.describe(new Error("x".repeat(500))).length, 200);

  console.log("\nthe run-time key reader\n");
  {
    const store = fakeStore();
    let t = 1000;
    const logs = [];
    const reader = keys.makeKeyReader(() => store, { ttlMs: 60000, now: () => t, log: (l) => logs.push(l) });
    const deployed = () => "deployed-key";
    check("the first read gets the newest version", await reader.read("gemini", deployed), GEMINI_KEY);
    check("one Secret Manager read", store.accessCalls, 1);
    t += 59000;
    check("within a minute: the same key, no new read", [await reader.read("gemini", deployed), store.accessCalls], [GEMINI_KEY, 1]);
    store.versions.GEMINI_API_KEY.push({ value: GEMINI_KEY_2 + "\n", createTime: "x" });
    t += 2000;
    check("after a minute: the newest key, trimmed", await reader.read("gemini", deployed), GEMINI_KEY_2);
    check("the new version is logged", logs[logs.length - 1], "[aiKey] gemini: using Secret Manager version 2");
    check("each provider has its own key", await reader.read("claude", deployed), CLAUDE_KEY);
    store.versions.CLAUDE_API_KEY.push({ value: CLAUDE_KEY_2, createTime: "x" });
    reader.forget("claude");
    check("forget: the next read gets the new key at once", await reader.read("claude", deployed), CLAUDE_KEY_2);

    store.failAccess.add("GEMINI_API_KEY");
    t += 61000;
    check("Secret Manager fails: the key read before is kept", await reader.read("gemini", deployed), GEMINI_KEY_2);
    const calls = store.accessCalls;
    t += 30000;
    check("and it is not asked again until a minute has passed", [await reader.read("gemini", deployed), store.accessCalls], [GEMINI_KEY_2, calls]);
    check("no key in any log line", holdsAKey(logs), false);
  }
  {
    const store = fakeStore();
    store.failAccess.add("CLAUDE_API_KEY");
    const logs = [];
    const reader = keys.makeKeyReader(() => store, { log: (l) => logs.push(l) });
    check("Secret Manager fails at the start: the deployed key", await reader.read("claude", () => " deployed-key "), "deployed-key");
    check("and the log says so", logs[0].includes("using the deployed key"), true);
    check("the deployed key is then kept for a minute", await reader.read("claude", () => ""), "deployed-key");
  }
  {
    // A fresh reader, so nothing is cached.
    const store = fakeStore();
    store.failAccess.add("CLAUDE_API_KEY");
    const reader = keys.makeKeyReader(() => store, { log: () => {} });
    const r = await rejection(reader.read("claude", () => { throw new Error("no value for secret"); }));
    check("no deployed key either: the AI call fails", typeof r === "object" && r.message.startsWith("No claude API key"), true);
  }
  {
    const store = fakeStore({ GEMINI_API_KEY: "  \n", CLAUDE_API_KEY: CLAUDE_KEY });
    const reader = keys.makeKeyReader(() => store, { log: () => {} });
    check("an empty newest version: the deployed key", await reader.read("gemini", () => "deployed-key"), "deployed-key");
  }
  {
    const store = fakeStore();
    let release;
    const gate = new Promise((r) => { release = r; });
    const slow = { ...store, accessLatest: async (s) => { store.accessCalls++; await gate; return { value: GEMINI_KEY, version: "1" }; } };
    const reader = keys.makeKeyReader(() => slow, { log: () => {} });
    const reads = [reader.read("gemini", () => ""), reader.read("gemini", () => ""), reader.read("gemini", () => "")];
    release();
    check("three calls at once: one Secret Manager read", [await Promise.all(reads), store.accessCalls], [[GEMINI_KEY, GEMINI_KEY, GEMINI_KEY], 1]);
  }
  check("off Cloud Functions, aiKey() uses the deployed key", [await aiKey("gemini"), await aiKey("claude")],
    ["deployed-gemini-key-for-tests", "deployed-claude-key-for-tests"]);

  console.log("\nwhich model each use gets\n");
  check("the five model settings", models.MODEL_KEY_NAMES, ["claude", "war_history", "gemini_flash", "gemini_flash_lite", "pvp_judge"]);
  check("戦史 with nothing set: Claude Haiku", models.configuredModel({}, "war_history"), "claude-haiku-4-5-20251001");
  check("戦史 set by the admin, trimmed", models.configuredModel({ war_history: " claude-sonnet-4-5 " }, "war_history"), "claude-sonnet-4-5");
  check("the PvP judge with nothing set: Gemini Flash", models.configuredModel(undefined, "pvp_judge"), "gemini-2.5-flash");
  check("a blank setting: the default", models.configuredModel({ claude: "  " }, "claude"), "claude-haiku-4-5-20251001");
  check("a setting that isn't text: the default", models.configuredModel({ gemini_flash: 5 }, "gemini_flash"), "gemini-2.5-flash");
  check("practice with nothing set: Flash-Lite", models.configuredModel(null, "gemini_flash_lite"), "gemini-2.5-flash-lite");
  check("a new Gemini key is checked against each Gemini model once", models.modelsOfProvider({}, "gemini"), ["gemini-2.5-flash", "gemini-2.5-flash-lite"]);
  check("and a new Claude key against Claude's", models.modelsOfProvider({ war_history: "claude-sonnet-4-5" }, "claude"),
    ["claude-haiku-4-5-20251001", "claude-sonnet-4-5"]);
  check("a model name is trimmed, Google's prefix dropped", models.checkModelName("  models/gemini-2.5-pro "), { model: "gemini-2.5-pro" });
  check("a Claude model id", models.checkModelName("claude-haiku-4-5-20251001"), { model: "claude-haiku-4-5-20251001" });
  check("an empty name is refused", models.checkModelName(""), { refusal: "invalid_model" });
  check("a name with a space is refused", models.checkModelName("gemini 2.5"), { refusal: "invalid_model" });
  check("a path is refused", models.checkModelName("../secrets"), { refusal: "invalid_model" });
  check("a name of 101 characters is refused", models.checkModelName("a".repeat(101)), { refusal: "invalid_model" });
  check("a name that isn't text is refused", models.checkModelName(7), { refusal: "invalid_model" });

  console.log("\nthe check call: Gemini\n");
  {
    const f = fakeFetch(200, { candidates: [] });
    check("a working key and model", await providers.tryModel("gemini", GEMINI_KEY, "gemini-2.5-flash", f.fn), { ok: true });
    const req = f.sent[0];
    check("it asks generateContent of that model", [req.method, req.url],
      ["POST", "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"]);
    check("the key goes in a header, not the URL", [req.headers["x-goog-api-key"] === GEMINI_KEY, req.url.includes(GEMINI_KEY)], [true, false]);
    check("at most 16 output tokens", req.body.generationConfig, { maxOutputTokens: 16 });
  }
  const gemini = async (status, error) => providers.tryModel("gemini", GEMINI_KEY, "gemini-2.5-flash", fakeFetch(status, { error }).fn);
  check("a wrong key (400 API_KEY_INVALID)", await gemini(400, {
    code: 400, status: "INVALID_ARGUMENT", message: "API key not valid. Please pass a valid API key.",
    details: [{ "@type": "type.googleapis.com/google.rpc.ErrorInfo", reason: "API_KEY_INVALID" }],
  }), { ok: false, reason: "invalid_key", status: 400 });
  check("a key not allowed to use the API (403)", await gemini(403, { status: "PERMISSION_DENIED", message: "Method doesn't allow unregistered callers" }),
    { ok: false, reason: "invalid_key", status: 403 });
  check("no credit (402)", await gemini(402, { message: "Prepayment credits are depleted" }), { ok: false, reason: "no_credit", status: 402 });
  check("billing needed (400 FAILED_PRECONDITION)", await gemini(400, { status: "FAILED_PRECONDITION", message: "Please enable billing for this project." }),
    { ok: false, reason: "no_credit", status: 400 });
  check("an unknown model (404)", await gemini(404, { status: "NOT_FOUND", message: "models/gemini-9 is not found for API version v1beta" }),
    { ok: false, reason: "model_not_found", status: 404 });
  check("a malformed model name (400)", await gemini(400, { status: "INVALID_ARGUMENT", message: "* GenerateContentRequest.model: unexpected model name format" }),
    { ok: false, reason: "model_not_found", status: 400 });
  check("the limit for now is reached (429)", await gemini(429, { status: "RESOURCE_EXHAUSTED", message: "Resource has been exhausted" }),
    { ok: false, reason: "rate_limited", status: 429 });
  check("a server error (500)", await gemini(500, { status: "INTERNAL", message: "An internal error has occurred." }),
    { ok: false, reason: "provider_error", status: 500 });
  check("an answer that isn't JSON", await providers.tryModel("gemini", GEMINI_KEY, "gemini-2.5-flash",
    async () => ({ ok: false, status: 502, json: async () => { throw new Error("not json"); } })), { ok: false, reason: "provider_error", status: 502 });
  check("no answer", await providers.tryModel("gemini", GEMINI_KEY, "gemini-2.5-flash", fakeFetch("throw").fn), { ok: false, reason: "network" });

  console.log("\nthe check call: Claude\n");
  {
    const f = fakeFetch(200, { content: [{ type: "text", text: "OK" }] });
    check("a working key and model", await providers.tryModel("claude", CLAUDE_KEY, "claude-haiku-4-5-20251001", f.fn), { ok: true });
    const req = f.sent[0];
    check("it asks the Messages API", [req.method, req.url], ["POST", "https://api.anthropic.com/v1/messages"]);
    check("the key and version in headers", [req.headers["x-api-key"] === CLAUDE_KEY, req.headers["anthropic-version"]], [true, "2023-06-01"]);
    check("that model, at most 16 output tokens", [req.body.model, req.body.max_tokens], ["claude-haiku-4-5-20251001", 16]);
  }
  const claude = async (status, error) => providers.tryModel("claude", CLAUDE_KEY, "claude-haiku-4-5-20251001",
    fakeFetch(status, { type: "error", error }).fn);
  check("a wrong key (401)", await claude(401, { type: "authentication_error", message: "invalid x-api-key" }),
    { ok: false, reason: "invalid_key", status: 401 });
  check("a key without permission (403)", await claude(403, { type: "permission_error", message: "Your API key does not have permission" }),
    { ok: false, reason: "invalid_key", status: 403 });
  check("no credit (400)", await claude(400, { type: "invalid_request_error", message: "Your credit balance is too low to access the Anthropic API." }),
    { ok: false, reason: "no_credit", status: 400 });
  check("an unknown model (404)", await claude(404, { type: "not_found_error", message: "model: claude-9" }),
    { ok: false, reason: "model_not_found", status: 404 });
  check("another bad request (400)", await claude(400, { type: "invalid_request_error", message: "max_tokens: too large" }),
    { ok: false, reason: "provider_error", status: 400 });
  check("the limit for now is reached (429)", await claude(429, { type: "rate_limit_error", message: "Number of requests has exceeded your rate limit" }),
    { ok: false, reason: "rate_limited", status: 429 });
  check("overloaded (529)", await claude(529, { type: "overloaded_error", message: "Overloaded" }),
    { ok: false, reason: "provider_error", status: 529 });

  console.log("\nthe model lists\n");
  {
    const f = fakeFetch(200, { models: [
      { name: "models/gemini-2.5-flash", supportedGenerationMethods: ["generateContent", "countTokens"] },
      { name: "models/text-embedding-004", supportedGenerationMethods: ["embedContent"] },
      { name: "models/gemini-2.5-pro", supportedGenerationMethods: ["generateContent"] },
      { name: "models/imagen-4.0-generate-001", supportedGenerationMethods: ["predict"] },
      { name: "models/gemini-2.5-flash", supportedGenerationMethods: ["generateContent"] },
      { name: 12 },
    ] });
    check("Gemini: the text models, sorted, once each", await providers.listModels("gemini", GEMINI_KEY, f.fn),
      { models: ["gemini-2.5-flash", "gemini-2.5-pro"] });
    check("asked with the key in a header", [f.sent[0].url.includes(GEMINI_KEY), f.sent[0].headers["x-goog-api-key"] === GEMINI_KEY], [false, true]);
  }
  check("Claude: the model ids, sorted", await providers.listModels("claude", CLAUDE_KEY, fakeFetch(200, { data: [
    { id: "claude-sonnet-4-5-20250929", type: "model" }, { id: "claude-haiku-4-5-20251001", type: "model" },
  ] }).fn), { models: ["claude-haiku-4-5-20251001", "claude-sonnet-4-5-20250929"] });
  check("a wrong key: refused", await providers.listModels("claude", CLAUDE_KEY,
    fakeFetch(401, { type: "error", error: { type: "authentication_error", message: "invalid x-api-key" } }).fn), { refusal: "invalid_key" });
  check("no answer", await providers.listModels("gemini", GEMINI_KEY, fakeFetch("throw").fn), { refusal: "network" });
  check("an odd body: an empty list", await providers.listModels("gemini", GEMINI_KEY, fakeFetch(200, { foo: 1 }).fn), { models: [] });

  console.log("\nthe admin callables\n");
  function setup(opts = {}) {
    const store = opts.store ?? fakeStore();
    const calls = { tried: [], saved: [], logs: [] };
    const deps = {
      isAdmin: async (uid) => uid === "admin-1",
      store,
      modelConfig: async () => opts.modelConfig ?? {},
      tryModel: async (p, k, m) => {
        calls.tried.push([p, k === GEMINI_KEY_2 || k === CLAUDE_KEY_2 ? "new key" : "current key", m]);
        return opts.tryModel ? opts.tryModel(p, k, m) : { ok: true };
      },
      listModels: async (p) => opts.listModels ? opts.listModels(p)
        : { models: p === "gemini" ? ["gemini-2.5-flash"] : ["claude-haiku-4-5-20251001"] },
      keySaved: (p) => calls.saved.push(p),
      log: (l) => calls.logs.push(l),
    };
    return { deps, store, calls };
  }

  // getAiSettings
  {
    const { deps } = setup();
    check("getAiSettings without sign-in", (await rejection(settings.handleGetAiSettings(deps, undefined))).code, "unauthenticated");
    check("getAiSettings for a player", await rejection(settings.handleGetAiSettings(deps, "player-1")),
      { code: "permission-denied", message: "NOT_ADMIN", details: null });
    const r = await settings.handleGetAiSettings(deps, "admin-1");
    check("each key: last 4, when it was saved, may save, its models", r, { keys: {
      gemini: { last4: "1234", savedAt: "2026-11-01T00:00:00Z", version: "1", canSave: true, models: ["gemini-2.5-flash"] },
      claude: { last4: "AbCd", savedAt: "2026-11-01T00:00:00Z", version: "1", canSave: true, models: ["claude-haiku-4-5-20251001"] },
    } });
    check("no key in the answer", holdsAKey(r), false);
  }
  {
    const store = fakeStore();
    store.permissions = ["secretmanager.versions.access"];
    store.failAccess.add("CLAUDE_API_KEY");
    const { deps, calls } = setup({ store, listModels: () => ({ refusal: "invalid_key" }) });
    const r = await settings.handleGetAiSettings(deps, "admin-1");
    check("without the permission to add versions: may not save", r.keys.gemini.canSave, false);
    check("a model list refused: the reason, no list", [r.keys.gemini.models, r.keys.gemini.modelsError], [undefined, "invalid_key"]);
    check("a key Secret Manager won't give: unreadable", r.keys.claude, { last4: "", savedAt: "", version: "", canSave: false, error: "unreadable" });
    check("and the log says why", calls.logs.some((l) => l.includes("claude: key not readable (403")), true);
  }

  // setAiApiKey
  {
    const { deps, store, calls } = setup({ modelConfig: { pvp_judge: "gemini-2.5-pro" } });
    check("setAiApiKey for a player", (await rejection(settings.handleSetAiApiKey(deps, "player-1", { provider: "gemini", key: GEMINI_KEY_2 }))).code,
      "permission-denied");
    check("an unknown company", await rejection(settings.handleSetAiApiKey(deps, "admin-1", { provider: "openai", key: GEMINI_KEY_2 })),
      { code: "invalid-argument", message: "invalid_provider", details: null });
    check("a malformed key", (await rejection(settings.handleSetAiApiKey(deps, "admin-1", { provider: "gemini", key: "AIza123" }))).message,
      "invalid_key_format");
    check("no key", (await rejection(settings.handleSetAiApiKey(deps, "admin-1", { provider: "claude" }))).message, "empty_key");
    check("nothing sent", (await rejection(settings.handleSetAiApiKey(deps, "admin-1", null))).message, "invalid_provider");
    check("nothing was tried or saved so far", [calls.tried.length, store.versions.GEMINI_API_KEY.length], [0, 1]);

    const same = await settings.handleSetAiApiKey(deps, "admin-1", { provider: "gemini", key: ` ${GEMINI_KEY} ` });
    check("the key already in use: nothing saved", [same, store.versions.GEMINI_API_KEY.length, calls.tried.length],
      [{ provider: "gemini", last4: "1234", savedAt: "2026-11-01T00:00:00Z", version: "1", unchanged: true }, 1, 0]);

    const r = await settings.handleSetAiApiKey(deps, "admin-1", { provider: "gemini", key: GEMINI_KEY_2 });
    check("a new key: tried with every Gemini model in use, then saved", calls.tried, [
      ["gemini", "new key", "gemini-2.5-flash"], ["gemini", "new key", "gemini-2.5-flash-lite"], ["gemini", "new key", "gemini-2.5-pro"],
    ]);
    check("the answer: last 4, when, which version", r,
      { provider: "gemini", last4: "5678", savedAt: "2026-11-27T10:00:00Z", version: "2", unchanged: false });
    check("saved as a new version holding exactly the key", store.versions.GEMINI_API_KEY.map((v) => v.value), [GEMINI_KEY, GEMINI_KEY_2]);
    check("this instance drops its cached key", calls.saved, ["gemini"]);
    check("no key in the answer or the logs", holdsAKey([r, calls.logs]), false);
    check("the log names the version and the admin", calls.logs, ["[aiSettings] gemini: new key saved as version 2 by admin-1"]);
  }
  {
    const { deps, store, calls } = setup({
      modelConfig: { war_history: "claude-opus-4-1" },
      tryModel: (_p, _k, m) => (m === "claude-opus-4-1" ? { ok: false, reason: "model_not_found", status: 404 } : { ok: true }),
    });
    const r = await rejection(settings.handleSetAiApiKey(deps, "admin-1", { provider: "claude", key: CLAUDE_KEY_2 }));
    check("a key that can't run one model in use: refused, with which and why", r, {
      code: "failed-precondition", message: "KEY_CHECK_FAILED:model_not_found",
      details: { reason: "model_not_found", model: "claude-opus-4-1", status: 404 },
    });
    check("and nothing saved", [store.versions.CLAUDE_API_KEY.length, calls.saved], [1, []]);
  }
  {
    const { deps, store } = setup({ tryModel: () => ({ ok: false, reason: "no_credit", status: 400 }) });
    check("a key without credit: refused", (await rejection(settings.handleSetAiApiKey(deps, "admin-1", { provider: "claude", key: CLAUDE_KEY_2 }))).message,
      "KEY_CHECK_FAILED:no_credit");
    check("nothing saved", store.versions.CLAUDE_API_KEY.length, 1);
  }
  {
    const store = fakeStore();
    store.failAdd = true;
    const { deps, calls } = setup({ store });
    check("Secret Manager refuses the new version", await rejection(settings.handleSetAiApiKey(deps, "admin-1", { provider: "gemini", key: GEMINI_KEY_2 })),
      { code: "internal", message: "KEY_SAVE_FAILED", details: null });
    check("the cached key is kept", calls.saved, []);
    check("no key in the logs", holdsAKey(calls.logs), false);
  }
  {
    const store = fakeStore();
    store.failAccess.add("GEMINI_API_KEY");
    const { deps } = setup({ store });
    const r = await settings.handleSetAiApiKey(deps, "admin-1", { provider: "gemini", key: GEMINI_KEY_2 });
    check("the current key unreadable: the new one is still checked and saved", [r.unchanged, r.version], [false, "2"]);
  }

  // checkAiModel
  {
    const { deps, calls } = setup({ tryModel: (_p, _k, m) => (m === "gemini-9" ? { ok: false, reason: "model_not_found", status: 404 } : { ok: true }) });
    check("checkAiModel for a player", (await rejection(settings.handleCheckAiModel(deps, "player-1", { provider: "gemini", model: "gemini-2.5-pro" }))).code,
      "permission-denied");
    check("an unknown company", (await rejection(settings.handleCheckAiModel(deps, "admin-1", { provider: "x", model: "m" }))).message, "invalid_provider");
    check("a bad name", (await rejection(settings.handleCheckAiModel(deps, "admin-1", { provider: "gemini", model: "a b" }))).message, "invalid_model");
    check("a model the key can run", await settings.handleCheckAiModel(deps, "admin-1", { provider: "gemini", model: "models/gemini-2.5-pro" }),
      { ok: true, model: "gemini-2.5-pro" });
    check("tried with the key in use", calls.tried[0], ["gemini", "current key", "gemini-2.5-pro"]);
    check("an unknown model", await settings.handleCheckAiModel(deps, "admin-1", { provider: "gemini", model: "gemini-9" }),
      { ok: false, model: "gemini-9", reason: "model_not_found" });
  }
  {
    const store = fakeStore();
    store.failAccess.add("CLAUDE_API_KEY");
    const { deps, calls } = setup({ store });
    check("the key unreadable: the check can't run", await settings.handleCheckAiModel(deps, "admin-1", { provider: "claude", model: "claude-haiku-4-5" }),
      { ok: false, model: "claude-haiku-4-5", reason: "key_unreadable" });
    check("nothing tried", calls.tried.length, 0);
  }
  check("the version id of a version name", [versionId("projects/604/secrets/GEMINI_API_KEY/versions/8"), versionId(undefined)], ["8", ""]);

  console.log("\nevery AI call reads its key through aiKey()\n");
  const src = path.join(__dirname, "..", "src");
  const direct = [];
  (function walk(dir) {
    for (const name of fs.readdirSync(dir)) {
      const p = path.join(dir, name);
      if (fs.statSync(p).isDirectory()) walk(p);
      else if (p.endsWith(".ts") && !p.endsWith(path.join("ai", "apiKey.ts")) &&
        /(GEMINI|CLAUDE)_API_KEY\.value\(\)/.test(fs.readFileSync(p, "utf8"))) direct.push(path.relative(src, p));
    }
  })(src);
  check("no other file reads a bound key directly", direct, []);

  console.log(fail === 0 ? "\nAll checks passed.\n" : `\n${fail} check(s) failed.\n`);
  process.exit(fail === 0 ? 0 : 1);
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
