import { AiProvider } from "./keys";

/**
 * The AI companies, as the PC admin needs them: one tiny real call to check a
 * key and a model before they are saved, and the list of models a key can use
 * (suggestions on the page).
 *
 * The tiny call asks for at most 16 output tokens, a fraction of a yen. A model
 * list would also answer for a key that has no credit left; only a real call
 * shows that the key can actually run the model.
 *
 * fetch is a parameter so scripts/verify-ai-keys.js runs this offline.
 */

export type CheckRefusal =
  | "invalid_key" // the company doesn't accept the key (wrong, deleted, or not allowed to use the API)
  | "no_credit" // the key's account has no credit or billing for this
  | "model_not_found" // no such model for this key (a typo, or the model was retired)
  | "rate_limited" // the key's usage limit for now is reached
  | "provider_error" // anything else the company answered
  | "network"; // no answer

export type CheckResult = { ok: true } | { ok: false; reason: CheckRefusal; status?: number };
export type ModelList = { models: string[] } | { refusal: CheckRefusal };
export type Fetch = (url: string, init?: RequestInit) => Promise<Response>;

const GEMINI_API = "https://generativelanguage.googleapis.com/v1beta";
const ANTHROPIC_API = "https://api.anthropic.com/v1";
const ANTHROPIC_VERSION = "2023-06-01";
const TIMEOUT_MS = 20 * 1000;
const PROBE_TOKENS = 16;
const PROBE_TEXT = "Reply with OK.";

/** One tiny real call with this key and model. The key goes in a header, never in the URL. */
export async function tryModel(
  provider: AiProvider, key: string, model: string, fetchFn: Fetch = fetch,
): Promise<CheckResult> {
  let res: Response;
  try {
    res = provider === "gemini"
      ? await fetchFn(`${GEMINI_API}/models/${encodeURIComponent(model)}:generateContent`, {
        method: "POST",
        headers: { "content-type": "application/json", "x-goog-api-key": key },
        body: JSON.stringify({
          contents: [{ role: "user", parts: [{ text: PROBE_TEXT }] }],
          generationConfig: { maxOutputTokens: PROBE_TOKENS },
        }),
        signal: AbortSignal.timeout(TIMEOUT_MS),
      })
      : await fetchFn(`${ANTHROPIC_API}/messages`, {
        method: "POST",
        headers: { "content-type": "application/json", "x-api-key": key, "anthropic-version": ANTHROPIC_VERSION },
        body: JSON.stringify({
          model,
          max_tokens: PROBE_TOKENS,
          messages: [{ role: "user", content: PROBE_TEXT }],
        }),
        signal: AbortSignal.timeout(TIMEOUT_MS),
      });
  } catch (_) {
    return { ok: false, reason: "network" };
  }
  if (res.ok) return { ok: true };
  const error = await readError(res);
  const reason = provider === "gemini" ? geminiRefusal(res.status, error) : claudeRefusal(res.status, error);
  return { ok: false, reason, status: res.status };
}

/** The models this key can use for text, sorted: suggestions for the admin's model fields. */
export async function listModels(provider: AiProvider, key: string, fetchFn: Fetch = fetch): Promise<ModelList> {
  let res: Response;
  try {
    res = provider === "gemini"
      ? await fetchFn(`${GEMINI_API}/models?pageSize=1000`, {
        headers: { "x-goog-api-key": key },
        signal: AbortSignal.timeout(TIMEOUT_MS),
      })
      : await fetchFn(`${ANTHROPIC_API}/models?limit=1000`, {
        headers: { "x-api-key": key, "anthropic-version": ANTHROPIC_VERSION },
        signal: AbortSignal.timeout(TIMEOUT_MS),
      });
    if (!res.ok) {
      const error = await readError(res);
      return { refusal: provider === "gemini" ? geminiRefusal(res.status, error) : claudeRefusal(res.status, error) };
    }
    const body: unknown = await res.json();
    return { models: provider === "gemini" ? geminiModelIds(body) : claudeModelIds(body) };
  } catch (_) {
    return { refusal: "network" };
  }
}

/** Gemini's list: the models that can write text (generateContent), without the "models/" prefix. */
export function geminiModelIds(body: unknown): string[] {
  const models = (body as { models?: unknown })?.models;
  if (!Array.isArray(models)) return [];
  const ids = models
    .filter((m) => Array.isArray(m?.supportedGenerationMethods) && m.supportedGenerationMethods.includes("generateContent"))
    .map((m) => (typeof m?.name === "string" ? m.name.replace(/^models\//, "") : ""))
    .filter((id) => id.startsWith("gemini"));
  return [...new Set(ids)].sort();
}

/** Anthropic's list: the model ids. */
export function claudeModelIds(body: unknown): string[] {
  const data = (body as { data?: unknown })?.data;
  if (!Array.isArray(data)) return [];
  const ids = data.map((m) => (typeof m?.id === "string" ? m.id : "")).filter((id) => id.startsWith("claude"));
  return [...new Set(ids)].sort();
}

export interface ErrorBody {
  /** Anthropic: authentication_error, not_found_error, … */
  type: string;
  /** Google: INVALID_ARGUMENT, PERMISSION_DENIED, … */
  status: string;
  message: string;
  /** Google: details[].reason, e.g. API_KEY_INVALID. */
  reasons: string[];
}

async function readError(res: Response): Promise<ErrorBody> {
  const empty: ErrorBody = { type: "", status: "", message: "", reasons: [] };
  try {
    const json = (await res.json()) as { error?: Record<string, unknown> };
    const e = json?.error ?? {};
    const details = Array.isArray(e.details) ? e.details : [];
    return {
      type: typeof e.type === "string" ? e.type : "",
      status: typeof e.status === "string" ? e.status : "",
      message: typeof e.message === "string" ? e.message.substring(0, 300) : "",
      reasons: details.map((d: { reason?: unknown }) => d?.reason).filter((r): r is string => typeof r === "string"),
    };
  } catch (_) {
    return empty;
  }
}

/** Google's answers: https://ai.google.dev/gemini-api/docs/troubleshooting */
export function geminiRefusal(status: number, e: ErrorBody): CheckRefusal {
  const text = `${e.status} ${e.message} ${e.reasons.join(" ")}`.toLowerCase();
  if (/api_key_invalid|api key not valid|api key expired/.test(text)) return "invalid_key";
  if (status === 401 || status === 403) return "invalid_key";
  if (status === 402 || /billing|credit|prepay/.test(text)) return "no_credit";
  if (status === 404) return "model_not_found";
  if (status === 400 && /model/.test(text) && /not found|unexpected model name|not supported/.test(text)) {
    return "model_not_found";
  }
  if (status === 429) return "rate_limited";
  return "provider_error";
}

/** Anthropic's answers: https://docs.anthropic.com/en/api/errors */
export function claudeRefusal(status: number, e: ErrorBody): CheckRefusal {
  const text = `${e.type} ${e.message}`.toLowerCase();
  if (status === 401 || status === 403 || /authentication_error|permission_error/.test(text)) return "invalid_key";
  if (status === 402 || /credit balance|billing/.test(text)) return "no_credit";
  if (status === 404 || /not_found_error/.test(text)) return "model_not_found";
  if (status === 429) return "rate_limited";
  return "provider_error";
}
