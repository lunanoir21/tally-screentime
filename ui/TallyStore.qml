pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "js/Themes.js" as Themes

// Settings (persisted to their own JSON), which surface is open, the
// focus session, and where the pill sits. Nothing here ticks unless a
// focus session is running.
Item {
    id: root

    // TALLY_STATE_DIR points Tally at another folder (tests, screenshots).
    readonly property string stateDir: Quickshell.env("TALLY_STATE_DIR") || (Quickshell.env("HOME") + "/.local/state/tally-screentime")

    // ---- Surfaces (ephemeral) ---------------------------------------------
    property bool panelOpen: false
    property bool pickerOpen: false
    property var pickerWin: null
    // "day" | "week" | "map" | "apps" | "app" | "settings" | "focus"
    property string page: "day"
    property string appId: ""
    // Which day / week end / heatmap cell the pages show ("" = today).
    property string viewKey: ""
    property string weekEnd: ""
    property string mapPick: ""
    // Page the app detail / apps list returns to.
    property string backPage: "day"

    function openPanel(p) {
        root.pickerOpen = false;
        root.viewKey = "";
        root.weekEnd = "";
        root.mapPick = "";
        root.page = p || "day";
        root.panelOpen = true;
    }
    function closePanel() { root.panelOpen = false; }
    function togglePanel() {
        if (root.panelOpen)
            root.closePanel();
        else if (!root.recentlyAutoClosed("panel"))
            root.openPanel(root.focusActive ? "focus" : "day");
    }
    function goto(p) { root.page = p; }
    function openApp(id) {
        root.backPage = root.page === "app" ? root.backPage : root.page;
        root.appId = id;
        root.page = "app";
    }
    // The first-run tour. Opens by itself until it has been finished once.
    property bool onboardingOpen: false
    property int tourStart: 0
    function finishOnboarding() {
        root.onboardingOpen = false;
        root.set("onboarded", true);
    }

    // Report export page; `scope` preselects what to export.
    function openExport(scope) {
        TallyExport.scope = scope || "week";
        if (root.page !== "export")
            root.backPage = root.page;
        root.page = "export";
    }

    function openPicker() { root.pickerOpen = true; }
    function closePicker() { root.pickerOpen = false; root.previewId = ""; }

    // A focus-grab dismissal lands a moment before the pill's own click;
    // without this the pill would instantly reopen what it just closed.
    property var lastAutoClose: ({ panel: 0 })
    property string lastClosedPage: ""
    function autoClosed(kind) {
        root.lastClosedPage = root.page;
        var m = Object.assign({}, root.lastAutoClose);
        m[kind] = Date.now();
        root.lastAutoClose = m;
    }
    function recentlyAutoClosed(kind) { return Date.now() - (root.lastAutoClose[kind] || 0) < 350; }

    // Where the pill sits (screen coordinates) so the notch points at it.
    property real anchorX: -1
    property real anchorBottom: 56
    property string anchorScreen: ""

    // ---- Focus session ---------------------------------------------------------
    readonly property int focusMinutes: 25
    property double focusEnd: 0        // epoch ms while running
    property double focusLeft: 0       // ms left while paused
    property double focusStart: 0
    property double now: Date.now()
    property var focusApps: ({})       // app -> ms spent during the session

    readonly property bool focusRunning: focusEnd > 0
    readonly property bool focusPaused: focusEnd === 0 && focusLeft > 0
    readonly property bool focusActive: focusRunning || focusPaused
    readonly property real focusRemaining: focusRunning ? Math.max(0, focusEnd - now) : focusLeft

    function startFocus() {
        root.focusStart = Date.now();
        root.focusEnd = root.focusStart + root.focusMinutes * 60000;
        root.focusLeft = 0;
        root.focusApps = {};
        root.now = root.focusStart;
        root.page = "focus";
    }
    function pauseFocus() {
        if (!root.focusRunning)
            return;
        root.focusLeft = Math.max(1000, root.focusEnd - Date.now());
        root.focusEnd = 0;
    }
    function resumeFocus() {
        if (!root.focusPaused)
            return;
        root.now = Date.now();
        root.focusEnd = root.now + root.focusLeft;
        root.focusLeft = 0;
    }
    function stopFocus() {
        root.focusEnd = 0;
        root.focusLeft = 0;
        root.focusApps = {};
        if (root.page === "focus")
            root.page = "day";
    }
    function creditFocus(app, ms) {
        if (!root.focusRunning || !app)
            return;
        var m = Object.assign({}, root.focusApps);
        m[app] = (m[app] || 0) + ms;
        root.focusApps = m;
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.focusRunning
        onTriggered: {
            root.now = Date.now();
            if (root.now >= root.focusEnd) {
                var parts = [];
                var apps = root.focusApps;
                var ids = Object.keys(apps).sort(function (a, b) { return apps[b] - apps[a]; }).slice(0, 3);
                for (var i = 0; i < ids.length; i++)
                    parts.push(TallyTracker.appName(ids[i]) + " " + Math.max(1, Math.round(apps[ids[i]] / 60000)) + Str.um);
                Quickshell.execDetached(["notify-send", "-a", "Tally", Str.nFocusEnd,
                    Str.nFocusEndBody(root.focusMinutes, parts.join(", "))]);
                root.stopFocus();
            }
        }
    }

    // ---- Settings (persisted) ------------------------------------------------
    property string themeId: "noir"
    property string language: "auto"      // "auto" | "tr" | "en"
    property bool onboarded: false
    property bool pillVisible: true
    property bool pillTime: true
    property bool pillGoalLine: true
    property bool openAfterExport: false
    property real goalHours: 6
    property bool notifyNear: true
    property bool notifyOver: false
    property int idleMinutes: 3
    property bool countVideo: true
    property var excluded: ["quickshell", "xdg-desktop-portal"]
    property int retentionDays: 365
    // app id -> { on: bool, min: minutes, mode: "notify" | "warn" | "dim" }
    property var limits: ({})

    function set(key, value) {
        root[key] = value;
        root.save();
    }
    function setLimit(id, patch) {
        var all = Object.assign({}, root.limits);
        all[id] = Object.assign({ on: false, min: 120, mode: "notify" }, all[id] || {}, patch);
        root.limits = all;
        root.save();
    }
    function limitOf(id) {
        return root.limits[id] || { on: false, min: 120, mode: "notify" };
    }
    function isExcluded(id) {
        var low = String(id).toLowerCase();
        for (var i = 0; i < root.excluded.length; i++)
            if (low === String(root.excluded[i]).toLowerCase() || low.indexOf(String(root.excluded[i]).toLowerCase()) === 0)
                return true;
        return false;
    }
    function exclude(id) {
        if (root.excluded.indexOf(id) === -1)
            root.set("excluded", root.excluded.concat([id]));
    }
    function include(id) {
        root.set("excluded", root.excluded.filter(function (x) { return x !== id; }));
    }

    // ---- Theme -------------------------------------------------------------------
    property bool systemDark: true
    // The picker sets previewId while a row is highlighted, so the widget
    // behind it re-themes live; closing the picker clears it.
    property string previewId: ""
    function resolveTheme(id) { return id === "system" ? (systemDark ? "noir" : "latte") : id; }
    readonly property string effectiveThemeId: resolveTheme(previewId !== "" ? previewId : themeId)

    Process {
        id: schemeProbe
        command: ["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"]
        stdout: StdioCollector {
            onStreamFinished: root.systemDark = text.indexOf("light") === -1
        }
    }
    onThemeIdChanged: if (themeId === "system" && loaded) schemeProbe.running = true

    // Full-screen "sınırı aştın" overlay for apps whose limit mode is dim.
    property string dimApp: ""

    // ---- Persistence -------------------------------------------------------------
    property bool loaded: false

    function save() {
        if (!root.loaded)
            return;
        adapter.themeId = root.themeId;
        adapter.language = root.language;
        adapter.onboarded = root.onboarded;
        adapter.pillVisible = root.pillVisible;
        adapter.pillTime = root.pillTime;
        adapter.pillGoalLine = root.pillGoalLine;
        adapter.openAfterExport = root.openAfterExport;
        adapter.goalHours = root.goalHours;
        adapter.notifyNear = root.notifyNear;
        adapter.notifyOver = root.notifyOver;
        adapter.idleMinutes = root.idleMinutes;
        adapter.countVideo = root.countVideo;
        adapter.excluded = root.excluded;
        adapter.retentionDays = root.retentionDays;
        adapter.limits = root.limits;
        saveTimer.restart();
    }

    Timer {
        id: saveTimer
        interval: 400
        onTriggered: file.writeAdapter()
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", root.stateDir])

    FileView {
        id: file
        path: root.stateDir + "/settings.json"
        atomicWrites: true
        onLoaded: {
            root.themeId = Themes.indexOf(adapter.themeId) >= 0 ? adapter.themeId : Themes.DEFAULT_ID;
            root.language = adapter.language === "tr" || adapter.language === "en" ? adapter.language : "auto";
            root.onboarded = adapter.onboarded;
            root.onboardingOpen = !adapter.onboarded;
            root.pillVisible = adapter.pillVisible;
            root.pillTime = adapter.pillTime;
            root.pillGoalLine = adapter.pillGoalLine;
            root.openAfterExport = adapter.openAfterExport;
            root.goalHours = adapter.goalHours;
            root.notifyNear = adapter.notifyNear;
            root.notifyOver = adapter.notifyOver;
            root.idleMinutes = Math.max(1, adapter.idleMinutes);
            root.countVideo = adapter.countVideo;
            root.excluded = Array.isArray(adapter.excluded) ? adapter.excluded : [];
            root.retentionDays = adapter.retentionDays;
            root.limits = adapter.limits && typeof adapter.limits === "object" ? adapter.limits : ({});
            root.loaded = true;
            if (root.themeId === "system")
                schemeProbe.running = true;
        }
        onLoadFailed: {
            root.loaded = true;
            root.save();
        }

        JsonAdapter {
            id: adapter
            property string themeId: "noir"
            property string language: "auto"
            property bool onboarded: false
            property bool pillVisible: true
            property bool pillTime: true
            property bool pillGoalLine: true
            property bool openAfterExport: false
            property real goalHours: 6
            property bool notifyNear: true
            property bool notifyOver: false
            property int idleMinutes: 3
            property bool countVideo: true
            property var excluded: ["quickshell", "xdg-desktop-portal"]
            property int retentionDays: 365
            property var limits: ({})
        }
    }
}
