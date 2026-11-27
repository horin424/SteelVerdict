import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { AiSettingsDeps, handleCheckAiModel, handleGetAiSettings, handleSetAiApiKey } from "./aiSettings";
import { forgetAiKey, secretStore } from "./apiKey";
import { listModels, tryModel } from "./providers";
import { emulatorProviders, isEmulator } from "./emulatorFakes";

/** An account listed in system_config/admin_uids: the same list firestore.rules checks. */
async function isAdminUid(uid: string): Promise<boolean> {
  const snap = await admin.firestore().collection("system_config").doc("admin_uids").get();
  const uids = snap.exists ? snap.get("uids") : null;
  return Array.isArray(uids) && uids.includes(uid);
}

function deps(): AiSettingsDeps {
  const providers = isEmulator() ? emulatorProviders : { tryModel, listModels };
  return {
    isAdmin: isAdminUid,
    store: secretStore(),
    modelConfig: async () => {
      const snap = await admin.firestore().collection("system_config").doc("game_config").get();
      return snap.exists ? snap.get("model_config") : undefined;
    },
    tryModel: (provider, key, model) => providers.tryModel(provider, key, model),
    listModels: (provider, key) => providers.listModels(provider, key),
    keySaved: forgetAiKey,
    log: (line) => console.log(line),
  };
}

// No `secrets:` here: these read and write the key secrets through Secret
// Manager's API, as the runtime account (see secretStore.ts).
const OPTIONS = { timeoutSeconds: 60 };

/** The PC admin's 「APIキー」 section: each key's last 4 characters, when it was saved, the models it can use. */
export const getAiSettings = onCall(OPTIONS, (request) => handleGetAiSettings(deps(), request.auth?.uid));

/** Saves a new API key (checked first with a tiny real call). The key takes effect within a minute. */
export const setAiApiKey = onCall(OPTIONS, (request) => handleSetAiApiKey(deps(), request.auth?.uid, request.data));

/** Checks one model name with the key in use, before the PC admin saves it. */
export const checkAiModel = onCall(OPTIONS, (request) => handleCheckAiModel(deps(), request.auth?.uid, request.data));
