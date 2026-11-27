// Costs & models: port of lib/features/admin/screens/admin_costs_editor.dart.
//
// Same rows as the app (every ticket cost and every model the config holds)
// and the same merge write of ticket_costs and model_config. Differences,
// deliberate:
// - A cost that is not a whole number of 0 or more is refused. The app saved it
//   as 0, which made that mode free (client review).
// - An emptied model is removed, so the server falls back to its default model.
//   The app skipped empty fields, so a model could never be cleared.
// - A stored cost that is not a number is shown so it can be fixed. The app's
//   parser fails on it and falls back to defaults for the whole game.
//
// Web only: the daily AI limits (functions/src/limits), saved in the same merge
// write as ai_daily_limits, and today's count of AI calls (ai_usage), which only
// admin_uids may read. A limit the admin leaves alone is not written, so one
// that was never stored keeps the server's default.
//
// Web only, 27 Nov 2026 (client point ②), through the admin callables in
// functions/src/ai:
// - 「APIキー」: the AI companies' keys. A key is saved on its own, not with the
//   page's 保存: the server tries it for real, stores it as a new Secret
//   Manager version, and the AI uses it within a minute. Only its last 4
//   characters are ever shown.
// - Every model the server reads is listed (戦史 and the PvP judge too), with
//   the models the key can use as suggestions. A changed model name is tried
//   with the key in use before the page saves it.
import { h, toast, parseWholeNumber, errorText, confirmDialog } from "../ui.js";
import { t } from "../i18n.js";
import { AI_LIMIT_KEYS, modeName, normalizeText } from "../model.js";
import {
  FormTracker,
  SaveMerger,
  StaleWatch,
  guardedSave,
  saveButton,
  staleBanner,
  stableStringify,
} from "../editorkit.js";

const LIMIT_LABELS = {
  freePerUser: "aiLimitFreePerUser",
  allPerUser: "aiLimitAllPerUser",
  appTotal: "aiLimitAppTotal",
};

// The game's day is the date in Japan (UTC+9, no daylight saving), as on the
// server (functions/src/utils/japanDay.ts).
const JAPAN_OFFSET_MS = 9 * 60 * 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;
const japanDay = (ms = Date.now()) => new Date(ms + JAPAN_OFFSET_MS).toISOString().substring(0, 10);
const msToNextJapanDay = (ms = Date.now()) => DAY_MS - ((ms + JAPAN_OFFSET_MS) % DAY_MS);

const storedLimitsOf = (raw) => {
  const v = raw.ai_daily_limits;
  return v !== null && typeof v === "object" && !Array.isArray(v) ? v : {};
};

// Display order: modes as a player meets them, then extras, then anything else.
const COST_ORDER = [
  "practice",
  "normal",
  "normal_gemini",
  "normal_claude",
  "tabletop",
  "epic",
  "boss",
  "history_puzzle",
  "pvp",
  "pvp_detail",
  "war_history",
  "claude",
  "gemini",
];

// The model keys the server reads (functions/src/ai/models.ts): what each one
// is used for, the company whose key it runs on, and the model used while none
// is set. Always listed, so a model that was cleared can be set again; the app
// only lists keys already stored.
const MODELS = {
  claude: { label: "modelUseClaude", provider: "claude", fallback: "claude-haiku-4-5-20251001" },
  war_history: { label: "modelUseWarHistory", provider: "claude", fallback: "claude-haiku-4-5-20251001" },
  gemini_flash: { label: "modelUseGeminiFlash", provider: "gemini", fallback: "gemini-2.5-flash" },
  gemini_flash_lite: { label: "modelUseGeminiFlashLite", provider: "gemini", fallback: "gemini-2.5-flash-lite" },
  pvp_judge: { label: "modelUsePvpJudge", provider: "gemini", fallback: "gemini-2.5-flash" },
};
const modelLabel = (k) => (MODELS[k] ? t(MODELS[k].label) : modeName(k, t));

// The API keys, checked as the server checks them (functions/src/ai/keys.ts).
const PROVIDERS = {
  gemini: {
    name: "apiKeyGemini",
    use: "apiKeyGeminiUse",
    company: "Google",
    pattern: /^AIza[0-9A-Za-z_-]{35}$/,
    format: "apiKeyFormatGemini",
  },
  claude: {
    name: "apiKeyClaude",
    use: "apiKeyClaudeUse",
    company: "Anthropic",
    pattern: /^sk-ant-[0-9A-Za-z_-]{20,300}$/,
    format: "apiKeyFormatClaude",
  },
};

