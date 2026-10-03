// Plumbing shared by the five editors.
import { h, toast, confirmDialog, errorText } from "./ui.js";
import { t } from "./i18n.js";
import { normalizeText } from "./model.js";

/// JSON with sorted keys, so two snapshots of the same data compare equal
/// whatever order the SDK hands the fields back in.
export function stableStringify(v) {
  if (Array.isArray(v)) return `[${v.map(stableStringify).join(",")}]`;
  if (v && typeof v === "object") {
    return `{${Object.keys(v)
      .sort()
      .map((k) => `${JSON.stringify(k)}:${stableStringify(v[k])}`)
      .join(",")}}`;
  }
  return JSON.stringify(v ?? null);
}

/// Remembers what a form was loaded with, to tell whether the admin changed it.
export class FormTracker {
  constructor() {
    this.items = [];
  }

  /// `read` returns the current value; it is compared with its value now.
  add(read) {
    this.items.push({ read, original: read() });
  }

  input(el) {
    this.add(() => (el.type === "checkbox" ? el.checked : normalizeText(el.value)));
    return el;
  }

  reset() {
    this.items = [];
  }

  isDirty() {
    return this.items.some(({ read, original }) => stableStringify(read()) !== stableStringify(original));
  }
}

/// Notices when the stored data under an editor changes after it was opened -
/// another admin, or the app's panel, saving in the meantime. The app's panel
/// has no such check: whoever saves last silently wins.
export class StaleWatch {
  constructor(read) {
    this.read = read;
    this.base = null;
  }

  capture() {
    this.base = stableStringify(this.read());
  }

  isStale() {
    return this.base !== null && stableStringify(this.read()) !== this.base;
  }
}

export async function confirmDiscard() {
  return confirmDialog({ message: t("unsaved"), okLabel: t("discard"), danger: true });
}

/// Decides, field by field, what one save writes.
///
/// A field the admin left alone is written as it is stored *now*, so a change
/// made elsewhere since the form opened survives, and so the stored text keeps
/// its exact bytes (CRLF included). A field the admin changed is written as
/// typed, and if it was also changed elsewhere that is a conflict the admin is
/// asked about. The app's panel writes every field from the form, so the last
/// save silently undoes any other change.
export class SaveMerger {
  constructor() {
    this.conflict = false;
  }

  /// `trim` trims only what the admin typed, as the app does on save; an
  /// untouched value keeps any whitespace it was stored with.
  text(typed, loadedValue, currentValue, { trim = false } = {}) {
    const loaded = loadedValue ?? "";
    const current = currentValue === undefined ? loaded : currentValue ?? "";
    if (normalizeText(typed) === normalizeText(loaded)) return current;
    if (normalizeText(current) !== normalizeText(loaded)) this.conflict = true;
    return trim ? typed.trim() : typed;
  }

  value(next, loadedValue, currentValue) {
    const current = currentValue === undefined ? loadedValue : currentValue;
    if (stableStringify(next) === stableStringify(loadedValue)) return current;
    if (stableStringify(current) !== stableStringify(loadedValue)) this.conflict = true;
    return next;
  }
}

/// The save sequence every editor uses: validate, ask about conflicts, write,
/// report. `build` returns { payload, merger }, or null after reporting a
/// validation error itself.
export async function guardedSave({ ctx, build, button }) {
  if (!ctx.canWrite()) {
    toast(t("readOnly"), "error");
    return false;
  }
  const built = build();
  if (!built) return false;
  const { payload, merger } = built;
  if (merger && merger.conflict) {
    const ok = await confirmDialog({ message: t("overwriteConfirm"), okLabel: t("overwrite"), danger: true });
    if (!ok) return false;
  }
  const label = button ? button.textContent : null;
  if (button) {
    button.disabled = true;
    button.textContent = "…";
  }
  try {
    await ctx.merge(payload);
    toast(t("adminSaveSuccess"));
    return true;
  } catch (e) {
    toast(t("adminSaveError", { error: errorText(e) }), "error");
    return false;
  } finally {
    if (button) {
      button.disabled = !ctx.canWrite();
      button.textContent = label;
    }
  }
}

/// IDs become Firestore map keys and appear in code and logs. The app accepts
/// anything - including an existing id, which "adds" a blank item over it and
/// wipes its content. Here a new id must be new and plain.
export function validateNewKey(value, ...existingMaps) {
  if (!value) return t("keyEmpty");
  if (!/^[A-Za-z0-9_-]+$/.test(value)) return t("keyInvalid");
  if (existingMaps.some((m) => m && Object.prototype.hasOwnProperty.call(m, value))) return t("keyExists");
  return null;
}

/// Banner shown above a form whose data changed elsewhere while it had edits.
export function staleBanner(onReload) {
  return h(
    "div",
    { class: "banner warn" },
    h("span", {}, t("changedElsewhere")),
    h("button", { class: "small secondary", type: "button", onClick: onReload }, t("reloadLatest")),
  );
}

export function saveButton(ctx, onClick) {
  return h("button", { class: "save", type: "button", disabled: !ctx.canWrite(), onClick }, t("adminSave"));
}

const TRASH_PATH =
  "M9 3h6l1 2h4v2H4V5h4l1-2zm-3 6h12l-1 12H7L6 9zm4 2v8h2v-8h-2zm4 0v8h2v-8h-2z";

export function trashIcon() {
  const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  svg.setAttribute("viewBox", "0 0 24 24");
  svg.setAttribute("aria-hidden", "true");
  const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
  path.setAttribute("d", TRASH_PATH);
  svg.append(path);
  return svg;
}
