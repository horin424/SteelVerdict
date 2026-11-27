import { HttpsError } from "firebase-functions/v2/https";
import {
  AI_PROVIDERS, AiProvider, SECRET_NAMES, SecretStore, checkKeyFormat, describe, isAiProvider, lastFour,
} from "./keys";
import { CheckRefusal, CheckResult, ModelList } from "./providers";
import { checkModelName, modelsOfProvider } from "./models";

/**
 * The PC admin's AI keys and model checks (client point ②, 26 Nov 2026):
 * - getAiSettings: for each key, its last 4 characters and when it was saved;
 *   whether this server may save keys; the models the key can use.
 * - setAiApiKey: saves a new key as a new Secret Manager version, after a tiny
 *   real call with every model that key serves.
 * - checkAiModel: the same tiny call for one model name, before it is saved.
 *
 * Admins only (system_config/admin_uids). A key is never logged, stored
 * anywhere but Secret Manager, or sent back: only its last 4 characters.
 *
 * The handlers take their dependencies, so scripts/verify-ai-keys.js runs them
 * with fakes; aiSettingsFunctions.ts wires the real ones.
 */
export interface AiSettingsDeps {
  isAdmin(uid: string): Promise<boolean>;
  store: SecretStore;
  /** system_config/game_config.model_config, read now (not the 5-minute cache). */
  modelConfig(): Promise<unknown>;
  tryModel(provider: AiProvider, key: string, model: string): Promise<CheckResult>;
  listModels(provider: AiProvider, key: string): Promise<ModelList>;
  /** A new key was saved: this server instance should use it at once. */
  keySaved(provider: AiProvider): void;
  log(line: string): void;
}

/** What the server needs on each key secret: read it, save a new version, see when a version was made. */
export const KEY_PERMISSIONS = [
  "secretmanager.versions.access",
  "secretmanager.versions.add",
  "secretmanager.versions.get",
];

export interface KeyStatus {
  /** The key's last 4 characters; "" when it can't be read. */
  last4: string;
  /** When the key in use was saved (ISO time); "" when unknown. */
  savedAt: string;
  version: string;
  /** This server may save a new key (secretmanager.versions.add). */
  canSave: boolean;
  /** "unreadable": the key couldn't be read from Secret Manager. */
  error?: "unreadable";
  /** The models this key can use, for suggestions. */
  models?: string[];
  /** Why the model list couldn't be read. */
  modelsError?: CheckRefusal;
}

async function requireAdmin(deps: AiSettingsDeps, uid: string | undefined): Promise<string> {
  if (!uid) throw new HttpsError("unauthenticated", "Authentication required.");
  if (!(await deps.isAdmin(uid))) throw new HttpsError("permission-denied", "NOT_ADMIN");
  return uid;
}

export async function handleGetAiSettings(
  deps: AiSettingsDeps, uid: string | undefined,
): Promise<{ keys: Record<AiProvider, KeyStatus> }> {
  await requireAdmin(deps, uid);
  const [gemini, claude] = await Promise.all(AI_PROVIDERS.map((p) => keyStatus(deps, p)));
  return { keys: { gemini, claude } };
}

async function keyStatus(deps: AiSettingsDeps, provider: AiProvider): Promise<KeyStatus> {
  const secret = SECRET_NAMES[provider];
  let granted: string[] = [];
  try {
    granted = await deps.store.testPermissions(secret, KEY_PERMISSIONS);
  } catch (err) {
    deps.log(`[aiSettings] ${provider}: permissions not readable (${describe(err)})`);
  }
  const canSave = granted.includes("secretmanager.versions.add");

  let latest: { value: string; version: string };
  try {
    latest = await deps.store.accessLatest(secret);
  } catch (err) {
    deps.log(`[aiSettings] ${provider}: key not readable (${describe(err)})`);
    return { last4: "", savedAt: "", version: "", canSave, error: "unreadable" };
  }
  const key = latest.value.trim();
  const savedAt = await savedTime(deps, secret, latest.version);
  const listed = key ? await deps.listModels(provider, key) : { refusal: "invalid_key" as const };
  return {
    last4: lastFour(key),
    savedAt,
    version: latest.version,
    canSave,
    ...("models" in listed ? { models: listed.models } : { modelsError: listed.refusal }),
  };
}

