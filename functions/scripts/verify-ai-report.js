/**
 * Offline checks of what the 「報告」 button may send (src/reports/aiReport.ts):
 * which reports are taken and how they are cleaned up, and the 20-a-day
 * counter. The saving (one transaction, the limit under load) is in
 * verify-ai-report-db.js, against the Firestore emulator; who may read the
 * reports is in verify-users-rules.js.
 *
 * Run: npm run verify:aireport
 */
const {
  MAX_AI_TEXT, MAX_STRATEGY, MAX_COMMENT, MAX_LABEL, MAX_REPORTS_PER_DAY, checkAiReport, reportCount,
} = require("../lib/reports/aiReport");

let fail = 0;
function check(name, actual, expected) {
  if (JSON.stringify(actual) === JSON.stringify(expected)) {
    console.log(`  ok   ${name}`);
  } else {
    fail++;
    console.log(`  FAIL ${name} - expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

const good = {
  kind: "battle", reason: "offensive", aiText: "敵軍は北の丘から攻め込み…", strategy: "丘を守る",
  comment: "  表現がひどい  ", gameMode: "normal", scenarioId: "aces_001", worldviewKey: "modern", appVersion: "1.0.0",
};
const refusal = (over) => {
  const r = checkAiReport({ ...good, ...over });
  return "refusal" in r ? r.refusal : "taken";
};

console.log("\nwhat a report may carry\n");
check("a full report is taken, the comment trimmed", checkAiReport(good), {
  report: { ...good, comment: "表現がひどい" },
});
check("a chronicle with only the text and a reason", checkAiReport({ kind: "chronicle", reason: "other", aiText: "x" }), {
  report: {
    kind: "chronicle", reason: "other", aiText: "x", strategy: "", comment: "",
    gameMode: "", scenarioId: "", worldviewKey: "", appVersion: "",
  },
});
check("null fields count as empty", refusal({ strategy: null, comment: null, gameMode: null }), "taken");
check("all four reasons", ["offensive", "violence", "sexual", "other"].map((reason) => refusal({ reason })),
  ["taken", "taken", "taken", "taken"]);

console.log("\nwhat is refused\n");
check("nothing sent", checkAiReport(undefined), { refusal: "invalid_request" });
check("a list instead of a report", checkAiReport([good]), { refusal: "invalid_request" });
check("an unknown kind", refusal({ kind: "pvp" }), "invalid_kind");
check("no kind", refusal({ kind: undefined }), "invalid_kind");
check("an unknown reason", refusal({ reason: "boring" }), "invalid_reason");
check("no text", refusal({ aiText: undefined }), "empty_text");
check("only spaces", refusal({ aiText: "  \n " }), "empty_text");
check("text that isn't a string", refusal({ aiText: 42 }), "empty_text");
check(`text of ${MAX_AI_TEXT} characters is taken`, refusal({ aiText: "a".repeat(MAX_AI_TEXT) }), "taken");
check(`text of ${MAX_AI_TEXT + 1}: refused`, refusal({ aiText: "a".repeat(MAX_AI_TEXT + 1) }), "text_too_long");
check(`strategy of ${MAX_STRATEGY + 1}: refused`, refusal({ strategy: "a".repeat(MAX_STRATEGY + 1) }), "strategy_too_long");
check("a strategy that isn't a string", refusal({ strategy: { x: 1 } }), "strategy_too_long");
check(`comment of ${MAX_COMMENT + 1}: refused`, refusal({ comment: "a".repeat(MAX_COMMENT + 1) }), "comment_too_long");
check(`comment of ${MAX_COMMENT} plus spaces: taken`, refusal({ comment: ` ${"a".repeat(MAX_COMMENT)} ` }), "taken");
check(`a game mode of ${MAX_LABEL + 1}: refused`, refusal({ gameMode: "a".repeat(MAX_LABEL + 1) }), "invalid_label");
check("a scenario id that isn't a string", refusal({ scenarioId: 7 }), "invalid_label");

console.log("\nthe day's counter (20 reports a day)\n");
check("the limit is 20", MAX_REPORTS_PER_DAY, 20);
check("the first report of the day", reportCount({}, "2026-11-20"),
  { allowed: true, update: { aiReportsDate: "2026-11-20", aiReportsCount: 1 } });
check("the 20th", reportCount({ aiReportsDate: "2026-11-20", aiReportsCount: 19 }, "2026-11-20"),
  { allowed: true, update: { aiReportsDate: "2026-11-20", aiReportsCount: 20 } });
check("the 21st: refused", reportCount({ aiReportsDate: "2026-11-20", aiReportsCount: 20 }, "2026-11-20"),
  { allowed: false });
check("a new day starts at 1", reportCount({ aiReportsDate: "2026-11-19", aiReportsCount: 20 }, "2026-11-20"),
  { allowed: true, update: { aiReportsDate: "2026-11-20", aiReportsCount: 1 } });
check("an odd count is taken as none", reportCount({ aiReportsDate: "2026-11-20", aiReportsCount: "x" }, "2026-11-20"),
  { allowed: true, update: { aiReportsDate: "2026-11-20", aiReportsCount: 1 } });

console.log(fail === 0 ? "\nAll checks passed.\n" : `\n${fail} check(s) failed.\n`);
process.exit(fail === 0 ? 0 : 1);
