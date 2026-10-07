// The admin's own login: change the password while signed in, or get a reset
// email from the sign-in screen. The in-app panel has neither; admins there use
// the app's own account screens.
import {
  EmailAuthProvider,
  reauthenticateWithCredential,
  sendPasswordResetEmail,
  updatePassword,
} from "./firebase.js";
import { getLang, t } from "./i18n.js";
import { errorText, h, openDialog, toast } from "./ui.js";

/// Firebase's own minimum. A password policy set on the project can ask for
/// more; Firebase's message then says what is missing.
const MIN_LENGTH = 6;

/// What Firebase answers to a wrong password, by SDK version and project
/// settings.
const WRONG_PASSWORD = ["auth/wrong-password", "auth/invalid-credential", "auth/invalid-login-credentials"];

function authError(err) {
  if (err && WRONG_PASSWORD.includes(err.code)) return t("passwordWrongCurrent");
  switch (err && err.code) {
    case "auth/weak-password":
      return t("passwordTooShort", { n: MIN_LENGTH });
    case "auth/password-does-not-meet-requirements":
      return t("passwordPolicy", { error: err.message });
    case "auth/invalid-email":
      return t("emailInvalid");
    case "auth/too-many-requests":
      return t("tooManyAttempts");
    case "auth/network-request-failed":
      return t("networkError");
    default:
      return errorText(err);
  }
}

function passwordField(label, autocomplete, autofocus = false) {
  // autofocus: showModal() would otherwise focus the first focusable field,
  // the hidden username one.
  const input = h("input", { type: "password", autocomplete, spellcheck: "false", autofocus });
  return { input, el: h("label", { class: "field" }, h("span", { class: "field-label" }, label), input) };
}

/// Change the signed-in user's password. Firebase asks for a recent sign-in
/// before a password change, so the current password is checked first; that
/// also stops anyone using a session left open on a shared PC.
export function changePassword(auth) {
  const user = auth.currentUser;
  if (!user || !user.email) return Promise.resolve(false);
  return openDialog((done, dialog) => {
    const current = passwordField(t("passwordCurrent"), "current-password", true);
    const next = passwordField(t("passwordNew"), "new-password");
    const again = passwordField(t("passwordConfirm"), "new-password");
    const error = h("p", { class: "field-error", role: "alert" });
    const cancel = h("button", { class: "secondary", type: "button", onClick: () => done(false) }, t("cancel"));
    const submit = h("button", { type: "submit" }, t("passwordChange"));

    const fail = (message, input) => {
      error.textContent = message;
      if (input) input.focus();
    };

    const form = h(
      "form",
      {
        class: "dialog-form",
        novalidate: true,
        onSubmit: async (e) => {
          e.preventDefault();
          error.textContent = "";
          if (!current.input.value) return fail(t("passwordCurrentEmpty"), current.input);
          if (next.input.value.length < MIN_LENGTH) return fail(t("passwordTooShort", { n: MIN_LENGTH }), next.input);
          if (next.input.value === current.input.value) return fail(t("passwordSame"), next.input);
          if (next.input.value !== again.input.value) return fail(t("passwordMismatch"), again.input);
          dialog.dataset.busy = "1";
          submit.disabled = cancel.disabled = true;
          try {
            await reauthenticateWithCredential(
              user,
              EmailAuthProvider.credential(user.email, current.input.value),
            );
            await updatePassword(user, next.input.value);
            delete dialog.dataset.busy;
            done(true);
            toast(t("passwordChanged"));
          } catch (err) {
            delete dialog.dataset.busy;
            submit.disabled = cancel.disabled = false;
            fail(authError(err), WRONG_PASSWORD.includes(err && err.code) ? current.input : next.input);
          }
        },
      },
      // Lets a password manager file the new password under this account.
      h("input", {
        type: "email",
        autocomplete: "username",
        value: user.email,
        readonly: true,
        tabindex: "-1",
        "aria-hidden": "true",
        class: "visually-hidden",
      }),
      current.el,
      next.el,
      again.el,
      h("p", { class: "field-hint" }, t("passwordRule", { n: MIN_LENGTH })),
      error,
      h("div", { class: "dialog-actions" }, cancel, submit),
    );
    return [h("h2", {}, t("passwordChangeTitle")), h("p", { class: "dialog-sub" }, user.email), form];
  });
}

/// Sign-in failures in words: a wrong password and an unknown address get the
/// same message, as Firebase itself no longer tells them apart.
export function signInError(err) {
  if (err && (WRONG_PASSWORD.includes(err.code) || err.code === "auth/user-not-found")) return t("signInWrong");
  if (err && ["auth/invalid-email", "auth/too-many-requests", "auth/network-request-failed"].includes(err.code)) {
    return authError(err);
  }
  return t("signInFailed", { error: errorText(err) });
}

/// Sends Firebase's password-reset email in the page's language. With email
/// enumeration protection on (the default for new projects), Firebase answers
/// the same whether or not the address has an account, so the message does too.
export async function sendReset(auth, email) {
  auth.languageCode = getLang();
  try {
    await sendPasswordResetEmail(auth, email);
    return { ok: t("resetSent", { email }) };
  } catch (err) {
    return { error: authError(err) };
  }
}