async function savedTime(deps: AiSettingsDeps, secret: string, version: string): Promise<string> {
  try {
    return (await deps.store.getVersion(secret, version)).createTime;
  } catch (_) {
    return "";
  }
}

export interface SetKeyResult {
  provider: AiProvider;
  last4: string;
  savedAt: string;
  version: string;
  /** The key was already the one in use: nothing was saved. */
  unchanged: boolean;
}

export async function handleSetAiApiKey(
  deps: AiSettingsDeps, uid: string | undefined, data: unknown,
): Promise<SetKeyResult> {
  const admin = await requireAdmin(deps, uid);
  const d = (data !== null && typeof data === "object" ? data : {}) as { provider?: unknown; key?: unknown };
  if (!isAiProvider(d.provider)) throw new HttpsError("invalid-argument", "invalid_provider");
  const provider = d.provider;
  const format = checkKeyFormat(provider, d.key);
  if ("refusal" in format) throw new HttpsError("invalid-argument", format.refusal);
  const key = format.key;
  const secret = SECRET_NAMES[provider];

  // Already the key in use: no new version.
  let current: { value: string; version: string } | null = null;
  try {
    current = await deps.store.accessLatest(secret);
  } catch (err) {
    deps.log(`[aiSettings] ${provider}: current key not readable (${describe(err)})`);
  }
  if (current && current.value.trim() === key) {
    return {
      provider, last4: lastFour(key), savedAt: await savedTime(deps, secret, current.version),
      version: current.version, unchanged: true,
    };
  }

  // Every model this key will serve must answer, so a wrong key, one without
  // credit, or one that can't use a model never goes live.
  for (const model of modelsOfProvider(await deps.modelConfig(), provider)) {
    const result = await deps.tryModel(provider, key, model);
    if (!result.ok) {
      throw new HttpsError("failed-precondition", `KEY_CHECK_FAILED:${result.reason}`,
        { reason: result.reason, model, status: result.status ?? null });
    }
  }

  let added: { version: string; createTime: string };
  try {
    added = await deps.store.addVersion(secret, key);
  } catch (err) {
    deps.log(`[aiSettings] ${provider}: the new key could not be saved (${describe(err)})`);
    throw new HttpsError("internal", "KEY_SAVE_FAILED");
  }
  deps.keySaved(provider);
  deps.log(`[aiSettings] ${provider}: new key saved as version ${added.version} by ${admin}`);
  return { provider, last4: lastFour(key), savedAt: added.createTime, version: added.version, unchanged: false };
}

export type ModelCheck =
  | { ok: true; model: string }
  | { ok: false; model: string; reason: CheckRefusal | "key_unreadable" };

export async function handleCheckAiModel(
  deps: AiSettingsDeps, uid: string | undefined, data: unknown,
): Promise<ModelCheck> {
  await requireAdmin(deps, uid);
  const d = (data !== null && typeof data === "object" ? data : {}) as { provider?: unknown; model?: unknown };
  if (!isAiProvider(d.provider)) throw new HttpsError("invalid-argument", "invalid_provider");
  const name = checkModelName(d.model);
  if ("refusal" in name) throw new HttpsError("invalid-argument", name.refusal);

  let key: string;
  try {
    key = (await deps.store.accessLatest(SECRET_NAMES[d.provider])).value.trim();
  } catch (err) {
    deps.log(`[aiSettings] ${d.provider}: key not readable for a model check (${describe(err)})`);
    return { ok: false, model: name.model, reason: "key_unreadable" };
  }
  const result = await deps.tryModel(d.provider, key, name.model);
  return result.ok ? { ok: true, model: name.model } : { ok: false, model: name.model, reason: result.reason };
}
