import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { ensureUserDoc } from "../utils/firestore";
import { japanDateString } from "../utils/japanDay";
import { AiReport, checkAiReport, reportCount } from "./aiReport";

/**
 * Reports of AI output, one document each. Only admins read them (the PC
 * admin's 「報告」 page) and they may only mark them handled; see
 * firestore.rules.
 */
export const CONTENT_REPORTS = "content_reports";

/**
 * Saves one report for [uid]: the report and the day's counter in one
 * transaction, at most MAX_REPORTS_PER_DAY a day. Returns the report's id.
 */
export async function saveAiReport(
  db: admin.firestore.Firestore, uid: string, report: AiReport, now: Date = new Date(),
): Promise<string> {
  const userRef = db.collection("users").doc(uid);
  const reportRef = db.collection(CONTENT_REPORTS).doc();
  const today = japanDateString(now);
  await db.runTransaction(async (tx) => {
    const user = await tx.get(userRef);
    if (!user.exists) throw new HttpsError("not-found", "User not found.");
    const count = reportCount(user.data() ?? {}, today);
    if (!count.allowed) throw new HttpsError("resource-exhausted", "REPORT_LIMIT");
    tx.create(reportRef, { ...report, uid, status: "new", createdAt: now.getTime(), day: today });
    tx.update(userRef, count.update);
  });
  return reportRef.id;
}

/**
 * reportAiContent: the 「報告」 button. Any signed-in player (guests too) may
 * report AI output they were shown; the app sends the text, since it lives
 * only on the phone.
 */
export const reportAiContent = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  const checked = checkAiReport(request.data);
  if ("refusal" in checked) {
    throw new HttpsError("invalid-argument", checked.refusal);
  }
  const uid = request.auth.uid;
  await ensureUserDoc(uid);
  const id = await saveAiReport(admin.firestore(), uid, checked.report);
  return { id };
});
