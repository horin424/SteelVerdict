// PC admin page: sign-in, admin check, live config, routing.
//
// Same five sections as the in-app panel (lib/features/admin), reading and
// writing the same document, system_config/game_config. The config is watched
// live, so counts and lists follow changes made from the app or another
// browser while the page is open. A sixth page, web only, lists the players'
// reports of AI output (content_reports).
import {
  FieldPath,
  deleteField,
  doc,
  forgetConfig,
  getCountFromServer,
  initFirebase,
  limit,
  onAuthStateChanged,
  onSnapshot,
  orderBy,
  query,
  resolveConfig,
  saveConfig,
  setDoc,
  signInWithEmailAndPassword,
  signOut,
  updateDoc,
  where,
} from "./firebase.js";
import { parseConfig } from "./model.js";
import { getLang, setLang, t } from "./i18n.js";
import { errorText, h } from "./ui.js";
import { icon } from "./icons.js";
import { changePassword, sendReset, signInError } from "./account.js";
import { confirmDiscard } from "./editorkit.js";
import { mountWorldviews } from "./editors/worldviews.js";
import { mountScenarios } from "./editors/scenarios.js";
import { mountModeAddons } from "./editors/modeAddons.js";
import { mountCosts } from "./editors/costs.js";
import { mountSystemConfig } from "./editors/systemConfig.js";
import { mountReports } from "./editors/reports.js";

const ROUTES = {
  worldviews: { mount: mountWorldviews, title: "adminWorldviews" },
  scenarios: { mount: mountScenarios, title: "adminScenarios" },
  "mode-addons": { mount: mountModeAddons, title: "adminModeAddons" },
  costs: { mount: mountCosts, title: "adminCosts" },
  system: { mount: mountSystemConfig, title: "adminSystemConfig" },
  reports: { mount: mountReports, title: "adminReports" },
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

/// Forgets the open page. A page that listens to Firestore itself (the reports
/// list) stops listening here.
function closeEditor() {
  if (state.editor && state.editor.dispose) state.editor.dispose();
  state.editor = null;
}

// ── Top bar ──────────────────────────────────────────────────────────────────

function renderTopbar() {
  document.title = `Steel Verdict · ${t("pageTitle")}`;
  const tool = (iconName, label, onClick, attrs = {}) =>
    h("button", { class: "ghost small tool", type: "button", onClick, ...attrs }, icon(iconName), h("span", {}, label));
  // replaceChildren would print a null as the text "null".
  document.getElementById("topbar").replaceChildren(
    ...[
      h(
        "a",
        { class: "brand", href: "#/" },
        icon("shield", "brand-mark"),
        h("span", { class: "brand-name", lang: "en" }, "Steel Verdict"),
        h("span", { class: "brand-sub" }, t("pageTitle")),
      ),
      h("span", { class: "spacer" }),
      state.user ? h("span", { class: "user" }, state.user.email || state.user.uid) : null,
      state.user && state.user.email ? tool("key", t("accountPassword"), () => changePassword(state.fb.auth)) : null,
      tool("translate", t("language"), toggleLang, { lang: getLang() === "ja" ? "en" : "ja" }),
      state.user ? tool("logout", t("signOut"), doSignOut) : null,
    ].filter(Boolean),
  );
}

async function toggleLang() {
  // Re-rendering rebuilds the open form, so ask before losing edits.
  if (editorDirty() && !(await confirmDiscard())) return;
  setLang(getLang() === "ja" ? "en" : "ja");
  renderTopbar();
  if (!state.fb) renderSetup();
  else if (!state.user) renderSignIn();
  else {
    // Through refresh(), so loading, error and not-an-admin screens are
    // redrawn as themselves, not replaced by the panel.
    closeEditor();
    refresh();
  }
}

async function doSignOut() {
  if (editorDirty() && !(await confirmDiscard())) return;
  closeEditor();
  await signOut(state.fb.auth);
}

// ── Views before the panel ───────────────────────────────────────────────────

function renderMessage(text, isError = false) {
  app.replaceChildren(h("div", { class: `card narrow${isError ? " error" : ""}` }, h("p", {}, text)));
}

/// Frame of the screens before sign-in, after the app's own sign-in screen:
/// the emblem, the game's name, then the form.
function authShell(content) {
  return h(
    "div",
    { class: "auth" },
    h(
      "div",
      { class: "auth-head" },
      h("span", { class: "emblem" }, icon("shield")),
      h("p", { class: "auth-name", lang: "en" }, "Steel Verdict"),
      h("p", { class: "auth-sub" }, t("pageTitle")),
    ),
    content,
  );
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
    authShell(
      h(
        "div",
        { class: "card auth-card" },
        h("p", { class: "muted" }, t("setupHelp")),
        h("label", { class: "field" }, h("span", { class: "field-label" }, t("setupLabel")), area),
        error,
        h("button", { class: "wide", type: "button", onClick: go }, t("setupSave")),
      ),
    ),
  );
}