/// Why a key or a model was refused, as the server reports it (functions/src/ai/providers.ts).
function checkReason(reason, provider, model) {
  const name = PROVIDERS[provider]?.company ?? provider;
  switch (reason) {
    case "invalid_key":
      return t("aiCheckInvalidKey", { name });
    case "no_credit":
      return t("aiCheckNoCredit");
    case "model_not_found":
      return t("aiCheckModelNotFound", { model });
    case "rate_limited":
      return t("aiCheckRateLimited");
    case "network":
      return t("aiCheckNetwork", { name });
    case "key_unreadable":
      return t("aiCheckKeyUnreadable");
    default:
      return t("aiCheckProviderError", { name });
  }
}

/// What a refused setAiApiKey call means (functions/src/ai/aiSettings.ts).
function keyErrorText(e, provider) {
  const message = String(e?.message ?? "");
  if (message.startsWith("KEY_CHECK_FAILED:")) {
    const reason = e.details?.reason ?? message.slice("KEY_CHECK_FAILED:".length);
    return checkReason(reason, provider, e.details?.model ?? "");
  }
  if (message === "invalid_key_format") return t(PROVIDERS[provider].format);
  if (message === "empty_key") return t("apiKeyEmpty");
  if (message === "KEY_SAVE_FAILED") return t("apiKeySaveFailed");
  if (message === "NOT_ADMIN") return t("readOnly");
  return errorText(e);
}

function ordered(keys) {
  return [...COST_ORDER.filter((k) => keys.includes(k)), ...keys.filter((k) => !COST_ORDER.includes(k)).sort()];
}

