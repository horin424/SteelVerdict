// Reports of AI output. Web only: the app has no screen for them.
//
// The app's 「報告」 button (battle result and war history screens) sends a
// report to the reportAiContent function, which stores it in content_reports
// (functions/src/reports). Google Play's AI-Generated Content policy asks for
// that button; this page is where the reports are read.
//
// - Only admins in system_config/admin_uids can read reports (firestore.rules).
//   The panel also opens for dev_uids, who get a note here instead.
// - The one change allowed is the 「対応済み」 checkbox (status, reviewedAt,
//   reviewedBy). Reports can't be edited or deleted.
// - The list is live: a new report appears without reloading. 「未対応」 lists
//   the open reports, 「すべて」 the newest first, 100 at a time.
import { h, fill, toast, errorText } from "../ui.js";
import { t } from "../i18n.js";
import { localizedTitle, modeName } from "../model.js";

const PAGE = 100;

// Kept for the life of the tab, so switching the language (which rebuilds the
// page) keeps the view and the open report.
let view = "new";
let selectedId = null;

const REASONS = {
  offensive: "aiReportReasonOffensive",
  violence: "aiReportReasonViolence",
  sexual: "aiReportReasonSexual",
  other: "aiReportReasonOther",
};
const KINDS = { battle: "aiReportTargetBattle", chronicle: "aiReportTargetChronicle" };

const reasonName = (reason) => (REASONS[reason] ? t(REASONS[reason]) : String(reason ?? "—"));
const kindName = (kind) => (KINDS[kind] ? t(KINDS[kind]) : String(kind ?? "—"));