function renderSignIn() {
  const email = h("input", { type: "email", autocomplete: "username", spellcheck: "false" });
  const password = h("input", { type: "password", autocomplete: "current-password" });
  const error = h("p", { class: "field-error", role: "alert" });
  const status = h("p", { class: "form-status", role: "status" });
  const submit = h("button", { class: "wide", type: "submit" }, t("signIn"));
  const clear = () => {
    error.textContent = "";
    status.textContent = "";
  };
  const forgot = h(
    "button",
    {
      class: "link",
      type: "button",
      onClick: async () => {
        clear();
        const address = email.value.trim();
        if (!address) {
          error.textContent = t("resetNeedEmail");
          email.focus();
          return;
        }
        forgot.disabled = true;
        const result = await sendReset(state.fb.auth, address);
        forgot.disabled = false;
        if (result.ok) status.textContent = result.ok;
        else error.textContent = result.error;
      },
    },
    t("forgotPassword"),
  );
  const form = h(
    "form",
    {
      class: "card auth-card",
      novalidate: true,
      onSubmit: async (e) => {
        e.preventDefault();
        clear();
        if (!email.value.trim() || !password.value) {
          error.textContent = t("signInEmpty");
          (email.value.trim() ? password : email).focus();
          return;
        }
        submit.disabled = true;
        try {
          await signInWithEmailAndPassword(state.fb.auth, email.value.trim(), password.value);
        } catch (err) {
          error.textContent = signInError(err);
        } finally {
          submit.disabled = false;
        }
      },
    },
    h("h1", {}, t("signInTitle")),
    h("label", { class: "field" }, h("span", { class: "field-label" }, t("email")), email),
    h("label", { class: "field" }, h("span", { class: "field-label" }, t("password")), password),
    error,
    status,
    submit,
    h(
      "div",
      { class: "auth-links" },
      forgot,
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
    ),
  );
  app.replaceChildren(authShell(form));
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
    aiDailyLimit: "problemAiDailyLimit",
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
  // Same counts, icons and icon colours as the app's panel
  // (admin_panel_screen.dart).
  const cards = [
    ["worldviews", "public", "blue", "adminWorldviews", "adminWorldviewsDesc", Object.keys(p.worldviews).length],
    ["scenarios", "militaryTech", "orange", "adminScenarios", "adminScenariosDesc", Object.keys(p.scenarios).length],
    ["mode-addons", "tune", "purple", "adminModeAddons", "adminModeAddonsDesc", Object.keys(p.modeAddons).length],
    [
      "costs",
      "confirmationNumber",
      "gold",
      "adminCosts",
      "adminCostsDesc",
      Object.keys(p.ticketCosts).length + Object.keys(p.modelConfig).length,
    ],
    ["system", "settings", "steel", "adminSystemConfig", "adminSystemConfigDesc", p.devUids.length],
    // Web only (the app has no reports screen): the open reports.
    ["reports", "report", "red", "adminReports", "adminReportsDesc", openReportsCount()],
  ];
  return h(
    "div",
    {},
    h("h1", { class: "page-title" }, t("adminPanel")),
    problemsBanner(),
    h(
      "div",
      { class: "hub" },
      cards.map(([route, iconName, tone, title, desc, count]) =>
        h(
          "a",
          { class: "hub-card", href: `#/${route}` },
          h("span", { class: `hub-icon tone-${tone}` }, icon(iconName)),
          h("span", { class: "hub-text" }, h("strong", {}, t(title)), h("span", {}, t(desc))),
          count instanceof Node ? count : h("span", { class: "count" }, String(count)),
          icon("chevronRight", "chevron"),
        ),
      ),
    ),
  );
}

