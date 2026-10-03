// Firebase setup for the PC admin page.
//
// The SDK is loaded from Google's CDN, as in the first version of this page, so
// there is no build step: Firebase Hosting serves this folder as it is.
import { initializeApp } from "https://www.gstatic.com/firebasejs/11.0.2/firebase-app.js";
import {
  getAuth,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
} from "https://www.gstatic.com/firebasejs/11.0.2/firebase-auth.js";
import {
  getFirestore,
  doc,
  onSnapshot,
  setDoc,
  updateDoc,
  deleteField,
  FieldPath,
} from "https://www.gstatic.com/firebasejs/11.0.2/firebase-firestore.js";

export {
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
  doc,
  onSnapshot,
  setDoc,
  updateDoc,
  deleteField,
  FieldPath,
};

export const LIVE_PROJECT_ID = "steelverdict-81c34";

// Same key as the first version of this page, so a config pasted there still
// works after the update.
const CONFIG_KEY = "sv_admin_firebase_config";

/// Finds the Firebase web config.
///
/// On Firebase Hosting, /__/firebase/init.json returns the hosting project's own
/// config. The same files therefore serve the test project and the live one, and
/// the client has nothing to paste. Elsewhere (local development) it falls back
/// to a config saved from the setup form.
export async function resolveConfig() {
  try {
    const res = await fetch("/__/firebase/init.json", { cache: "no-store" });
    if (res.ok) return { config: await res.json(), source: "hosting" };
  } catch (_) {
    // Not on Firebase Hosting.
  }
  try {
    const saved = localStorage.getItem(CONFIG_KEY);
    if (saved) return { config: JSON.parse(saved), source: "saved" };
  } catch (_) {
    // Storage blocked or the saved value is unreadable: ask again.
  }
  return null;
}

export function saveConfig(config) {
  try {
    localStorage.setItem(CONFIG_KEY, JSON.stringify(config));
  } catch (_) {
    // Storage blocked: the page still works until it is reloaded.
  }
}

export function forgetConfig() {
  try {
    localStorage.removeItem(CONFIG_KEY);
  } catch (_) {
    // Nothing saved.
  }
}

export function initFirebase(config) {
  const app = initializeApp(config);
  const db = getFirestore(app);
  return {
    auth: getAuth(app),
    db,
    projectId: config.projectId,
    configRef: doc(db, "system_config", "game_config"),
    adminUidsRef: doc(db, "system_config", "admin_uids"),
  };
}
