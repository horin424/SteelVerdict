import { AiProvider, SECRET_NAMES, SecretStore } from "./keys";
import { CheckResult, ModelList } from "./providers";

/**
 * Stand-ins used only in the Firebase emulator (FUNCTIONS_EMULATOR=true), so
 * the PC admin's 「APIキー」 section can be tried on a local machine: there is
 * no Secret Manager there, and no real call goes to the AI companies.
 *
 * - Each key starts as a made-up value ending in 0000.
 * - A key that contains "invalid" is refused as a wrong key; "nocredit", as a
 *   key without credit.
 * - A model name that contains "missing" is refused as unknown.
 */
export function isEmulator(): boolean {
  return process.env.FUNCTIONS_EMULATOR === "true";
}

export function emulatorSecretStore(): SecretStore {
  // Built at run time, so no key-shaped text sits in the source.
  const versions = new Map<string, { value: string; createTime: string }[]>([
    [SECRET_NAMES.gemini, [{ value: "AI" + "za" + "E".repeat(31) + "0000", createTime: "2026-11-01T00:00:00Z" }]],
    [SECRET_NAMES.claude, [{ value: "sk-" + "ant-" + "e".repeat(40) + "0000", createTime: "2026-11-01T00:00:00Z" }]],
  ]);
  const list = (secret: string) => {
    const v = versions.get(secret);
    if (!v) throw new Error(`NOT_FOUND: secret ${secret}`);
    return v;
  };
  return {
    async accessLatest(secret) {
      const v = list(secret);
      return { value: v[v.length - 1].value, version: String(v.length) };
    },
    async addVersion(secret, value) {
      const v = list(secret);
      v.push({ value, createTime: new Date().toISOString() });
      return { version: String(v.length), createTime: v[v.length - 1].createTime };
    },
    async getVersion(secret, version) {
      const found = list(secret)[Number(version) - 1];
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
