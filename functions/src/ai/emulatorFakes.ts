import * as admin from "firebase-admin";
import { AiProvider, SECRET_NAMES, SecretStore } from "./keys";
import { CheckResult, ModelList } from "./providers";

/**
 * Stand-ins used only in the Firebase emulator (FUNCTIONS_EMULATOR=true), so
 * the PC admin's 「APIキー」 section can be tried on a local machine: there is
 * no Secret Manager there, and no real call goes to the AI companies.
 *
 * - The made-up keys live in the Firestore emulator (emulator_secrets), since
 *   the emulator runs each function in its own process. Each starts as a value
 *   ending in 0000.
 * - A key that contains "invalid" is refused as a wrong key; "nocredit", as a
 *   key without credit.
 * - A model name that contains "missing" is refused as unknown.
 */
export function isEmulator(): boolean {
  return process.env.FUNCTIONS_EMULATOR === "true";
}

const COLLECTION = "emulator_secrets";
const SEEDED_AT = "2026-11-01T00:00:00Z";

interface FakeVersion {
  value: string;
  createTime: string;
}

// Built at run time, so no key-shaped text sits in the source.
function seed(secret: string): FakeVersion[] {
  const value = secret === SECRET_NAMES.gemini
    ? "AI" + "za" + "E".repeat(31) + "0000"
    : "sk-" + "ant-" + "e".repeat(40) + "0000";
  return [{ value, createTime: SEEDED_AT }];
}

function storedVersions(snap: admin.firestore.DocumentSnapshot, secret: string): FakeVersion[] {
  const v = snap.exists ? snap.get("versions") : null;
  return Array.isArray(v) && v.length > 0 ? (v as FakeVersion[]) : seed(secret);
}

export function emulatorSecretStore(): SecretStore {
  const ref = (secret: string) => admin.firestore().collection(COLLECTION).doc(secret);
  const versions = async (secret: string) => storedVersions(await ref(secret).get(), secret);
  return {
    async accessLatest(secret) {
      const v = await versions(secret);
      return { value: v[v.length - 1].value, version: String(v.length) };
    },
    async addVersion(secret, value) {
      return admin.firestore().runTransaction(async (tx) => {
        const v = storedVersions(await tx.get(ref(secret)), secret);
        const createTime = new Date().toISOString();
        tx.set(ref(secret), { versions: [...v, { value, createTime }] });
        return { version: String(v.length + 1), createTime };
      });
    },
    async getVersion(secret, version) {
      const found = (await versions(secret))[Number(version) - 1];
      if (!found) throw new Error(`NOT_FOUND: version ${version}`);
      return { createTime: found.createTime, state: "ENABLED" };
    },
    async testPermissions(_secret, permissions) {
      return permissions;
    },
  };
}

export const emulatorProviders = {
  async tryModel(_provider: AiProvider, key: string, model: string): Promise<CheckResult> {
    if (key.includes("invalid")) return { ok: false, reason: "invalid_key", status: 400 };
    if (key.includes("nocredit")) return { ok: false, reason: "no_credit", status: 400 };
    if (model.includes("missing")) return { ok: false, reason: "model_not_found", status: 404 };
    return { ok: true };
  },
  async listModels(provider: AiProvider, _key: string): Promise<ModelList> {
    return provider === "gemini"
      ? { models: ["gemini-2.5-flash", "gemini-2.5-flash-lite", "gemini-2.5-pro"] }
      : { models: ["claude-haiku-4-5-20251001", "claude-sonnet-4-5-20250929"] };
  },
};