/// The number of open reports, filled in when the server answers. A count
/// query reads no report text. Only admin_uids may read reports; others see "–".
function openReportsCount() {
  const el = h("span", { class: "count", title: t("reportsOpenCount") }, state.canWrite ? "…" : "–");
  if (state.canWrite) {
    getCountFromServer(query(state.fb.reportsRef, where("status", "==", "new")))
      .then((snap) => {
        const n = snap.data().count;
        el.textContent = String(n);
        el.classList.toggle("attention", n > 0);
      })
      .catch(() => {
        el.textContent = "–";
      });
  }
  return el;
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
    // Reports page: up to `count` open reports (status "new", fetched in id
    // order, which needs no extra index), or the newest `count` of all. Shown
    // newest first either way.
    watchReports: ({ open, count }, onData, onError) =>
      onSnapshot(
        open
          ? query(state.fb.reportsRef, where("status", "==", "new"), limit(count))
          : query(state.fb.reportsRef, orderBy("createdAt", "desc"), limit(count)),
        (snap) =>
          onData(
            snap.docs
              .map((d) => ({ ...d.data(), id: d.id }))
              .sort((a, b) => (Number(b.createdAt) || 0) - (Number(a.createdAt) || 0)),
            snap.metadata.fromCache,
          ),
        onError,
      ),
    updateReport: (id, change) => updateDoc(doc(state.fb.reportsRef, id), change),
    // Costs & models page: the count of AI calls on one Japan day ("YYYY-MM-DD"),
    // null when there is none yet. Only admin_uids may read it.
    watchAiUsage: (day, onData, onError) =>
      onSnapshot(
        doc(state.fb.aiUsageRef, day),
        (snap) => onData(snap.exists() ? snap.data() : null, snap.metadata.fromCache),
        onError,
      ),
    // Costs & models page: the API keys and the model checks (functions/src/ai).
    callFunction: (name, data) => state.fb.call(name, data),
  };
}

function renderRoute() {
  const name = routeName();
  const route = ROUTES[name];
  closeEditor();
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
      h(
        "div",
        { class: "crumbs" },
        h("a", { class: "back", href: "#/" }, icon("chevronLeft"), t("back")),
        h("h1", { class: "page-title" }, t(route.title)),
      ),
      body,
    ].filter(Boolean),
  );
  state.editor = route.mount(body, editorContext());
}

/// Called on every config / admin-list snapshot and on navigation.
function refresh() {
  if (!state.user) return;
  if (state.configError) {
    closeEditor();
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
    closeEditor();
    renderMessage(t("configMissing"), true);
    return;
  }
  const uid = state.user.uid;
  // The app shows its panel to dev_uids; the rules let admin_uids write.
  if (!state.parsed.devUids.includes(uid) && !state.adminUids.includes(uid)) {
    closeEditor();
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
  // Offline, Firestore answers "no document" from its empty local cache. That
  // would read as a deleted config or a missing admin right, so both listeners
  // wait for the server's answer instead.
  const fromEmptyCache = (snap) => !snap.exists() && snap.metadata.fromCache;
  state.unsubs.push(
    onSnapshot(
      state.fb.configRef,
      (snap) => {
        if (fromEmptyCache(snap)) return;
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
        if (fromEmptyCache(snap)) return;
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
    closeEditor();
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
  closeEditor();
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
