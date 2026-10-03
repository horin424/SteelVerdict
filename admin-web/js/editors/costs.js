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
import { h, toast, parseWholeNumber } from "../ui.js";
import { t } from "../i18n.js";
import { modeName } from "../model.js";
import { FormTracker, SaveMerger, StaleWatch, guardedSave, saveButton, staleBanner } from "../editorkit.js";

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
  let saving = false;
  const form = new FormTracker();
  const stale = new StaleWatch(() => {
    const r = ctx.raw();
    return [r.ticketCosts ?? null, r.ticket_costs ?? null, r.modelConfig ?? null, r.model_config ?? null];
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

    stale.capture();
    const save = saveButton(ctx, () => onSave(save));
    body.replaceChildren(
      h("h3", { class: "section-label" }, t("adminTicketCostsSection")),
      h("div", { class: "stat-grid" }, costRows),
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
        const storedModels = ctx.raw().model_config ?? {};
        const models = {};
        for (const [k, input] of Object.entries(modelInputs)) {
          const value = m.text(input.value, loadedModels[k] ?? "", p.modelConfig[k] ?? "", { trim: true });
          if (value) models[k] = value;
          // Emptied by the admin: remove it. Stored empty already: leave it.
          else if (storedModels[k]) models[k] = ctx.deleteField();
        }
        return { merger: m, payload: { ticket_costs: costs, model_config: models } };
      },
    });
    saving = false;
    if (ok) load();
  }

  load();

  return {
    isDirty: () => form.isDirty(),
    onConfig() {
      if (saving || !stale.isStale()) return;
      if (!form.isDirty()) load();
      else if (!body.querySelector(".banner.stale")) {
        const banner = staleBanner(load);
        banner.classList.add("stale");
        body.prepend(banner);
      }
    },
  };
}
