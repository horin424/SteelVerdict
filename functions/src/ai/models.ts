import { CLAUDE_HAIKU, GEMINI_FLASH, GEMINI_FLASH_LITE } from "../utils/config";
import { AiProvider } from "./keys";

/**
 * The models the admin can choose (system_config/game_config.model_config):
 * which company's key each one uses, and the model used while none is set.
 * The PC admin's 「コスト＆モデル」 page lists the same keys (admin-web/js/editors/costs.js).
 */
export const MODEL_KEYS = {
  /** The player's Claude choice (submitBattle). */
  claude: { provider: "claude", fallback: CLAUDE_HAIKU },
  /** 戦史, the war chronicle (generateWarHistory). Fixed in the code until 27 Nov 2026. */
  war_history: { provider: "claude", fallback: CLAUDE_HAIKU },
  /** normal, epic, boss, history_puzzle (submitBattle). */
  gemini_flash: { provider: "gemini", fallback: GEMINI_FLASH },
  /** practice, tabletop (submitBattle). */
  gemini_flash_lite: { provider: "gemini", fallback: GEMINI_FLASH_LITE },
  /** The PvP judge, the same model for both players (judgePvpMatch). Fixed in the code until 27 Nov 2026. */
  pvp_judge: { provider: "gemini", fallback: GEMINI_FLASH },
} as const satisfies Record<string, { provider: AiProvider; fallback: string }>;

export type ModelKey = keyof typeof MODEL_KEYS;
export const MODEL_KEY_NAMES = Object.keys(MODEL_KEYS) as ModelKey[];

/** The model to use for [key]: the admin's setting, or the default when it is missing or blank. */
export function configuredModel(modelConfig: unknown, key: ModelKey): string {
  const stored = isMap(modelConfig) ? modelConfig[key] : undefined;
  return typeof stored === "string" && stored.trim() !== "" ? stored.trim() : MODEL_KEYS[key].fallback;
}

/** Every model one company's key serves now, once each: a new key is checked against all of them. */
export function modelsOfProvider(modelConfig: unknown, provider: AiProvider): string[] {
  const models = MODEL_KEY_NAMES
    .filter((k) => MODEL_KEYS[k].provider === provider)
    .map((k) => configuredModel(modelConfig, k));
  return [...new Set(models)];
}

// A model id as the companies write them: "gemini-2.5-flash", "claude-haiku-4-5-20251001".
const MODEL_NAME = /^[A-Za-z0-9][A-Za-z0-9._-]{0,99}$/;

/** A model name the admin typed, trimmed and without Google's "models/" prefix; or a refusal. */
export function checkModelName(raw: unknown): { model: string } | { refusal: "invalid_model" } {
  if (typeof raw !== "string") return { refusal: "invalid_model" };
  const model = raw.trim().replace(/^models\//, "");
  return MODEL_NAME.test(model) ? { model } : { refusal: "invalid_model" };
}

function isMap(v: unknown): v is Record<string, unknown> {
  return v !== null && typeof v === "object" && !Array.isArray(v);
}
