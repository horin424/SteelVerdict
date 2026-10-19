// Mode instructions: port of lib/features/admin/screens/admin_mode_addons_editor.dart.
//
// Same list as the app (its seven default modes, then any others the config
// holds) and the same merge write into mode_addons. One deliberate difference:
// the app skips empty fields, so with a merge write an instruction can never be
// removed (client review). Here an emptied field deletes that mode's entry,
// which prompt.ts treats the same as never having one.
import { h, field } from "../ui.js";
import { t } from "../i18n.js";
import { modeName } from "../model.js";
import { FormTracker, SaveMerger, StaleWatch, guardedSave, saveButton, staleBanner } from "../editorkit.js";

const DEFAULT_MODES = ["practice", "normal", "tabletop", "epic", "boss", "history_puzzle", "pvp"];

export function mountModeAddons(root, ctx) {
  let loaded = null; // { mode: text } as the form showed it
  let inputs = {};
  let saving = false;
  const form = new FormTracker();
  const stale = new StaleWatch(() => [ctx.raw().modeAddons ?? null, ctx.raw().mode_addons ?? null]);
  const body = h("section", { class: "single" });
  root.append(body);

  function load() {
    form.reset();
    const addons = ctx.parsed().modeAddons;
    const modes = [...DEFAULT_MODES, ...Object.keys(addons).filter((m) => !DEFAULT_MODES.includes(m))];
    loaded = Object.fromEntries(modes.map((m) => [m, addons[m] ?? ""]));
    inputs = {};
    const rows = modes.map((m) => {
      const f = field({ label: modeName(m, t), value: loaded[m], rows: 5, mono: true, counter: true, hint: m });
      inputs[m] = f.input;
      form.input(f.input);
      return f.el;
    });
    stale.capture();
    const save = saveButton(ctx, () => onSave(save));
    body.replaceChildren(
      h("p", { class: "note" }, t("adminPromptEnglishOnly")),
      h("p", { class: "field-hint" }, t("emptyFieldsRemoved")),
      ...rows,
      h("div", { class: "save-bar" }, save),
    );
  }

  async function onSave(button) {
    saving = true;
    const ok = await guardedSave({
      ctx,
      button,
      build: () => {
        const m = new SaveMerger();
        const current = ctx.parsed().modeAddons;
        const stored = ctx.raw().mode_addons ?? {};
        const out = {};
        for (const [mode, input] of Object.entries(inputs)) {
          const value = m.text(input.value, loaded[mode], current[mode] ?? "");
          if (value) out[mode] = value;
          // Emptied by the admin: remove it. Stored empty already: leave it.
          else if (stored[mode]) out[mode] = ctx.deleteField();
        }
        return { merger: m, payload: { mode_addons: out } };
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
