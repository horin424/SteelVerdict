// System settings: port of lib/features/admin/screens/admin_system_config_editor.dart.
//
// Same fields and the same merge write as the app: the fallback prompt and the
// dev UID list each under camelCase and snake_case, and the two ad unit ids.
//
// Differences, deliberate:
// - The form is filled only once the real config has arrived. The app fills it
//   once, from whatever it has; opened before the config loads, it holds the
//   defaults, and saving writes them - an empty dev_uids that locks every admin
//   out. On a web page opened by URL that would be the normal case.
// - Saving a list without your own UID, or an empty list, asks first.
// - The ad unit fields say they are not used: the app reads its ad units from
//   Remote Config.
import { h, field, confirmDialog } from "../ui.js";
import { t } from "../i18n.js";
import { FormTracker, SaveMerger, StaleWatch, guardedSave, saveButton, staleBanner, trashIcon } from "../editorkit.js";

export function mountSystemConfig(root, ctx) {
  let loaded = null;
  let uids = [];
  let inputs = null;
  let saving = false;
  const form = new FormTracker();
  const stale = new StaleWatch(() => {
    const r = ctx.raw();
    return [
      r.fallbackPrompt ?? null,
      r.fallback_prompt ?? null,
      r.devUids ?? null,
      r.dev_uids ?? null,
      r.adUnitRewarded ?? null,
      r.adUnitInterstitial ?? null,
    ];
  });
  const body = h("section", { class: "single" });
  root.append(body);

  function load() {
    form.reset();
    const p = ctx.parsed();
    loaded = {
      fallbackPrompt: p.fallbackPrompt ?? "",
      devUids: [...p.devUids],
      adUnitRewarded: p.adUnitRewarded,
      adUnitInterstitial: p.adUnitInterstitial,
    };
    uids = [...loaded.devUids];
    inputs = {
      fallback: field({
        label: t("adminFallbackPromptHelp"),
        value: loaded.fallbackPrompt,
        rows: 10,
        mono: true,
        counter: true,
      }),
      rewarded: field({ label: t("adminRewardedAdUnit"), value: loaded.adUnitRewarded }),
      interstitial: field({ label: t("adminInterstitialAdUnit"), value: loaded.adUnitInterstitial }),
    };
    form.input(inputs.fallback.input);
    form.input(inputs.rewarded.input);
    form.input(inputs.interstitial.input);
    form.add(() => [...uids]);

    const uidList = h("div", { class: "uid-list" });
    const newUid = h("input", { type: "text", class: "mono", placeholder: t("adminDevUidHint"), spellcheck: "false" });
    const addUid = () => {
      const uid = newUid.value.trim();
      if (!uid || uids.includes(uid)) return;
      uids.push(uid);
      newUid.value = "";
      renderUids();
    };
    newUid.addEventListener("keydown", (e) => {
      if (e.key === "Enter") addUid();
    });
    function renderUids() {
      uidList.replaceChildren(
        ...uids.map((uid) =>
          h(
            "div",
            { class: "uid-row" },
            h("code", {}, uid),
            uid === ctx.uid ? h("span", { class: "pill" }, t("you")) : null,
            h(
              "button",
              {
                class: "icon-btn",
                type: "button",
                title: t("adminDelete"),
                "aria-label": `${t("adminDelete")}: ${uid}`,
                onClick: () => {
                  uids = uids.filter((u) => u !== uid);
                  renderUids();
                },
              },
              trashIcon(),
            ),
          ),
        ),
      );
    }
    renderUids();

    stale.capture();
    const save = saveButton(ctx, () => onSave(save));
    body.replaceChildren(
      h("h3", { class: "section-label" }, t("adminFallbackPromptSection")),
      inputs.fallback.el,
      h("h3", { class: "section-label" }, t("adminDevUidsSection")),
      uidList,
      h(
        "div",
        { class: "uid-add" },
        newUid,
        h("button", { class: "small", type: "button", onClick: addUid }, t("adminAdd")),
      ),
      h("h3", { class: "section-label" }, t("adminAdUnitsSection")),
      h("p", { class: "field-hint" }, t("adUnitsUnused")),
      h("div", { class: "row-2" }, inputs.rewarded.el, inputs.interstitial.el),
      h("div", { class: "save-bar" }, save),
    );
  }

  async function onSave(button) {
    if (uids.length === 0) {
      if (!(await confirmDialog({ message: t("emptyUidsConfirm"), okLabel: t("adminSave"), danger: true }))) return;
    } else if (loaded.devUids.includes(ctx.uid) && !uids.includes(ctx.uid)) {
      if (!(await confirmDialog({ message: t("removeSelfConfirm"), okLabel: t("adminSave"), danger: true }))) return;
    }
    saving = true;
    const ok = await guardedSave({
      ctx,
      button,
      build: () => {
        const p = ctx.parsed();
        const m = new SaveMerger();
        // The app trims these on save; untouched values are written as stored.
        const trim = { trim: true };
        const fallback = m.text(inputs.fallback.input.value, loaded.fallbackPrompt, p.fallbackPrompt ?? "", trim);
        const devUids = m.value([...uids], loaded.devUids, p.devUids);
        return {
          merger: m,
          payload: {
            // Both spellings, as in the app: the app reads camelCase, the
            // functions read snake_case.
            fallbackPrompt: fallback,
            fallback_prompt: fallback,
            devUids,
            dev_uids: devUids,
            adUnitRewarded: m.text(inputs.rewarded.input.value, loaded.adUnitRewarded, p.adUnitRewarded, trim),
            adUnitInterstitial: m.text(
              inputs.interstitial.input.value,
              loaded.adUnitInterstitial,
              p.adUnitInterstitial,
              trim,
            ),
          },
        };
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
