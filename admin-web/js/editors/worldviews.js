// Worldviews: port of lib/features/admin/screens/admin_worldview_editor.dart.
//
// Same fields and the same save as the app: one merge write of the selected
// world, each prompt written under both camelCase and snake_case (the app reads
// camelCase, prompt.ts reads snake_case first), resultType under both, and the
// world's stats and stat descriptions carried through unchanged.
import { h, fill, field, toast, confirmDialog, promptDialog, englishOnlyNote, errorText } from "../ui.js";
import { t } from "../i18n.js";
import { BUILTIN_DEFAULT_WORLDVIEW, DEFAULT_WORLDVIEW_KEY, localizedTitle, normalizeText } from "../model.js";
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

export function mountWorldviews(root, ctx) {
  let selected = null;
  let loaded = null; // the parsed world as the form was filled
  let pendingSelect = null; // just added, not yet in the config
  let saving = false;
  let fields = null;
  const form = new FormTracker();
  const stale = new StaleWatch(() => (selected ? ctx.raw().worldviews?.[selected] : null));

  const listEl = h("nav", { class: "item-list", "aria-label": t("adminWorldviews") });
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
          h("span", {}, t("adminWorldviews")),
          h("button", { class: "small", type: "button", onClick: add }, `+ ${t("adminAdd")}`),
        ),
        listEl,
      ),
      formEl,
    ),
  );

  function renderList() {
    const worldviews = ctx.parsed().worldviews;
    // Sorted: the app lists map order, which reshuffles after every save.
    const keys = Object.keys(worldviews).sort();
    listEl.replaceChildren(
      ...keys.map((key) =>
        h(
          "div",
          { class: `list-item${key === selected ? " active" : ""}` },
          h(
            "button",
            { class: "list-main", type: "button", onClick: () => select(key) },
            h("span", { class: "list-title" }, localizedTitle(worldviews[key], ctx.lang()) || key),
            h("span", { class: "list-sub" }, `ID: ${key}`),
          ),
          h(
            "button",
            {
              class: "icon-btn",
              type: "button",
              title: t("adminDelete"),
              "aria-label": `${t("adminDelete")}: ${key}`,
              onClick: () => remove(key),
            },
            trashIcon(),
          ),
        ),
      ),
    );
  }

  async function select(key) {
    if (key === selected) return;
    if (form.isDirty() && !(await confirmDiscard())) return;
    load(key);
  }

  function load(key) {
    const wv = key ? ctx.parsed().worldviews[key] : null;
    selected = wv ? key : null;
    loaded = wv;
    stale.capture();
    renderForm();
    renderList();
  }

  /// Text the app and the AI would read differently: camelCase and snake_case
  /// both present and not equal.
  function mismatch(raw, camel, snake) {
    return (
      raw &&
      typeof raw[camel] === "string" &&
      typeof raw[snake] === "string" &&
      normalizeText(raw[camel]) !== normalizeText(raw[snake])
    );
  }

  function renderForm() {
    form.reset();
    fields = null;
    if (!selected) {
      formEl.replaceChildren(h("p", { class: "empty" }, t("adminSelectWorldview")));
      return;
    }
    const wv = loaded;
    const raw = ctx.raw().worldviews?.[selected] ?? {};
    const f = {
      title: field({ label: t("adminTitle"), value: wv.title }),
      titleJa: field({ label: t("adminTitleJa"), value: wv.titleJa ?? "" }),
      judgment: field({ label: t("adminCommonJudgment"), value: wv.commonJudgment, rows: 22, mono: true, counter: true }),
      desc: field({ label: t("adminDescription"), value: wv.worldviewDescription, rows: 8, counter: true }),
      descJa: field({ label: t("adminDescriptionJa"), value: wv.worldviewDescriptionJa ?? "", rows: 8, counter: true }),
      resultType: h(
        "select",
        {},
        h("option", { value: "battle" }, t("resultBattle")),
        h("option", { value: "survival" }, t("resultSurvival")),
      ),
    };
    f.resultType.value = wv.resultType === "survival" ? "survival" : "battle";
    for (const k of ["title", "titleJa", "judgment", "desc", "descJa"]) form.input(f[k].input);
    form.add(() => f.resultType.value);
    fields = f;

    const save = saveButton(ctx, () => onSave(save));
    fill(formEl,
      h("h2", { class: "form-title" }, localizedTitle(wv, ctx.lang()) || selected, h("code", {}, selected)),
      h("div", { class: "row-2" }, f.title.el, f.titleJa.el),
      mismatch(raw, "commonJudgment", "common_judgment") ? h("p", { class: "banner warn" }, t("mismatchWarning")) : null,
      f.judgment.el,
      englishOnlyNote(),
      mismatch(raw, "worldviewDescription", "worldview_description")
        ? h("p", { class: "banner warn" }, t("mismatchWarning"))
        : null,
      h("div", { class: "row-2" }, f.desc.el, f.descJa.el),
      h("label", { class: "field" }, h("span", { class: "field-label" }, t("resultType")), f.resultType),
      h("div", { class: "save-bar" }, save),
    );
  }

  async function onSave(button) {
    const key = selected;
    const f = fields;
    saving = true;
    const ok = await guardedSave({
      ctx,
      button,
      build: () => {
        const m = new SaveMerger();
        // The world as the config holds it now: undefined if deleted elsewhere.
        const current = ctx.parsed().worldviews[key];
        const now = (prop, fallback) => (current ? current[prop] ?? fallback : undefined);
        const asResult = (v) => (v === "survival" ? "survival" : "battle");

        const judgment = m.text(f.judgment.input.value, loaded.commonJudgment, now("commonJudgment", ""));
        const desc = m.text(f.desc.input.value, loaded.worldviewDescription, now("worldviewDescription", ""));
        const descJa = m.text(f.descJa.input.value, loaded.worldviewDescriptionJa ?? "", now("worldviewDescriptionJa", ""));
        const resultType = m.value(
          f.resultType.value,
          asResult(loaded.resultType),
          current ? asResult(current.resultType) : undefined,
        );
        return {
          merger: m,
          payload: {
            worldviews: {
              [key]: {
                worldviewKey: key,
                title: m.text(f.title.input.value, loaded.title, now("title", "")),
                titleJa: m.text(f.titleJa.input.value, loaded.titleJa ?? "", now("titleJa", "")),
                commonJudgment: judgment,
                worldviewDescription: desc,
                worldviewDescriptionJa: descJa,
                resultType,
                result_type: resultType,
                // Written twice on purpose - see the comment in the app's editor.
                common_judgment: judgment,
                worldview_description: desc,
                worldview_description_ja: descJa,
                // As the config holds them now, like the app.
                stats: current?.stats ?? [],
                statDescriptions: current?.statDescriptions ?? {},
              },
            },
          },
        };
      },
    });
    saving = false;
    if (ok && selected === key) load(key);
  }

  async function add() {
    if (form.isDirty() && !(await confirmDiscard())) return;
    const key = await promptDialog({
      title: t("adminNewWorldview"),
      placeholder: t("adminWorldviewKeyHint"),
      okLabel: t("adminAdd"),
      validate: (v) => validateNewKey(v, ctx.raw().worldviews, ctx.parsed().worldviews),
    });
    if (!key) return;
    if (!ctx.canWrite()) {
      toast(t("readOnly"), "error");
      return;
    }
    // Seeded from the live default world, as in the app.
    const liveDefault = ctx.parsed().worldviews[DEFAULT_WORLDVIEW_KEY];
    const stats = liveDefault?.stats?.length ? liveDefault.stats : BUILTIN_DEFAULT_WORLDVIEW.stats;
    const statDescriptions =
      liveDefault && Object.keys(liveDefault.statDescriptions).length
        ? liveDefault.statDescriptions
        : BUILTIN_DEFAULT_WORLDVIEW.statDescriptions;
    try {
      await ctx.merge({
        worldviews: {
          [key]: {
            worldviewKey: key,
            title: key,
            titleJa: "",
            commonJudgment: "",
            common_judgment: "",
            worldviewDescription: "",
            worldview_description: "",
            worldviewDescriptionJa: "",
            resultType: "battle",
            result_type: "battle",
            worldview_description_ja: "",
            stats,
            statDescriptions,
          },
        },
      });
      toast(t("added"));
      // Open it now if the config already shows it, else when it arrives.
      if (ctx.parsed().worldviews[key]) load(key);
      else pendingSelect = key;
    } catch (e) {
      toast(t("adminSaveError", { error: errorText(e) }), "error");
    }
  }

  async function remove(key) {
    const ok = await confirmDialog({
      title: t("adminDelete"),
      message: `${t("adminDeleteConfirm")} (${key})`,
      okLabel: t("adminDelete"),
      danger: true,
    });
    if (!ok) return;
    if (!ctx.canWrite()) {
      toast(t("readOnly"), "error");
      return;
    }
    try {
      await ctx.deleteKey("worldviews", key);
      toast(t("deleted"));
      if (selected === key) load(null);
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
      if (pendingSelect && ctx.parsed().worldviews[pendingSelect] && !form.isDirty()) {
        const key = pendingSelect;
        pendingSelect = null;
        load(key);
        return;
      }
      renderList();
      if (!selected || saving) return;
      if (!ctx.parsed().worldviews[selected]) {
        // Deleted elsewhere. Keep unsaved edits on screen (saving recreates
        // the world); otherwise close the form.
        if (!form.isDirty()) load(null);
        else if (!formEl.querySelector(".banner.stale")) {
          const banner = staleBanner(() => load(null));
          banner.classList.add("stale");
          formEl.prepend(banner);
        }
        return;
      }
      if (!stale.isStale()) return;
      // Nothing typed yet: just show the newer version. Otherwise warn.
      if (!form.isDirty()) load(selected);
      else if (!formEl.querySelector(".banner.stale")) {
        const banner = staleBanner(() => load(selected));
        banner.classList.add("stale");
        formEl.prepend(banner);
      }
    },
  };
}