/// The first line worth showing in the list. The AI writes Markdown, so rules
/// (---) are skipped and heading and bold markers dropped.
export function firstLine(text) {
  for (const raw of String(text ?? "").split(/\r?\n/)) {
    const line = raw.trim();
    if (!line || /^([-*_])\1{2,}$/.test(line)) continue;
    const plain = line.replace(/^#{1,6}\s+/, "").replace(/\*\*/g, "").trim();
    if (plain) return plain;
  }
  return "";
}

/// Date and time in the browser's time zone; the client's PC is in Japan.
function when(ms, lang) {
  if (typeof ms !== "number" || !Number.isFinite(ms)) return "—";
  return new Intl.DateTimeFormat(lang === "ja" ? "ja-JP" : "en-GB", { dateStyle: "medium", timeStyle: "short" }).format(
    ms,
  );
}

export function mountReports(root, ctx) {
  if (!ctx.canWrite()) {
    root.append(h("p", { class: "note" }, t("reportsAdminOnly")));
    return { isDirty: () => false, onConfig() {}, dispose() {} };
  }

  let shown = PAGE; // how many the current view asks for
  let reports = []; // the current view, newest first
  let hasMore = false;
  let loaded = false;
  let loadError = null;
  let selected = null; // the open report, kept when it leaves the 未対応 list
  let savingId = null;
  let detailKey = null; // what the detail shows, so it is rebuilt only on a change
  let unsub = null;

  const tabs = h("div", { class: "tabs", role: "group", "aria-label": t("adminReports") });
  const listEl = h("nav", { class: "item-list", "aria-label": t("adminReports") });
  const moreEl = h("div", { class: "list-more" });
  const detailEl = h("section", { class: "item-form report", "aria-live": "polite" });
  root.append(
    h(
      "div",
      { class: "reports" },
      h("p", { class: "note" }, t("reportsNote")),
      h(
        "div",
        { class: "split" },
        h(
          "div",
          { class: "list-col" },
          h("div", { class: "list-head" }, h("span", {}, t("adminReports")), tabs),
          listEl,
          moreEl,
        ),
        detailEl,
      ),
    ),
  );

  function subscribe() {
    if (unsub) unsub();
    unsub = ctx.watchReports(
      { open: view === "new", count: shown },
      (list, fromCache) => {
        // Offline, the first answer comes from an empty local cache: wait for
        // the server rather than say there are no reports.
        if (!loaded && fromCache && !list.length) return;
        reports = list;
        hasMore = list.length >= shown;
        loaded = true;
        loadError = null;
        const fresh = list.find((r) => r.id === selectedId);
        if (fresh) selected = fresh;
        render();
      },
      (err) => {
        loadError = err;
        render();
      },
    );
  }

  function switchView(next) {
    if (next === view) return;
    view = next;
    shown = PAGE;
    reports = [];
    loaded = false;
    loadError = null;
    render();
    subscribe();
  }

  function select(report) {
    selectedId = report.id;
    selected = report;
    render();
  }

  async function setDone(report, done) {
    // The fields the rules allow. Back to open keeps who handled it last.
    const change = done ? { status: "done", reviewedAt: Date.now(), reviewedBy: ctx.uid } : { status: "new" };
    const before = report;
    selected = { ...report, ...change };
    savingId = report.id;
    render();
    try {
      await ctx.updateReport(report.id, change);
      toast(t(done ? "reportMarkedDone" : "reportMarkedOpen"));
    } catch (e) {
      if (selectedId === report.id) selected = before;
      toast(t("adminSaveError", { error: errorText(e) }), "error");
    } finally {
      savingId = null;
      render();
    }
  }

  function render() {
    renderTabs();
    renderList();
    renderMore();
    renderDetail();
  }

  function renderTabs() {
    fill(
      tabs,
      ["new", "all"].map((v) =>
        h(
          "button",
          {
            class: v === view ? "active" : null,
            type: "button",
            "aria-pressed": v === view ? "true" : "false",
            onClick: () => switchView(v),
          },
          t(v === "new" ? "reportsOpen" : "reportsAll"),
        ),
      ),
    );
  }

  function renderList() {
    if (loadError) {
      fill(listEl, h("p", { class: "list-note error" }, t("reportsLoadFailed", { error: errorText(loadError) })));
      return;
    }
    if (!loaded) {
      fill(listEl, h("p", { class: "list-note" }, t("loading")));
      return;
    }
    if (!reports.length) {
      fill(listEl, h("p", { class: "list-note" }, t(view === "new" ? "reportsNoneOpen" : "reportsNone")));
      return;
    }
    const lang = ctx.lang();
    fill(
      listEl,
      reports.map((r) => {
        const done = r.status === "done";
        const meta = [when(r.createdAt, lang), kindName(r.kind), r.gameMode ? modeName(r.gameMode, t) : null];
        return h(
          "div",
          { class: `list-item${r.id === selectedId ? " active" : ""}${done ? " done" : ""}` },
          h(
            "button",
            { class: "list-main", type: "button", onClick: () => select(r) },
            h(
              "span",
              { class: "list-title" },
              reasonName(r.reason),
              // Next to the reason: the date line is cut off in the narrow list.
              done ? h("span", { class: "list-done" }, `✓ ${t("reportDone")}`) : null,
            ),
            h("span", { class: "list-sub" }, meta.filter(Boolean).join(" · ")),
            h("span", { class: "list-sub excerpt" }, firstLine(r.aiText)),
          ),
        );
      }),
    );
  }

  function renderMore() {
    fill(
      moreEl,
      loaded && hasMore && !loadError
        ? h(
            "button",
            {
              class: "small secondary",
              type: "button",
              onClick: () => {
                shown += PAGE;
                subscribe();
              },
            },
            t("reportsMore"),
          )
        : null,
    );
  }

  function renderDetail() {
    const lang = ctx.lang();
    const key = JSON.stringify([selected, savingId, lang]);
    if (key === detailKey) return;
    detailKey = key;
    if (!selected) {
      fill(detailEl, h("p", { class: "empty" }, t("reportsSelect")));
      return;
    }
    const r = selected;
    const { scenarios, worldviews } = ctx.parsed();
    const done = r.status === "done";
    // A config title next to the stored id, or just the id.
    const named = (item, id) =>
      !id ? "—" : item ? [localizedTitle(item, lang) || id, " ", h("code", {}, id)] : h("code", {}, id);
    const text = (label, value, counted = false) => [
      h(
        "h3",
        { class: "section-label" },
        label,
        counted && value ? ` · ${t("characters", { n: value.length.toLocaleString() })}` : null,
      ),
      value && value.trim()
        ? h("div", { class: "report-text" }, value)
        : h("p", { class: "field-hint" }, t("reportNone")),
    ];
    fill(
      detailEl,
      h(
        "div",
        { class: "report-head" },
        h("h2", { class: "form-title" }, reasonName(r.reason)),
        h(
          "label",
          { class: "check report-done" },
          h("input", {
            type: "checkbox",
            checked: done,
            disabled: savingId === r.id,
            onChange: (e) => setDone(r, e.target.checked),
          }),
          h("span", {}, t("reportDone")),
        ),
      ),
      done && r.reviewedAt
        ? h(
            "p",
            { class: "field-hint" },
            t("reportHandledAt", {
              date: when(r.reviewedAt, lang),
              who: r.reviewedBy === ctx.uid ? t("you") : r.reviewedBy || "—",
            }),
          )
        : null,
      h(
        "dl",
        { class: "report-meta" },
        [
          [t("reportReceived"), when(r.createdAt, lang)],
          [t("reportKind"), kindName(r.kind)],
          [t("reportMode"), r.gameMode ? modeName(r.gameMode, t) : "—"],
          [t("reportScenario"), named(scenarios[r.scenarioId], r.scenarioId)],
          [t("reportWorld"), named(worldviews[r.worldviewKey], r.worldviewKey)],
          [t("reportAppVersion"), r.appVersion || "—"],
          [t("reportReporter"), r.uid ? h("code", {}, r.uid) : "—"],
        ].map(([label, value]) => [h("dt", {}, label), h("dd", {}, value)]),
      ),
      text(t("reportComment"), r.comment),
      text(t("reportStrategy"), r.strategy),
      text(t("reportAiText"), r.aiText, true),
    );
  }

  render();
  subscribe();

  return {
    isDirty: () => false,
    // Scenario and world names come from the config.
    onConfig() {
      detailKey = null;
      renderDetail();
    },
    dispose() {
      if (unsub) unsub();
      unsub = null;
    },
  };
}
