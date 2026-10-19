// Small DOM helpers shared by the editors: element builder, toast, dialogs.
import { t } from "./i18n.js";

/// h("div", { class: "x", onClick: fn }, child, "text", ...)
export function h(tag, attrs, ...children) {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs || {})) {
    if (v === undefined || v === null || v === false) continue;
    if (k === "class") el.className = v;
    else if (k === "value" || k === "checked") el[k] = v;
    else if (k.startsWith("on") && typeof v === "function") el.addEventListener(k.slice(2).toLowerCase(), v);
    else el.setAttribute(k, v === true ? "" : v);
  }
  for (const c of children.flat(Infinity)) {
    if (c === null || c === undefined || c === false) continue;
    el.append(c instanceof Node ? c : String(c));
  }
  return el;
}

/// el.replaceChildren(...) that skips null/false the way h() does.
/// replaceChildren itself would print a null as the text "null".
export function fill(el, ...children) {
  el.replaceChildren(...children.flat(Infinity).filter((c) => c !== null && c !== undefined && c !== false));
}

let toastTimer = null;

/// Short status message, like the app's ErrorSnackbar. Errors stay longer and
/// close on click.
export function toast(message, kind = "success") {
  const el = document.getElementById("toast");
  el.textContent = message;
  el.className = `toast ${kind}`;
  el.onclick = () => el.classList.add("hidden");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => el.classList.add("hidden"), kind === "error" ? 12000 : 3500);
}

/// Shows a modal built by `build(done, dialog)` and resolves with what is passed
/// to `done`. Escape resolves null, except while `dialog.dataset.busy` is set
/// (a request in flight, whose outcome the dialog still has to report).
export function openDialog(build) {
  return new Promise((resolve) => {
    const dialog = h("dialog", { class: "dialog" });
    const done = (value) => {
      dialog.close();
      dialog.remove();
      resolve(value);
    };
    dialog.append(...build(done, dialog).filter(Boolean));
    dialog.addEventListener("cancel", (e) => {
      e.preventDefault();
      if (dialog.dataset.busy) return;
      done(null);
    });
    document.body.append(dialog);
    dialog.showModal();
  });
}

/// Resolves true when confirmed.
export async function confirmDialog({ title, message, okLabel, danger = false }) {
  const result = await openDialog((done) => [
    title ? h("h2", {}, title) : null,
    h("p", {}, message),
    h(
      "div",
      { class: "dialog-actions" },
      h("button", { class: "secondary", type: "button", onClick: () => done(false) }, t("cancel")),
      h(
        "button",
        { class: danger ? "danger" : "", type: "button", autofocus: true, onClick: () => done(true) },
        okLabel,
      ),
    ),
  ]);
  return result === true;
}

/// Resolves to the trimmed text, or null when cancelled. `validate` returns an
/// error message to keep the dialog open, or null to accept.
export function promptDialog({ title, placeholder, okLabel, validate }) {
  return openDialog((done) => {
    const input = h("input", { type: "text", placeholder, autocomplete: "off", spellcheck: "false" });
    const error = h("p", { class: "field-error", role: "alert" });
    const submit = () => {
      const value = input.value.trim();
      const message = validate ? validate(value) : null;
      if (message) {
        error.textContent = message;
        input.focus();
        return;
      }
      done(value);
    };
    input.addEventListener("keydown", (e) => {
      if (e.key === "Enter") submit();
    });
    setTimeout(() => input.focus(), 0);
    return [
      h("h2", {}, title),
      input,
      error,
      h(
        "div",
        { class: "dialog-actions" },
        h("button", { class: "secondary", type: "button", onClick: () => done(null) }, t("cancel")),
        h("button", { type: "button", onClick: submit }, okLabel),
      ),
    ];
  });
}

/// Parses a whole number the way the admin means it, rejecting what the app
/// silently turned into 0 or 1 (`int.tryParse(text) ?? 0`). Returns
/// { value } or { error }.
export function parseWholeNumber(text, field, { min = null, max = null } = {}) {
  const s = String(text ?? "").trim();
  const fail = () => ({
    error:
      min !== null && max !== null
        ? t("wholeNumberRange", { field, min, max })
        : min !== null
          ? t("wholeNumberMin", { field, min })
          : t("wholeNumber", { field }),
  });
  if (!/^[+-]?\d+$/.test(s)) return fail();
  const value = parseInt(s, 10);
  if ((min !== null && value < min) || (max !== null && value > max)) return fail();
  return { value };
}

/// A labelled text field. Returns { el, input }.
export function field({ label, value = "", rows = 0, mono = false, counter = false, hint = null }) {
  const input = rows
    ? h("textarea", { rows, class: mono ? "mono" : null, spellcheck: "false" })
    : h("input", { type: "text", spellcheck: "false" });
  input.value = value ?? "";
  const count = counter ? h("span", { class: "counter" }) : null;
  const updateCount = () => {
    if (count) count.textContent = t("characters", { n: input.value.length.toLocaleString() });
  };
  input.addEventListener("input", updateCount);
  updateCount();
  const el = h(
    "label",
    { class: "field" },
    h("span", { class: "field-label" }, label, count),
    input,
    hint ? h("span", { class: "field-hint" }, hint) : null,
  );
  return { el, input, refreshCount: updateCount };
}

/// The info banner both prompt editors in the app show.
export function englishOnlyNote() {
  return h("p", { class: "note" }, t("adminPromptEnglishOnly"));
}

/// Firebase errors carry a code; show it with the message.
export function errorText(e) {
  return e && e.code ? `${e.code} — ${e.message}` : String(e && e.message ? e.message : e);
}
