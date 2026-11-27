import { CLAUDE_API_KEY, GEMINI_API_KEY } from "../utils/config";
import { AiProvider, SecretStore, makeKeyReader } from "./keys";
import { restSecretStore } from "./secretStore";
import { emulatorSecretStore, isEmulator } from "./emulatorFakes";

let store: SecretStore | null = null;

/** This server's Secret Manager; a stand-in in the emulator (emulatorFakes.ts). */
export function secretStore(): SecretStore {
  if (!store) store = isEmulator() ? emulatorSecretStore() : restSecretStore();
  return store;
}

const reader = makeKeyReader(secretStore);

/** The key bound at deploy (`secrets: [...]` on the calling function). */
function deployedKey(provider: AiProvider): string {
  return (provider === "gemini" ? GEMINI_API_KEY : CLAUDE_API_KEY).value();
}

/**
 * The API key an AI call uses now. On Cloud Functions: the newest version in
 * Secret Manager, read at most a minute ago (a key saved in the PC admin is in
 * use within a minute), or the deployed key if Secret Manager can't be read.
 * Anywhere else (the emulator, the offline tests): the deployed key, as before.
 */
export function aiKey(provider: AiProvider): Promise<string> {
  const onCloud = !!process.env.K_SERVICE && !isEmulator();
  if (!onCloud) return Promise.resolve().then(() => deployedKey(provider));
  return reader.read(provider, () => deployedKey(provider));
}

/** After a new key is saved: this instance reads it at its next AI call. Others within a minute. */
export function forgetAiKey(provider: AiProvider): void {
  reader.forget(provider);
}