export function mountCosts(root, ctx) {
  let loadedCosts = null;
  let loadedModels = null;
  let costInputs = {};
  let modelInputs = {};
  let loadedLimits = null;
  let loadedStoredLimits = null;
  let limitInputs = {};
  let saving = false;
  let disposed = false;
  // Today's count of AI calls: undefined until it arrives.
  let usage;
  let usageError = null;
  let usageEl = null;
  let unsubUsage = null;
  let dayTimer = null;
  // The API keys: undefined while loading, null for a non-admin, else
  // getAiSettings' answer or { error }.
  let keyState = null;
  let keysAsAdmin = null;
  let keysRequest = 0;
  // Kept across form reloads, so a key being typed survives a save of the form.
  const keysEl = h("div", { class: "key-list" });
  const suggestions = {
    gemini: h("datalist", { id: "sv-models-gemini" }),
    claude: h("datalist", { id: "sv-models-claude" }),
  };
  const form = new FormTracker();
  const stale = new StaleWatch(() => {
    const r = ctx.raw();
    return [
      r.ticketCosts ?? null,
      r.ticket_costs ?? null,
      r.modelConfig ?? null,
      r.model_config ?? null,
      r.ai_daily_limits ?? null,
    ];
  });
  const body = h("section", { class: "single" });
  root.append(body);

  const ja = () => ctx.lang() === "ja";
  const paren = (s) => (ja() ? `（${s}）` : ` (${s})`);

  function load() {
    form.reset();
    const p = ctx.parsed();
    // Invalid stored costs keep their raw value, so they compare as stored.
    loadedCosts = { ...p.ticketCosts, ...p.invalidTicketCosts };
    loadedModels = {
      ...Object.fromEntries(Object.keys(MODELS).map((k) => [k, ""])),
      ...p.modelConfig,
    };

    costInputs = {};
    const costRows = ordered(Object.keys(loadedCosts)).map((k) => {
      const invalid = Object.prototype.hasOwnProperty.call(p.invalidTicketCosts, k);
      const input = h("input", {
        type: "text",
        inputmode: "numeric",
        class: `num${invalid ? " invalid" : ""}`,
        value: String(loadedCosts[k]),
      });
      costInputs[k] = input;
      form.input(input);
      return h("label", { class: "stat-row" }, h("span", {}, modeName(k, t)), h("code", {}, k), input);
    });

    modelInputs = {};
    const modelKeys = [
      ...Object.keys(MODELS),
      ...Object.keys(loadedModels)
        .filter((k) => !MODELS[k])
        .sort(),
    ];
    const modelRows = modelKeys.map((k) => {
      const input = h("input", {
        type: "text",
        class: "mono",
        spellcheck: "false",
        autocomplete: "off",
        placeholder: MODELS[k]?.fallback ?? "",
        list: MODELS[k] ? suggestions[MODELS[k].provider].id : null,
        value: loadedModels[k],
      });
      modelInputs[k] = input;
      form.input(input);
      return h("label", { class: "model-row" }, h("span", {}, modelLabel(k)), h("code", {}, k), input);
    });

    // A stored limit the server ignores keeps its raw value, so it shows to be fixed.
    loadedLimits = { ...p.aiDailyLimits, ...p.invalidAiDailyLimits };
    loadedStoredLimits = { ...storedLimitsOf(ctx.raw()) };
    limitInputs = {};
    const limitRows = Object.entries(AI_LIMIT_KEYS).map(([field, key]) => {
      const invalid = Object.prototype.hasOwnProperty.call(p.invalidAiDailyLimits, field);
      const input = h("input", {
        type: "text",
        inputmode: "numeric",
        class: `num${invalid ? " invalid" : ""}`,
        value: String(loadedLimits[field]),
      });
      limitInputs[field] = input;
      form.input(input);
      return h("label", { class: "stat-row" }, h("span", {}, t(LIMIT_LABELS[field])), h("code", {}, key), input);
    });
    usageEl = h("p", { class: "field-hint ai-usage" });
    renderUsage();

    stale.capture();
    const save = saveButton(ctx, () => onSave(save));
    body.replaceChildren(
      h("h3", { class: "section-label" }, t("adminApiKeysSection")),
      h("p", { class: "field-hint" }, t("apiKeysHint")),
      keysEl,
      h("h3", { class: "section-label" }, t("adminTicketCostsSection")),
      h("div", { class: "stat-grid" }, costRows),
      h("h3", { class: "section-label" }, t("adminAiLimitsSection")),
      h("p", { class: "field-hint" }, t("aiLimitsHint")),
      h("div", { class: "stat-grid" }, limitRows),
      usageEl,
      h("h3", { class: "section-label" }, t("adminAiModelsSection")),
      h("p", { class: "field-hint" }, t("modelEmptyHint"), " ", t("modelCheckHint")),
      h("div", { class: "model-list" }, modelRows),
      suggestions.gemini,
      suggestions.claude,
      h("div", { class: "save-bar" }, save),
    );
  }

  async function onSave(button) {
    if (ctx.canWrite() && !(await checkModels(button))) return;
    saving = true;
    const ok = await guardedSave({
      ctx,
      button,
      build: () => {
        const p = ctx.parsed();
        const m = new SaveMerger();
        const costs = {};
        for (const [k, input] of Object.entries(costInputs)) {
          const n = parseWholeNumber(input.value, modeName(k, t), { min: 0 });
          if (n.error) {
            toast(n.error, "error");
            input.focus();
            return null;
          }
          // A stored non-number compares as changed, so it is always replaced.
          costs[k] = m.value(n.value, loadedCosts[k], p.ticketCosts[k] ?? p.invalidTicketCosts[k]);
        }
        // Daily AI limits. Left alone: written as stored now, so another
        // admin's change survives, or not at all when never stored, so the
        // server keeps its default. Changed: written, after asking if it was
        // also changed elsewhere since the page loaded.
        const storedLimits = storedLimitsOf(ctx.raw());
        const limits = {};
        for (const [field, input] of Object.entries(limitInputs)) {
          const n = parseWholeNumber(input.value, t(LIMIT_LABELS[field]), { min: 0 });
          if (n.error) {
            toast(n.error, "error");
            input.focus();
            return null;
          }
          const key = AI_LIMIT_KEYS[field];
          if (n.value === loadedLimits[field]) {
            if (storedLimits[key] !== undefined) limits[key] = storedLimits[key];
            continue;
          }
          if (stableStringify(storedLimits[key]) !== stableStringify(loadedStoredLimits[key])) m.conflict = true;
          limits[key] = n.value;
        }
        const storedModels = ctx.raw().model_config ?? {};
        const models = {};
        for (const [k, input] of Object.entries(modelInputs)) {
          const value = m.text(input.value, loadedModels[k] ?? "", p.modelConfig[k] ?? "", { trim: true });
          if (value) models[k] = value;
          // Emptied by the admin: remove it. Stored empty already: leave it.
          else if (storedModels[k]) models[k] = ctx.deleteField();
        }
        const payload = { ticket_costs: costs, model_config: models };
        if (Object.keys(limits).length) payload.ai_daily_limits = limits;
        return { merger: m, payload };
      },
    });
    saving = false;
    if (ok) load();
  }

  // Each changed model name is tried with the key in use (checkAiModel) before
  // the save. A name the company refuses is not saved; a check that can't run
  // (no answer, no credit, …) is the admin's call.
  async function checkModels(button) {
    const changed = Object.entries(modelInputs).filter(([k, input]) => {
      const typed = input.value.trim();
      return MODELS[k] && typed !== "" && normalizeText(typed) !== normalizeText(loadedModels[k] ?? "");
    });
    if (!changed.length) return true;
    const label = button.textContent;
    button.disabled = true;
    button.textContent = t("modelChecking");
    const unchecked = [];
    try {
      for (const [k, input] of changed) {
        const provider = MODELS[k].provider;
        let r;
        try {
          r = await ctx.callFunction("checkAiModel", { provider, model: input.value.trim() });
        } catch (e) {
          if (String(e?.message) === "invalid_model") {
            toast(t("modelInvalidName", { label: modelLabel(k) }), "error");
            input.focus();
            return false;
          }
          unchecked.push(modelLabel(k) + paren(errorText(e)));
          continue;
        }
        if (r.ok) {
          input.value = r.model; // as the company writes it ("models/" dropped)
        } else if (r.reason === "model_not_found") {
          toast(t("modelRefused", { label: modelLabel(k), reason: checkReason(r.reason, provider, r.model) }), "error");
          input.focus();
          return false;
        } else {
          unchecked.push(modelLabel(k) + paren(checkReason(r.reason, provider, r.model)));
        }
      }
    } finally {
      button.disabled = !ctx.canWrite();
      button.textContent = label;
    }
    if (!unchecked.length) return true;
    return confirmDialog({
      message: t("modelCheckFailedConfirm", { list: unchecked.join(ja() ? "、" : "; ") }),
      okLabel: t("saveAnyway"),
    });
  }

  function formatDate(iso) {
    const d = new Date(iso);
    if (Number.isNaN(d.getTime())) return String(iso);
    return d.toLocaleString(ja() ? "ja-JP" : "en-GB", { dateStyle: "medium", timeStyle: "short" });
  }

  function renderKeys() {
    if (!ctx.canWrite()) {
      keysEl.replaceChildren(h("p", { class: "field-hint" }, t("apiKeysAdminOnly")));
    } else if (keyState === undefined || keyState === null) {
      keysEl.replaceChildren(h("p", { class: "field-hint" }, t("apiKeysLoading")));
    } else if (keyState.error) {
      keysEl.replaceChildren(
        h("p", { class: "field-error" }, t("apiKeysLoadFailed", { error: errorText(keyState.error) })),
      );
    } else {
      keysEl.replaceChildren(...Object.keys(PROVIDERS).map((p) => keyRow(p, keyState.keys?.[p] ?? {})));
    }
  }

  function keyRow(provider, s) {
    const meta = PROVIDERS[provider];
    const name = t(meta.name);
    const input = h("input", {
      type: "password",
      class: "mono",
      placeholder: t("apiKeyNewPlaceholder"),
      autocomplete: "new-password",
      spellcheck: "false",
      "aria-label": `${name}: ${t("apiKeyNewPlaceholder")}`,
    });
    const error = h("p", { class: "field-error", role: "alert" });
    const button = h("button", { class: "small", type: "button", disabled: s.canSave !== true }, t("apiKeyChange"));
    button.addEventListener("click", () => changeKey(provider, input, button, error));
    input.addEventListener("keydown", (e) => {
      if (e.key === "Enter" && !button.disabled) button.click();
    });
    const current = s.error
      ? h("span", { class: "field-error" }, t("apiKeyUnreadable"))
      : h("code", { title: t("apiKeyCurrent", { last4: s.last4 ?? "" }) }, `…${s.last4 ?? ""}`);
    return h(
      "div",
      { class: "key-row" },
      h("div", { class: "key-name" }, h("strong", {}, name), h("span", { class: "field-hint" }, t(meta.use))),
      h(
        "div",
        { class: "key-state" },
        current,
        s.savedAt ? h("span", { class: "field-hint" }, t("apiKeySavedAt", { date: formatDate(s.savedAt) })) : null,
      ),
      h("div", { class: "key-edit" }, input, button),
      s.canSave === false ? h("p", { class: "field-hint key-note" }, t("apiKeyNoPermission")) : null,
      error,
    );
  }

  async function changeKey(provider, input, button, error) {
    const meta = PROVIDERS[provider];
    const name = t(meta.name);
    const key = input.value.trim();
    error.textContent = "";
    if (!key) {
      error.textContent = t("apiKeyEmpty");
      input.focus();
      return;
    }
    if (!meta.pattern.test(key)) {
      error.textContent = t(meta.format);
      input.focus();
      return;
    }
    const ok = await confirmDialog({
      title: t("apiKeyChangeTitle", { name }),
      message: t("apiKeyConfirm"),
      okLabel: t("apiKeyChange"),
    });
    if (!ok) return;
    const label = button.textContent;
    button.disabled = true;
    input.disabled = true;
    button.textContent = t("apiKeyChecking");
    try {
      const r = await ctx.callFunction("setAiApiKey", { provider, key });
      toast(r.unchanged ? t("apiKeyUnchanged") : t("apiKeyChanged", { name, last4: r.last4 }));
      loadKeys(); // fresh rows: the field is empty again, the new key's models listed
    } catch (e) {
      error.textContent = `${keyErrorText(e, provider)} ${t("apiKeyNotChanged")}`;
      button.disabled = false;
      input.disabled = false;
      button.textContent = label;
    }
  }

  async function loadKeys() {
    keysAsAdmin = ctx.canWrite();
    const mine = ++keysRequest;
    keyState = keysAsAdmin ? undefined : null;
    renderKeys();
    fillSuggestions();
    if (!keysAsAdmin) return;
    let next;
    try {
      next = await ctx.callFunction("getAiSettings", {});
    } catch (e) {
      next = { error: e };
    }
    if (disposed || mine !== keysRequest) return;
    keyState = next;
    renderKeys();
    fillSuggestions();
  }

  function fillSuggestions() {
    for (const [provider, list] of Object.entries(suggestions)) {
      const models = keyState?.keys?.[provider]?.models ?? [];
      list.replaceChildren(...models.map((m) => h("option", { value: m })));
    }
  }

  function number(n) {
    const v = Number(n);
    return (Number.isFinite(v) ? v : 0).toLocaleString(ja() ? "ja-JP" : "en-GB");
  }

  function renderUsage() {
    if (!usageEl) return;
    usageEl.classList.remove("error", "attention");
    if (!ctx.canWrite()) {
      usageEl.textContent = t("aiUsageAdminOnly");
    } else if (usageError) {
      usageEl.textContent = t("aiUsageLoadFailed", { error: errorText(usageError) });
      usageEl.classList.add("error");
    } else if (usage === undefined) {
      usageEl.textContent = t("aiUsageLoading");
    } else {
      const limit = ctx.parsed().aiDailyLimits.appTotal;
      usageEl.textContent = t("aiUsageToday", {
        count: number(usage.count),
        limit: number(limit),
        free: number(usage.free),
      });
      // The whole app has reached its limit: every AI call is refused until midnight.
      if ((Number(usage.count) || 0) >= limit) usageEl.classList.add("attention");
    }
  }

  function stopUsage() {
    if (unsubUsage) unsubUsage();
    unsubUsage = null;
    clearTimeout(dayTimer);
    dayTimer = null;
  }

  // Today's count, live. Only admin_uids may read it; the rights can change
  // while the page is open. A new Japan day starts a new count.
  function syncUsage() {
    if (ctx.canWrite() && !unsubUsage) {
      usage = undefined;
      usageError = null;
      unsubUsage = ctx.watchAiUsage(
        japanDay(),
        (data, fromCache) => {
          // Offline, the empty local cache would read as no use today.
          if (data === null && fromCache) return;
          usage = data ?? { count: 0, free: 0 };
          usageError = null;
          renderUsage();
        },
        (err) => {
          usageError = err;
          renderUsage();
        },
      );
      dayTimer = setTimeout(() => {
        stopUsage();
        syncUsage();
      }, msToNextJapanDay() + 1000);
    } else if (!ctx.canWrite() && unsubUsage) {
      stopUsage();
    }
    renderUsage();
  }

  load();
  syncUsage();
  loadKeys();

  return {
    isDirty: () => form.isDirty(),
    onConfig() {
      // The admin rights or the app's limit may have changed.
      syncUsage();
      if (ctx.canWrite() !== keysAsAdmin) loadKeys();
      if (saving || !stale.isStale()) return;
      if (!form.isDirty()) load();
      else if (!body.querySelector(".banner.stale")) {
        const banner = staleBanner(load);
        banner.classList.add("stale");
        body.prepend(banner);
      }
    },
    dispose() {
      disposed = true;
      stopUsage();
    },
  };
}
