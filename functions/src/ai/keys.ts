/**
 * The AI API keys (Gemini, Claude): where they live, what a key looks like, and
 * the reader the AI calls use at run time.
 *
 * The keys are Secret Manager secrets. Until 27 Nov 2026 the functions read them
 * only through their deploy-time binding (`secrets: [...]`), which Firebase pins
 * to the version that was current at deploy, so a new key needed a redeploy. Now
 * the PC admin saves a new key as a new version of the same secret
 * (src/ai/aiSettings.ts), and the AI calls read the newest version at run time
 * through makeKeyReader, cached for a minute per server instance. The bound
 * value stays as the fallback for when Secret Manager can't be read.
 *
 * Pure: no Firebase or Google imports, so scripts/verify-ai-keys.js runs it
 * offline with a fake store.
 */

export type AiProvider = "gemini" | "claude";
export const AI_PROVIDERS: readonly AiProvider[] = ["gemini", "claude"];

/** The Secret Manager secret that holds each provider's key (src/utils/config.ts). */
export const SECRET_NAMES: Readonly<Record<AiProvider, string>> = {
  gemini: "GEMINI_API_KEY",
  claude: "CLAUDE_API_KEY",
};

export function isAiProvider(v: unknown): v is AiProvider {
  return v === "gemini" || v === "claude";
}

/** What the functions need from Secret Manager: REST in production (secretStore.ts), a fake in tests. */
export interface SecretStore {
  /** The newest version: its value and its id ("8"). */
  accessLatest(secret: string): Promise<{ value: string; version: string }>;
  /** Adds a version holding this value; returns its id and when it was created. */
  addVersion(secret: string, value: string): Promise<{ version: string; createTime: string }>;
  /** One version's creation time and state (ENABLED, DISABLED, DESTROYED). */
  getVersion(secret: string, version: string): Promise<{ createTime: string; state: string }>;
  /** Which of these permissions this server holds on the secret. */
  testPermissions(secret: string, permissions: string[]): Promise<string[]>;
}

// Google AI Studio keys are "AIza" and 35 more characters. Anthropic keys are
// "sk-ant-" and the rest (today "sk-ant-api03-…", about 108 characters).
const KEY_PATTERNS: Readonly<Record<AiProvider, RegExp>> = {
  gemini: /^AIza[0-9A-Za-z_-]{35}$/,
  claude: /^sk-ant-[0-9A-Za-z_-]{20,300}$/,
};

export type KeyFormatRefusal = "empty_key" | "invalid_key_format";

/** A pasted key, trimmed, or why it can't be a key of this provider. */
export function checkKeyFormat(provider: AiProvider, raw: unknown): { key: string } | { refusal: KeyFormatRefusal } {
  if (typeof raw !== "string" || raw.trim() === "") return { refusal: "empty_key" };
  const key = raw.trim();
  return KEY_PATTERNS[provider].test(key) ? { key } : { refusal: "invalid_key_format" };
}

/** The last 4 characters: the only part of a key the admin page ever shows. Nothing for a short value. */
export function lastFour(key: string): string {
  return key.length >= 12 ? key.slice(-4) : "";
}

/**
 * An error described for the logs. Secret Manager and the AI companies never
 * echo a key back in their errors, and our own errors don't hold one either.
 */
export function describe(err: unknown): string {
  const e = err as { response?: { status?: unknown }; code?: unknown; message?: unknown } | null;
  const status = e?.response?.status ?? e?.code;
  const message = typeof e?.message === "string" ? e.message : String(err);
  return `${status !== undefined ? `${String(status)} ` : ""}${message}`.substring(0, 200);
}

export interface KeyReader {
  /** The key to use now: the newest saved version, at most ttl old; else the last one read; else fallback(). */
  read(provider: AiProvider, fallback: () => string): Promise<string>;
  /** Drops the cached key, so the next read goes to Secret Manager (right after a new key is saved). */
  forget(provider?: AiProvider): void;
}

/** How long a server instance keeps a key before it reads Secret Manager again. */
export const KEY_CACHE_MS = 60 * 1000;

interface Cached {
  value: string;
  at: number;
  /** The Secret Manager version, or "deployed" for the bound value. */
  version: string;
}

export function makeKeyReader(
  store: () => SecretStore,
  options: { ttlMs?: number; now?: () => number; log?: (line: string) => void } = {},
): KeyReader {
  const ttl = options.ttlMs ?? KEY_CACHE_MS;
  const now = options.now ?? (() => Date.now());
  const log = options.log ?? ((line: string) => console.log(line));
  const cache = new Map<AiProvider, Cached>();
  // One Secret Manager read at a time per provider, however many calls arrive.
  const pending = new Map<AiProvider, Promise<string>>();

  async function load(provider: AiProvider, fallback: () => string, previous: Cached | undefined): Promise<string> {
    const at = now();
    try {
      const latest = await store().accessLatest(SECRET_NAMES[provider]);
      const value = latest.value.trim();
      if (!value) throw new Error("the newest version is empty");
      if (previous?.version !== latest.version) {
        log(`[aiKey] ${provider}: using Secret Manager version ${latest.version}`);
      }
      cache.set(provider, { value, at, version: latest.version });
      return value;
    } catch (err) {
      // Keep the AI working: the key read before, else the one bound at deploy.
      const value = previous?.value || safeCall(fallback);
      if (!value) {
        throw new Error(`No ${provider} API key: Secret Manager not readable (${describe(err)}), no deployed key.`);
      }
      log(`[aiKey] ${provider}: Secret Manager not readable (${describe(err)}); ` +
        `using the ${previous ? "key read before" : "deployed key"}`);
      // Cached as well, so a failing Secret Manager is tried again only after ttl.
      cache.set(provider, { value, at, version: previous?.version ?? "deployed" });
      return value;
    }
  }

  return {
    read(provider, fallback) {
      const hit = cache.get(provider);
      if (hit && now() - hit.at < ttl) return Promise.resolve(hit.value);
      const inFlight = pending.get(provider);
      if (inFlight) return inFlight;
      const p = (async () => {
        try {
          return await load(provider, fallback, hit);
        } finally {
          pending.delete(provider);
        }
      })();
      pending.set(provider, p);
      return p;
    },
    forget(provider) {
      if (provider) cache.delete(provider);
      else cache.clear();
    },
  };
}

function safeCall(fallback: () => string): string {
  try {
    const v = fallback();
    return typeof v === "string" ? v.trim() : "";
  } catch (_) {
    return "";
  }
}
