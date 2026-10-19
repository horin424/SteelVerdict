// Scenarios: port of lib/features/admin/screens/admin_scenario_editor.dart.
//
// Same fields and the same merge write as the app, including the commander
// definition under both camelCase and snake_case (prompt.ts reads snake_case
// first) and isUnlocked carried through untouched.
//
// Differences, all deliberate:
// - Numbers are validated instead of silently becoming 0 or 1.
// - A new scenario's enemy stats use the default world's stat keys. The app
//   still uses the legacy strength/intellect/skill/... set (client review item).
// - A scenario pointing at a world that no longer exists keeps that key instead
//   of being quietly moved to the first world on save.
import { h, fill, field, toast, confirmDialog, promptDialog, errorText, parseWholeNumber } from "../ui.js";
import { t } from "../i18n.js";
import { DEFAULT_WORLDVIEW_KEY, LEGACY_STAT_KEYS, localizedTitle, normalizeText, statName } from "../model.js";
import {
  FormTracker,
  SaveMerger,
  StaleWatch,
  confirmDiscard,
  guardedSave,
  saveButton,
  staleBanner,
  trashIcon,
  validateNewKey,
} from "../editorkit.js";

const BATTLE_TYPES = ["standard", "boss", "history"];

function battleTypeName(type) {
  return (
    { standard: t("battleTypeStandard"), boss: t("battleTypeBoss"), history: t("battleTypeHistory") }[type] ?? type
  );
}

