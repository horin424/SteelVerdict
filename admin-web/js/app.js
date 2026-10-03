// PC admin page: sign-in, admin check, live config, routing.
//
// Same five sections as the in-app panel (lib/features/admin), reading and
// writing the same document, system_config/game_config. The config is watched
// live, so counts and lists follow changes made from the app or another
// browser while the page is open.
import {
  LIVE_PROJECT_ID,
  FieldPath,
  deleteField,
  forgetConfig,
  initFirebase,
  onAuthStateChanged,
  onSnapshot,
  resolveConfig,
  saveConfig,
  setDoc,
  signInWithEmailAndPassword,
  signOut,
  updateDoc,
} from "./firebase.js";
import { parseConfig } from "./model.js";
import { getLang, setLang, t } from "./i18n.js";
import { errorText, h } from "./ui.js";
import { confirmDiscard } from "./editorkit.js";
import { mountWorldviews } from "./editors/worldviews.js";
import { mountScenarios } from "./editors/scenarios.js";
import { mountModeAddons } from "./editors/modeAddons.js";
import { mountCosts } from "./editors/costs.js";
import { mountSystemConfig } from "./editors/systemConfig.js";

const ROUTES = {
  worldviews: { mount: mountWorldviews, title: "adminWorldviews" },
  scenarios: { mount: mountScenarios, title: "adminScenarios" },
  "mode-addons": { mount: mountModeAddons, title: "adminModeAddons" },
  costs: { mount: mountCosts, title: "adminCosts" },
  system: { mount: mountSystemConfig, title: "adminSystemConfig" },
};

const app = document.getElementById("app");
const state = {
  fb: null,
  configSource: null,
  user: null,
  raw: null,
  parsed: null,
  configLoaded: false,
  configError: null,
  adminUids: null,
  canWrite: false,
  unsubs: [],
  editor: null,
  routeName: null,
};

