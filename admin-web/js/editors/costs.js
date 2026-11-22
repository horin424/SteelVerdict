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
import { h, toast, parseWholeNumber, errorText } from "../ui.js";
import { t } from "../i18n.js";
import { AI_LIMIT_KEYS, modeName } from "../model.js";
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

// The model keys submitBattle reads, with the default it falls back to when a
// key is missing (functions/src/utils/config.ts). Always listed, so a model
// that was cleared can be set again; the app only lists keys already stored.
const MODEL_DEFAULTS = {
  claude: "claude-haiku-4-5-20251001",
  gemini_flash: "gemini-2.5-flash",
  gemini_flash_lite: "gemini-2.5-flash-lite",
};

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
  // Today's count of AI calls: undefined until it arrives.
  let usage;
  let usageError = null;
  let usageEl = null;
  let unsubUsage = null;
  let dayTimer = null;
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

  function load() {
    form.reset();
    const p = ctx.parsed();
    // Invalid stored costs keep their raw value, so they compare as stored.
    loadedCosts = { ...p.ticketCosts, ...p.invalidTicketCosts };
    loadedModels = {
      ...Object.fromEntries(Object.keys(MODEL_DEFAULTS).map((k) => [k, ""])),
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
    const modelRows = Object.keys(loadedModels)
      .sort()
      .map((k) => {
        const input = h("input", {
          type: "text",
          class: "mono",
          spellcheck: "false",
          placeholder: MODEL_DEFAULTS[k] ?? "",
          value: loadedModels[k],
        });
        modelInputs[k] = input;
        form.input(input);
        return h("label", { class: "model-row" }, h("span", {}, modeName(k, t)), h("code", {}, k), input);
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
      h("h3", { class: "section-label" }, t("adminTicketCostsSection")),
      h("div", { class: "stat-grid" }, costRows),
      h("h3", { class: "section-label" }, t("adminAiLimitsSection")),
      h("p", { class: "field-hint" }, t("aiLimitsHint")),
      h("div", { class: "stat-grid" }, limitRows),
      usageEl,
      h("h3", { class: "section-label" }, t("adminAiModelsSection")),
      h("p", { class: "field-hint" }, t("modelEmptyHint")),
      h("div", { class: "model-list" }, modelRows),
      h("div", { class: "save-bar" }, save),
    );
  }

  async function onSave(button) {
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

  function number(n) {
    const v = Number(n);
    return (Number.isFinite(v) ? v : 0).toLocaleString(ctx.lang() === "ja" ? "ja-JP" : "en-GB");
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

  return {
    isDirty: () => form.isDirty(),
    onConfig() {
      // The admin rights or the app's limit may have changed.
      syncUsage();
      if (saving || !stale.isStale()) return;
      if (!form.isDirty()) load();
      else if (!body.querySelector(".banner.stale")) {
        const banner = staleBanner(load);
        banner.classList.add("stale");
        body.prepend(banner);
      }
    },
    dispose() {
      stopUsage();
    },
  };
}