export function mountScenarios(root, ctx) {
  let selected = null;
  let loaded = null; // the parsed scenario as the form was filled
  let loadedWorld = null; // the world key the form showed
  let loadedStats = null; // { key: number } as the form showed it
  let pendingSelect = null; // just added, not yet in the config
  let saving = false;
  let fields = null;
  const form = new FormTracker();
  const stale = new StaleWatch(() => (selected ? ctx.raw().scenarios?.[selected] : null));

  const listEl = h("nav", { class: "item-list", "aria-label": t("adminScenarios") });
  const formEl = h("section", { class: "item-form" });
  root.append(
    h(
      "div",
      { class: "split" },
      h(
        "div",
        { class: "list-col" },
        h(
          "div",
          { class: "list-head" },
          h("span", {}, t("adminScenarios")),
          h("button", { class: "small", type: "button", onClick: add }, `+ ${t("adminAdd")}`),
        ),
        listEl,
      ),
      formEl,
    ),
  );

  /// Stat keys for a scenario with none stored: its world's, else the default
  /// world's, else the legacy set the app uses.
  function defaultStatKeys(worldKey) {
    const worlds = ctx.parsed().worldviews;
    return worlds[worldKey]?.stats?.length
      ? worlds[worldKey].stats
      : worlds[DEFAULT_WORLDVIEW_KEY]?.stats?.length
        ? worlds[DEFAULT_WORLDVIEW_KEY].stats
        : LEGACY_STAT_KEYS;
  }

  function renderList() {
    const { scenarios, worldviews } = ctx.parsed();
    const lang = ctx.lang();
    // Grouped by world, then by id. The app shows one flat list in map order.
    const groups = {};
    for (const id of Object.keys(scenarios)) (groups[scenarios[id].worldviewKey] ??= []).push(id);
    listEl.replaceChildren(
      ...Object.keys(groups)
        .sort()
        .map((world) =>
          h(
            "div",
            { class: "list-group" },
            h("div", { class: "list-group-title" }, worldviews[world] ? localizedTitle(worldviews[world], lang) : world),
            ...groups[world].sort().map((id) => {
              const s = scenarios[id];
              return h(
                "div",
                { class: `list-item${id === selected ? " active" : ""}` },
                h(
                  "button",
                  { class: "list-main", type: "button", onClick: () => select(id) },
                  h("span", { class: "list-title" }, localizedTitle(s, lang) || id),
                  h("span", { class: "list-sub" }, `${battleTypeName(s.battleType)} / ${s.difficulty} · ${id}`),
                ),
                h(
                  "button",
                  {
                    class: "icon-btn",
                    type: "button",
                    title: t("adminDelete"),
                    "aria-label": `${t("adminDelete")}: ${id}`,
                    onClick: () => remove(id),
                  },
                  trashIcon(),
                ),
              );
            }),
          ),
        ),
    );
  }

  async function select(id) {
    if (id === selected) return;
    if (form.isDirty() && !(await confirmDiscard())) return;
    load(id);
  }

  function load(id) {
    const s = id ? ctx.parsed().scenarios[id] : null;
    selected = s ? id : null;
    loaded = s;
    stale.capture();
    renderForm();
    renderList();
  }

  function renderForm() {
    form.reset();
    fields = null;
    if (!selected) {
      formEl.replaceChildren(h("p", { class: "empty" }, t("adminSelectScenario")));
      return;
    }
    const s = loaded;
    const worlds = ctx.parsed().worldviews;
    const lang = ctx.lang();

    const worldSelect = h("select", {});
    const worldKeys = Object.keys(worlds).sort();
    for (const k of worldKeys) worldSelect.append(h("option", { value: k }, `${localizedTitle(worlds[k], lang)} (${k})`));
    if (!worlds[s.worldviewKey]) worldSelect.append(h("option", { value: s.worldviewKey }, `${s.worldviewKey} (?)`));
    worldSelect.value = s.worldviewKey;
    loadedWorld = worldSelect.value;

    const typeSelect = h("select", {}, ...BATTLE_TYPES.map((v) => h("option", { value: v }, battleTypeName(v))));
    typeSelect.value = s.battleType;
    const free = h("input", { type: "checkbox", checked: s.isFree });

    // Enemy stats in the world's stat order, extra keys after.
    const storedKeys = Object.keys(s.enemyStats);
    const keys = storedKeys.length ? storedKeys : defaultStatKeys(s.worldviewKey);
    const worldOrder = worlds[s.worldviewKey]?.stats ?? [];
    const ordered = [
      ...worldOrder.filter((k) => keys.includes(k)),
      ...keys.filter((k) => !worldOrder.includes(k)).sort(),
    ];
    loadedStats = Object.fromEntries(ordered.map((k) => [k, s.enemyStats[k] ?? 0]));
    const statInputs = {};
    const statRows = ordered.map((k) => {
      const input = h("input", { type: "text", inputmode: "numeric", class: "num", value: String(loadedStats[k]) });
      statInputs[k] = input;
      form.input(input);
      return h(
        "label",
        { class: "stat-row" },
        h("span", {}, statName(k, t)),
        h("code", {}, k),
        input,
      );
    });
    const keysDiffer =
      worldOrder.length &&
      (ordered.length !== worldOrder.length || ordered.some((k) => !worldOrder.includes(k)));

    const f = {
      title: field({ label: t("adminTitle"), value: s.title }),
      titleJa: field({ label: t("adminTitleJa"), value: s.titleJa ?? "" }),
      enemyName: field({ label: t("adminEnemyName"), value: s.enemyName }),
      enemyNameJa: field({ label: t("adminEnemyNameJa"), value: s.enemyNameJa ?? "" }),
      commander: field({ label: t("adminCommanderDef"), value: s.commanderDefinition, rows: 6, counter: true }),
      commanderJa: field({ label: t("adminCommanderDefJa"), value: s.commanderDefinitionJa ?? "", rows: 6, counter: true }),
      difficulty: field({ label: `${t("adminDifficulty")} (1–5)`, value: String(s.difficulty) }),
      worldSelect,
      typeSelect,
      free,
      statInputs,
    };
    f.difficulty.input.setAttribute("inputmode", "numeric");
    for (const k of ["title", "titleJa", "enemyName", "enemyNameJa", "commander", "commanderJa", "difficulty"]) {
      form.input(f[k].input);
    }
    form.add(() => worldSelect.value);
    form.add(() => typeSelect.value);
    form.input(free);
    fields = f;

    const raw = ctx.raw().scenarios?.[selected] ?? {};
    const mismatch =
      typeof raw.commanderDefinition === "string" &&
      typeof raw.commander_definition === "string" &&
      normalizeText(raw.commanderDefinition) !== normalizeText(raw.commander_definition);

    const save = saveButton(ctx, () => onSave(save));
    fill(formEl,
      h("h2", { class: "form-title" }, localizedTitle(s, lang) || selected, h("code", {}, selected)),
      h("div", { class: "row-2" }, f.title.el, f.titleJa.el),
      h("div", { class: "row-2" }, f.enemyName.el, f.enemyNameJa.el),
      mismatch ? h("p", { class: "banner warn" }, t("mismatchWarning")) : null,
      h("div", { class: "row-2" }, f.commander.el, f.commanderJa.el),
      h(
        "div",
        { class: "row-3" },
        h("label", { class: "field" }, h("span", { class: "field-label" }, t("adminWorldviewSection")), worldSelect),
        h("label", { class: "field" }, h("span", { class: "field-label" }, t("adminBattleType")), typeSelect),
        f.difficulty.el,
      ),
      h("label", { class: "check" }, free, h("span", {}, t("adminFreeScenario"))),
      h("h3", { class: "section-label" }, t("adminEnemyStatsSection")),
      keysDiffer
        ? h("p", { class: "field-hint" }, `${t("statsFromWorld")} (${worldOrder.map((k) => statName(k, t)).join(" / ")})`)
        : null,
      h("div", { class: "stat-grid" }, statRows),
      h("div", { class: "save-bar" }, save),
    );
  }

  async function onSave(button) {
    const id = selected;
    const f = fields;
    saving = true;
    const ok = await guardedSave({
      ctx,
      button,
      build: () => {
        const difficulty = parseWholeNumber(f.difficulty.input.value, t("adminDifficulty"), { min: 1, max: 5 });
        if (difficulty.error) {
          toast(difficulty.error, "error");
          return null;
        }
        const statValues = {};
        for (const [k, input] of Object.entries(f.statInputs)) {
          const n = parseWholeNumber(input.value, statName(k, t), { min: 0 });
          if (n.error) {
            toast(n.error, "error");
            return null;
          }
          statValues[k] = n.value;
        }

        const m = new SaveMerger();
        const current = ctx.parsed().scenarios[id];
        const now = (prop, fallback) => (current ? current[prop] ?? fallback : undefined);
        const commander = m.text(f.commander.input.value, loaded.commanderDefinition, now("commanderDefinition", ""));
        const commanderJa = m.text(
          f.commanderJa.input.value,
          loaded.commanderDefinitionJa ?? "",
          now("commanderDefinitionJa", ""),
        );
        const enemyStats = {};
        for (const [k, v] of Object.entries(statValues)) {
          enemyStats[k] = m.value(v, loadedStats[k], current ? current.enemyStats[k] ?? loadedStats[k] : undefined);
        }
        return {
          merger: m,
          payload: {
            scenarios: {
              [id]: {
                scenarioId: id,
                title: m.text(f.title.input.value, loaded.title, now("title", "")),
                titleJa: m.text(f.titleJa.input.value, loaded.titleJa ?? "", now("titleJa", "")),
                enemyName: m.text(f.enemyName.input.value, loaded.enemyName, now("enemyName", "")),
                enemyNameJa: m.text(f.enemyNameJa.input.value, loaded.enemyNameJa ?? "", now("enemyNameJa", "")),
                commanderDefinition: commander,
                commanderDefinitionJa: commanderJa,
                // Also written in snake_case, as in the app: prompt.ts reads
                // commander_definition first.
                commander_definition: commander,
                commander_definition_ja: commanderJa,
                difficulty: m.value(difficulty.value, loaded.difficulty, now("difficulty")),
                battleType: m.value(f.typeSelect.value, loaded.battleType, now("battleType")),
                isFree: m.value(f.free.checked, loaded.isFree, now("isFree")),
                worldviewKey: m.value(f.worldSelect.value, loadedWorld, now("worldviewKey")),
                isUnlocked: current?.isUnlocked ?? true,
                enemyStats,
              },
            },
          },
        };
      },
    });
    saving = false;
    if (ok && selected === id) load(id);
  }

  async function add() {
    if (form.isDirty() && !(await confirmDiscard())) return;
    const id = await promptDialog({
      title: t("adminNewScenario"),
      placeholder: t("adminScenarioIdHint"),
      okLabel: t("adminAdd"),
      validate: (v) => validateNewKey(v, ctx.raw().scenarios, ctx.parsed().scenarios),
    });
    if (!id) return;
    if (!ctx.canWrite()) {
      toast(t("readOnly"), "error");
      return;
    }
    try {
      await ctx.merge({
        scenarios: {
          [id]: {
            scenarioId: id,
            title: id,
            titleJa: "",
            enemyName: "",
            enemyNameJa: "",
            commanderDefinition: "",
            commanderDefinitionJa: "",
            commander_definition: "",
            commander_definition_ja: "",
            difficulty: 1,
            battleType: "standard",
            isFree: false,
            worldviewKey: DEFAULT_WORLDVIEW_KEY,
            isUnlocked: true,
            enemyStats: Object.fromEntries(defaultStatKeys(DEFAULT_WORLDVIEW_KEY).map((k) => [k, 0])),
          },
        },
      });
      toast(t("added"));
      // Open it now if the config already shows it, else when it arrives.
      if (ctx.parsed().scenarios[id]) load(id);
      else pendingSelect = id;
    } catch (e) {
      toast(t("adminSaveError", { error: errorText(e) }), "error");
    }
  }

  async function remove(id) {
    const ok = await confirmDialog({
      title: t("adminDelete"),
      message: `${t("adminDeleteConfirm")} (${id})`,
      okLabel: t("adminDelete"),
      danger: true,
    });
    if (!ok) return;
    if (!ctx.canWrite()) {
      toast(t("readOnly"), "error");
      return;
    }
    try {
      await ctx.deleteKey("scenarios", id);
      toast(t("deleted"));
      if (selected === id) load(null);
      else renderList();
    } catch (e) {
      toast(t("adminSaveError", { error: errorText(e) }), "error");
    }
  }

  renderList();
  renderForm();

  return {
    isDirty: () => form.isDirty(),
    onConfig() {
      if (pendingSelect && ctx.parsed().scenarios[pendingSelect] && !form.isDirty()) {
        const id = pendingSelect;
        pendingSelect = null;
        load(id);
        return;
      }
      renderList();
      if (!selected || saving) return;
      if (!ctx.parsed().scenarios[selected]) {
        // Deleted elsewhere. Keep unsaved edits on screen (saving recreates
        // the scenario); otherwise close the form.
        if (!form.isDirty()) load(null);
        else if (!formEl.querySelector(".banner.stale")) {
          const banner = staleBanner(() => load(null));
          banner.classList.add("stale");
          formEl.prepend(banner);
        }
        return;
      }
      if (!stale.isStale()) return;
      if (!form.isDirty()) load(selected);
      else if (!formEl.querySelector(".banner.stale")) {
        const banner = staleBanner(() => load(selected));
        banner.classList.add("stale");
        formEl.prepend(banner);
      }
    },
  };
}