const routeName = () => location.hash.replace(/^#\/?/, "");
const editorDirty = () => Boolean(state.editor && state.editor.isDirty());

// ── Top bar ──────────────────────────────────────────────────────────────────

function renderTopbar() {
  document.title = `Steel Verdict · ${t("pageTitle")}`;
  const env = state.fb
    ? state.fb.projectId === LIVE_PROJECT_ID
      ? h("span", { class: "env live" }, `${t("envLive")} · ${state.fb.projectId}`)
      : h("span", { class: "env test" }, `${t("envTest")} · ${state.fb.projectId}`)
    : null;
  // replaceChildren would print a null as the text "null".
  document.getElementById("topbar").replaceChildren(
    ...[
      h("a", { class: "brand", href: "#/" }, "Steel Verdict", h("span", {}, t("pageTitle"))),
      env,
      h("span", { class: "spacer" }),
      state.user ? h("span", { class: "user" }, state.user.email || state.user.uid) : null,
      h("button", { class: "ghost small", type: "button", lang: getLang() === "ja" ? "en" : "ja", onClick: toggleLang }, t("language")),
      state.user ? h("button", { class: "ghost small", type: "button", onClick: doSignOut }, t("signOut")) : null,
    ].filter(Boolean),
  );
}

async function toggleLang() {
  // Re-rendering rebuilds the open form, so ask before losing edits.
  if (editorDirty() && !(await confirmDiscard())) return;
  setLang(getLang() === "ja" ? "en" : "ja");
  renderTopbar();
  if (state.user && state.parsed) renderRoute();
  else if (state.fb && !state.user) renderSignIn();
  else if (!state.fb) renderSetup();
}

async function doSignOut() {
  if (editorDirty() && !(await confirmDiscard())) return;
  state.editor = null;
  await signOut(state.fb.auth);
}

// ── Views before the panel ───────────────────────────────────────────────────

function renderMessage(text, isError = false) {
  app.replaceChildren(h("div", { class: `card narrow${isError ? " error" : ""}` }, h("p", {}, text)));
}

function renderSetup() {
  const area = h("textarea", {
    rows: 6,
    class: "mono",
    spellcheck: "false",
    placeholder: '{"apiKey":"...","authDomain":"...","projectId":"...","appId":"..."}',
  });
  const error = h("p", { class: "field-error", role: "alert" });
  const go = () => {
    try {
      const config = JSON.parse(area.value);
      if (!config.apiKey || !config.projectId) throw new Error("apiKey / projectId");
      saveConfig(config);
      start(config, "saved");
    } catch (e) {
      error.textContent = t("setupInvalid", { error: e.message });
    }
  };
  app.replaceChildren(
    h(
      "div",
      { class: "card narrow" },
      h("h1", {}, t("pageTitle")),
      h("p", { class: "muted" }, t("setupHelp")),
      h("label", { class: "field" }, h("span", { class: "field-label" }, t("setupLabel")), area),
      error,
      h("button", { type: "button", onClick: go }, t("setupSave")),
    ),
  );
}

function renderSignIn() {
  const email = h("input", { type: "email", autocomplete: "username", required: true });
  const password = h("input", { type: "password", autocomplete: "current-password", required: true });
  const error = h("p", { class: "field-error", role: "alert" });
  const submit = h("button", { type: "submit" }, t("signIn"));
  const form = h(
    "form",
    {
      class: "card narrow",
      onSubmit: async (e) => {
        e.preventDefault();
        error.textContent = "";
        submit.disabled = true;
        try {
          await signInWithEmailAndPassword(state.fb.auth, email.value.trim(), password.value);
        } catch (err) {
          error.textContent = t("signInFailed", { error: errorText(err) });
        } finally {
          submit.disabled = false;
        }
      },
    },
    h("h1", {}, t("signInTitle")),
    h("label", { class: "field" }, h("span", { class: "field-label" }, t("email")), email),
    h("label", { class: "field" }, h("span", { class: "field-label" }, t("password")), password),
    submit,
    error,
    state.configSource === "saved"
      ? h(
          "button",
          {
            class: "link",
            type: "button",
            onClick: () => {
              forgetConfig();
              location.reload();
            },
          },
          t("setupForget"),
        )
      : null,
  );
  app.replaceChildren(form);
  email.focus();
}

function renderDenied() {
  app.replaceChildren(
    h(
      "div",
      { class: "card narrow error" },
      h("p", {}, t("notAdmin", { email: state.user.email || state.user.uid })),
      h("button", { type: "button", onClick: doSignOut }, t("signOut")),
    ),
  );
}

// ── The panel ────────────────────────────────────────────────────────────────

function problemsBanner() {
  const problems = state.parsed.problems;
  if (!problems.length) return null;
  const text = {
    worldview: "problemWorldview",
    scenario: "problemScenario",
    ticketCost: "problemTicketCost",
    fallbackPrompt: "problemFallbackPrompt",
    adUnit: "problemAdUnit",
  };
  return h(
    "div",
    { class: "banner error" },
    h("strong", {}, t("problemsTitle")),
    h("ul", {}, problems.map((p) => h("li", {}, t(text[p.kind], { key: p.key ?? "" })))),
  );
}

function renderHub() {
  const p = state.parsed;
  // Same counts as the app's panel.
  const cards = [
    ["worldviews", "adminWorldviews", "adminWorldviewsDesc", Object.keys(p.worldviews).length],
    ["scenarios", "adminScenarios", "adminScenariosDesc", Object.keys(p.scenarios).length],
    ["mode-addons", "adminModeAddons", "adminModeAddonsDesc", Object.keys(p.modeAddons).length],
    ["costs", "adminCosts", "adminCostsDesc", Object.keys(p.ticketCosts).length + Object.keys(p.modelConfig).length],
    ["system", "adminSystemConfig", "adminSystemConfigDesc", p.devUids.length],
  ];
  return h(
    "div",
    {},
    h("h1", { class: "page-title" }, t("adminPanel")),
    problemsBanner(),
    h(
      "div",
      { class: "hub" },
      cards.map(([route, title, desc, count]) =>
        h(
          "a",
          { class: "hub-card", href: `#/${route}` },
          h("span", { class: "hub-text" }, h("strong", {}, t(title)), h("span", {}, t(desc))),
          h("span", { class: "count" }, String(count)),
        ),
      ),
    ),
  );
}

function editorContext() {
  return {
    raw: () => state.raw,
    parsed: () => state.parsed,
    lang: getLang,
    canWrite: () => state.canWrite,
    uid: state.user.uid,
    merge: (payload) => setDoc(state.fb.configRef, payload, { merge: true }),
    // FieldPath, not "worldviews.<key>": a key containing a dot would
    // otherwise be read as a nested path.
    deleteKey: (section, key) => updateDoc(state.fb.configRef, new FieldPath(section, key), deleteField()),
    deleteField,
  };
}

function renderRoute() {
  const name = routeName();
  const route = ROUTES[name];
  state.editor = null;
  state.routeName = name;
  const readOnly = state.canWrite ? null : h("div", { class: "banner error" }, t("readOnly"));
  if (!route) {
    app.replaceChildren(...[readOnly, renderHub()].filter(Boolean));
    return;
  }
  const body = h("div", { class: "editor-body" });
  app.replaceChildren(
    ...[
      readOnly,
      h("div", { class: "crumbs" }, h("a", { href: "#/" }, `← ${t("back")}`), h("h1", { class: "page-title" }, t(route.title))),
      body,
    ].filter(Boolean),
  );
  state.editor = route.mount(body, editorContext());
}

/// Called on every config / admin-list snapshot and on navigation.
function refresh() {
  if (!state.user) return;
  if (state.configError) {
    state.editor = null;
    renderMessage(t("configLoadFailed", { error: errorText(state.configError) }), true);
    return;
  }
  // Nothing is drawn from defaults: an editor filled before the real config
  // arrives is how the app's system-config screen can save an empty admin list.
  if (!state.configLoaded || state.adminUids === null) {
    renderMessage(t("loading"));
    return;
  }
  if (!state.raw) {
    state.editor = null;
    renderMessage(t("configMissing"), true);
    return;
  }
  const uid = state.user.uid;
  // The app shows its panel to dev_uids; the rules let admin_uids write.
  if (!state.parsed.devUids.includes(uid) && !state.adminUids.includes(uid)) {
    state.editor = null;
    renderDenied();
    return;
  }
  const canWrite = state.adminUids.includes(uid);
  const canWriteChanged = canWrite !== state.canWrite;
  state.canWrite = canWrite;
  if (state.editor && state.routeName === routeName() && !(canWriteChanged && !editorDirty())) {
    state.editor.onConfig();
    return;
  }
  renderRoute();
}

function stopListening() {
  for (const unsub of state.unsubs) unsub();
  state.unsubs = [];
}

function listen() {
  state.configLoaded = false;
  state.configError = null;
  state.adminUids = null;
  state.unsubs.push(
    onSnapshot(
      state.fb.configRef,
      (snap) => {
        state.configLoaded = true;
        state.raw = snap.exists() ? snap.data() : null;
        state.parsed = state.raw ? parseConfig(state.raw) : null;
        refresh();
      },
      (err) => {
        state.configError = err;
        refresh();
      },
    ),
    onSnapshot(
      state.fb.adminUidsRef,
      (snap) => {
        const uids = snap.exists() ? snap.data().uids : null;
        state.adminUids = Array.isArray(uids) ? uids.map(String) : [];
        refresh();
      },
      () => {
        state.adminUids = [];
        refresh();
      },
    ),
  );
}

function start(config, source) {
  state.fb = initFirebase(config);
  state.configSource = source;
  renderTopbar();
  renderMessage(t("loading"));
  onAuthStateChanged(state.fb.auth, (user) => {
    stopListening();
    state.user = user;
    state.editor = null;
    state.raw = null;
    state.parsed = null;
    renderTopbar();
    if (!user) {
      renderSignIn();
      return;
    }
    renderMessage(t("loading"));
    listen();
  });
}

// ── Navigation guards ────────────────────────────────────────────────────────

let lastHash = location.hash;
let restoringHash = false;
window.addEventListener("hashchange", async () => {
  if (restoringHash) {
    restoringHash = false;
    return;
  }
  if (editorDirty() && !(await confirmDiscard())) {
    restoringHash = true;
    location.hash = lastHash;
    return;
  }
  lastHash = location.hash;
  state.editor = null;
  refresh();
});

window.addEventListener("beforeunload", (e) => {
  if (editorDirty()) {
    e.preventDefault();
    e.returnValue = "";
  }
});

// Local development only: lets a test read what the page holds.
if (["localhost", "127.0.0.1"].includes(location.hostname)) {
  window.svAdminDebug = { raw: () => state.raw, parsed: () => state.parsed, projectId: () => state.fb?.projectId };
}

setLang(getLang());
renderTopbar();
const resolved = await resolveConfig();
if (resolved) start(resolved.config, resolved.source);
else renderSetup();
