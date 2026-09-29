pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "js/Model.js" as Model
import "js/Ledger.js" as Ledger

// Focused-window time per app, per day, in
// ~/.local/state/tally-screentime/history.json:
//   { days: { "YYYY-MM-DD": { total, apps:{id:ms}, h:[24 x ms],
//                              s:{id:[stretches, longest]}, best:[ms, start], n:{flags} } } }
//
// Cost model: no polling. The only recurring wakeup is a 15 s timer that
// exists while some app is being billed; a disk write is at most one per
// 20 s and only when something changed. Idle (3 min by default) stops both.
Item {
    id: root

    readonly property string historyPath: TallyStore.stateDir + "/history.json"
    readonly property string legacyPath: Quickshell.env("HOME") + "/.local/state/pulse-screentime/history.json"

    property string todayKey: Model.dayKey(new Date())
    // Every day including today; always REPLACED (never mutated in place)
    // so bindings downstream re-evaluate.
    property var days: ({})
    readonly property var today: days[todayKey] || Model.newDay()

    property string activeApp: ""
    property double activeStart: 0
    property double stretchStart: 0
    property double runStart: 0
    property bool ready: false
    property bool pathReady: false
    property bool idle: false
    // TALLY_DEMO=1: show the history that is there, count nothing, write nothing.
    readonly property bool demo: Quickshell.env("TALLY_DEMO") === "1"

    readonly property bool hasActivity: activeApp !== "" && !idle
    readonly property string barLabel: Str.fmt(today.total)

    function day(key) {
        return root.days[key] || Model.newDay();
    }

    // ---- App names ---------------------------------------------------------
    property var nameCache: ({})
    function appName(appId) {
        if (!appId)
            return "";
        if (root.nameCache[appId] !== undefined)
            return root.nameCache[appId];
        var name = appId;
        var entry = DesktopEntries.heuristicLookup(appId);
        if (entry && entry.name)
            name = entry.name;
        else if (name.length > 0)
            name = name.charAt(0).toUpperCase() + name.slice(1);
        root.nameCache[appId] = name;   // memo only, nothing binds to it
        return name;
    }

    // Icon name from the desktop entry; "" when the app has none.
    property var iconCache: ({})
    function appIcon(appId) {
        if (!appId)
            return "";
        var c = root.iconCache[appId];
        if (c !== undefined)
            return c;
        var entry = DesktopEntries.heuristicLookup(appId);
        var icon = entry && entry.icon ? entry.icon : appId;
        root.iconCache[appId] = icon;
        return icon;
    }

    // ---- Tracking ----------------------------------------------------------
    function clone(d) { return Ledger.clone(d); }

    function notify(title, body, urgent) {
        var cmd = ["notify-send", "-a", "Tally"];
        if (urgent)
            cmd.push("-u", "critical");
        cmd.push(title, body);
        Quickshell.execDetached(cmd);
    }

    // Goal and per-app limit thresholds; each fires once per day, the flag
    // living in the day's own record so a shell restart doesn't repeat it.
    function checks(d, app) {
        var goal = TallyStore.goalHours * 3600000;
        if (goal > 0) {
            if (TallyStore.notifyNear && d.total >= goal * 0.8 && d.total < goal && !d.n.g80) {
                d.n.g80 = 1;
                root.notify(Str.nGoalNear, Str.nGoalNearBody(Str.fmt(goal - d.total), TallyStore.goalHours), false);
            }
            if (d.total >= goal && !d.n.g100) {
                d.n.g100 = 1;
                if (TallyStore.notifyOver)
                    root.notify(Str.nGoalOver, Str.nGoalOverBody(Str.fmt(d.total), Str.fmt(d.total - goal)), false);
            }
        }
        var lim = TallyStore.limits[app];
        if (lim && lim.on) {
            var lm = lim.min * 60000;
            var ms = d.apps[app] || 0;
            var nm = root.appName(app);
            if (ms >= lm * 0.8 && ms < lm && !d.n["a80:" + app]) {
                d.n["a80:" + app] = 1;
                root.notify(Str.nAppNear(nm), Str.nAppNearBody(Str.fmt(lm - ms), lim.min / 60), false);
            }
            if (ms >= lm && !d.n["a100:" + app]) {
                d.n["a100:" + app] = 1;
                if (lim.mode === "dim")
                    TallyStore.dimApp = app;
                else
                    root.notify(Str.hitLimit(nm), Str.limitLine(lim.min / 60), lim.mode === "warn");
            }
        }
    }

    function commit(now) {
        if (root.demo || !root.ready || !root.activeApp || !root.activeStart)
            return;
        var elapsed = now - root.activeStart;
        root.activeStart = now;
        if (elapsed <= 0)
            return;
        // A gap this long means suspend or a clock jump: don't bill it.
        if (elapsed > 60000) {
            root.runStart = now;
            root.stretchStart = now;
            return;
        }
        var span = Ledger.addSpan(root.days, root.activeApp, now - elapsed, now);
        var nd = span.days;
        var lastKey = span.lastKey;
        if (lastKey) {
            var cur = nd[lastKey];
            if (root.runStart && now - root.runStart > cur.best[0])
                cur.best = [now - root.runStart, root.runStart];
            root.checks(cur, root.activeApp);
        }
        root.days = nd;
        TallyStore.creditFocus(root.activeApp, elapsed);
        root.scheduleSave();
    }

    // Count a focus stretch (>= 30 s) towards the app's session stats.
    function endStretch(now) {
        if (!root.activeApp || !root.stretchStart)
            return;
        var len = now - root.stretchStart;
        root.stretchStart = 0;
        if (len < 30000)
            return;
        var key = Model.dayKey(new Date(now));
        var d = root.clone(root.days[key] || Model.newDay());
        var s = d.s[root.activeApp] || [0, 0];
        d.s[root.activeApp] = [s[0] + 1, Math.max(s[1], len)];
        var nd = Object.assign({}, root.days);
        nd[key] = d;
        root.days = nd;
        root.scheduleSave();
    }

    // The idle monitor only fires after `timeout` without input, and all of
    // that time was billed to whatever was in front. Take it back, walking
    // hour by hour so the hourly buckets stay honest, but never further
    // than the start of the current run.
    function refund(now, ms) {
        var r = Ledger.refundSpan(root.days, root.activeApp, now, ms, root.runStart);
        if (r.given > 0) {
            root.days = r.days;
            root.scheduleSave();
        }
        return r.given;
    }

    function stopBilling(idleMs) {
        var now = Date.now();
        root.commit(now);
        var back = root.refund(now, idleMs || 0);
        root.endStretch(now - back);
        root.activeApp = "";
        root.activeStart = 0;
        root.runStart = 0;
    }

    function switchActive() {
        if (root.demo)
            return;
        var now = Date.now();
        root.commit(now);
        root.endStretch(now);
        var tl = ToplevelManager.activeToplevel;
        var app = tl && tl.activated && tl.appId ? tl.appId : "";
        if (app && !TallyStore.isExcluded(app)) {
            if (app !== root.activeApp)
                root.stretchStart = now;
            if (!root.activeApp)
                root.runStart = now;
            root.activeApp = app;
            root.activeStart = now;
            if (!root.stretchStart)
                root.stretchStart = now;
        } else {
            root.activeApp = "";
            root.activeStart = 0;
            root.runStart = 0;
        }
    }

    function rollover() {
        var key = Model.dayKey(new Date());
        if (key !== root.todayKey) {
            root.commit(Date.now());
            root.todayKey = key;
            root.purge();
        }
    }

    function purge() {
        var r = Ledger.purge(root.days, root.todayKey, TallyStore.retentionDays);
        if (r.dropped > 0) {
            root.days = r.days;
            root.scheduleSave();
        }
    }

    function resetToday() {
        var nd = Object.assign({}, root.days);
        delete nd[root.todayKey];
        root.days = nd;
        if (root.activeApp) {
            root.activeStart = Date.now();
            root.stretchStart = root.activeStart;
        }
        root.scheduleSave();
    }

    // Writes `text` to `path` without going through the shell's argv limit
    // for anything but the file name.
    function exportTo(path, obj, title) {
        exportFile.path = path;
        exportFile.setText(JSON.stringify(obj, null, 1));
        Quickshell.execDetached(["notify-send", "-a", "Tally", title, path]);
    }
    // Restores days from a backup (or a JSON report) and merges them into the
    // history. Returns { added, replaced, kept, skipped } or { error }.
    function importFrom(path) {
        var p = String(path).trim();
        if (p.indexOf("~/") === 0)
            p = Quickshell.env("HOME") + p.slice(1);
        importFile.path = "";
        importFile.path = p;
        var text = "";
        try { text = importFile.text(); } catch (err) { return { error: "read" }; }
        var obj = null;
        try { obj = JSON.parse(text); } catch (err2) { return { error: "json" }; }
        var parsed = Ledger.parseImport(obj);
        if (parsed.error)
            return { error: parsed.error };
        var merged = Ledger.mergeHistory(root.days, parsed.days);
        if (merged.added + merged.replaced > 0) {
            root.days = merged.days;
            root.scheduleSave();
            root.flush();
        }
        return { added: merged.added, replaced: merged.replaced, kept: merged.kept, skipped: parsed.skipped };
    }
    FileView { id: importFile; blockLoading: true }

    function exportAll() {
        root.exportTo(Quickshell.env("HOME") + "/tally-history.json", { days: root.days }, Str.historyExported);
    }

    FileView {
        id: exportFile
        atomicWrites: true
    }

    // ---- Wiring ---------------------------------------------------------------
    Connections {
        target: ToplevelManager
        function onActiveToplevelChanged() { if (!root.idle) root.switchActive(); }
    }

    // Away from the keyboard: stop billing. Inhibitors (a playing video)
    // keep counting when "Video oynarken say" is on.
    IdleMonitor {
        timeout: Math.max(1, TallyStore.idleMinutes) * 60
        respectInhibitors: TallyStore.countVideo
        onIsIdleChanged: {
            root.idle = isIdle;
            if (isIdle)
                root.stopBilling(Math.max(1, TallyStore.idleMinutes) * 60000);
            else
                root.switchActive();
        }
    }

    Timer {
        interval: 15000
        repeat: true
        running: root.ready && root.activeApp !== ""
        onTriggered: {
            root.rollover();
            root.commit(Date.now());
        }
    }

    // Excluding the app you are in right now should take effect at once.
    Connections {
        target: TallyStore
        function onExcludedChanged() { if (root.ready && !root.idle) root.switchActive(); }
        // A shorter retention takes effect at once, not at the next midnight.
        function onRetentionDaysChanged() { if (root.ready) root.purge(); }
    }

    // ---- Persistence -----------------------------------------------------------
    function scheduleSave() {
        if (root.demo)
            return;
        adapter.days = root.days;
        if (!saveTimer.running)
            saveTimer.start();
    }

    // Bill what is running up to this instant and write the file now, so
    // whatever reads the history next (a report, a backup) sees the same
    // numbers the widget shows.
    function flush() {
        if (!root.ready || root.demo)
            return;
        root.commit(Date.now());
        adapter.days = root.days;
        file.writeAdapter();
    }

    Timer {
        id: saveTimer
        interval: 20000
        onTriggered: file.writeAdapter()
    }

    Component.onDestruction: {
        if (root.ready && !root.demo) {
            root.commit(Date.now());
            adapter.days = root.days;
            file.writeAdapter();
        }
    }

    // First run: adopt the old Pulse history if there is one, once.
    Process {
        id: prep
        running: true
        command: ["sh", "-c", "mkdir -p \"$1\"; [ -n \"$4\" ] || [ -f \"$2\" ] || { [ -f \"$3\" ] && cp \"$3\" \"$2\"; }; true",
            "sh", TallyStore.stateDir, root.historyPath, root.legacyPath, Quickshell.env("TALLY_STATE_DIR") || ""]
        onExited: root.pathReady = true
    }

    FileView {
        id: file
        path: root.pathReady ? root.historyPath : ""
        atomicWrites: true
        onLoaded: {
            var loaded = adapter.days;
            root.days = loaded && typeof loaded === "object" ? loaded : ({});
            root.ready = true;
            root.purge();
            root.switchActive();
        }
        onLoadFailed: {
            root.days = {};
            root.ready = true;
            root.switchActive();
        }

        JsonAdapter {
            id: adapter
            property var days: ({})
        }
    }
}
