import { GoogleAuth } from "google-auth-library";
import { SecretStore } from "./keys";

/**
 * Secret Manager over REST, as this server's own account (the functions'
 * runtime service account). google-auth-library is already a dependency, so
 * no new package is needed.
 *
 * The account needs, on each key secret: secretAccessor (Firebase grants it
 * when it binds the secret at deploy), secretVersionAdder (to save a new key)
 * and viewer (to show when a key was saved). See
 * release_scope/12_AI_KEYS_AND_MODELS_PLAN.md.
 *
 * Old versions are never disabled or destroyed here: a deployed revision pins
 * one, and Cloud Run can't start new instances once it is gone.
 */
const API = "https://secretmanager.googleapis.com/v1";

export function restSecretStore(): SecretStore {
  const auth = new GoogleAuth({ scopes: ["https://www.googleapis.com/auth/cloud-platform"] });
  let projectId: string | undefined;

  async function secretPath(secret: string): Promise<string> {
    projectId = projectId ?? process.env.GCLOUD_PROJECT ?? (await auth.getProjectId());
    return `projects/${projectId}/secrets/${secret}`;
  }

  async function request<T>(method: "GET" | "POST", path: string, data?: unknown): Promise<T> {
    const client = await auth.getClient();
    const res = await client.request<T>({ url: `${API}/${path}`, method, data, timeout: 10 * 1000 });
    return res.data;
  }

  return {
    async accessLatest(secret) {
      const r = await request<{ name?: string; payload?: { data?: string } }>(
        "GET", `${await secretPath(secret)}/versions/latest:access`);
      return { value: Buffer.from(r.payload?.data ?? "", "base64").toString("utf8"), version: versionId(r.name) };
    },
    async addVersion(secret, value) {
      const r = await request<{ name?: string; createTime?: string }>(
        "POST", `${await secretPath(secret)}:addVersion`,
        { payload: { data: Buffer.from(value, "utf8").toString("base64") } });
      return { version: versionId(r.name), createTime: r.createTime ?? "" };
    },
    async getVersion(secret, version) {
      const r = await request<{ createTime?: string; state?: string }>(
        "GET", `${await secretPath(secret)}/versions/${encodeURIComponent(version)}`);
      return { createTime: r.createTime ?? "", state: r.state ?? "" };
    },
    async testPermissions(secret, permissions) {
      const r = await request<{ permissions?: string[] }>(
        "POST", `${await secretPath(secret)}:testIamPermissions`, { permissions });
      return Array.isArray(r.permissions) ? r.permissions : [];
    },
  };
}

/** "projects/1/secrets/GEMINI_API_KEY/versions/8" → "8". */
export function versionId(name: unknown): string {
  return typeof name === "string" ? name.substring(name.lastIndexOf("/") + 1) : "";
}
