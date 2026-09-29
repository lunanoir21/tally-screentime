pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "js/Report.js" as Report
import "js/Html.js" as Html

// Turns the history into a report file: a PNG, a one-page PDF, or the
// report's raw data as JSON. Rendering happens in a short-lived hidden
// window (TallyReportJob) that exists only while a picture is being taken.
Item {
    id: root

    // What the export page is set to.
    property string scope: "week"          // day | week | all
    property string kind: "page"           // page | card | board
    property string format: "png"          // png | pdf | html | json
    property string look: "theme"          // theme | paper

    // Where a run stands.
    property string phase: "idle"          // idle | working | done | error
    property real progress: 0
    property string lastPath: ""
    property string lastFormat: ""
    property string error: ""
    property bool copiedRecently: false

    // Set while a picture is being rendered; the host turns it into a window.
    property var job: null

    // While a report is being made, and for a moment after, the panel ignores
    // the compositor's "grab cleared": that is the report's own window, not a
    // click outside the card.
    property double guardUntil: 0
    function guard(ms) { root.guardUntil = Date.now() + ms; }
    function guarded() { return root.phase === "working" || Date.now() < root.guardUntil; }

    readonly property string dir: Quickshell.env("TALLY_EXPORT_DIR") || (Quickshell.env("HOME") + "/Pictures/tally")
    readonly property string tool: Qt.resolvedUrl("../tools/img2pdf.py").toString().replace("file://", "")
    property string pngPath: ""
    property string pdfPath: ""

    function buildData(scopeName) {
        return Report.build(TallyTracker.days, {
            scope: scopeName || root.scope,
            todayKey: TallyTracker.todayKey,
            goalHours: TallyStore.goalHours
        });
    }

    function fileName(ext) {
        var withKind = root.format === "png" || root.format === "pdf";
        return "tally-" + root.scope + (withKind ? "-" + root.kind : "") + "-" + TallyTracker.todayKey + "." + ext;
    }

    // The interactive page: one file with its own styles, script, fonts and data.
    // `iconByName` maps an icon name to a data: URI (see tools/find_icons.py).
    function htmlPage(data, iconByName) {
        var names = {}, icons = {};
        for (var i = 0; i < data.apps.length; i++) {
            var id = data.apps[i].id;
            names[id] = TallyTracker.appName(id);
            var u = iconByName[TallyTracker.appIcon(id)];
            if (u && i < 12)
                icons[id] = u;
        }
        var payload = {
            v: 1,
            look: root.look === "paper" ? "paper" : "theme",
            generated: Str.generated(new Date()),
            pal: {
                theme: { card: String(TallyTheme.card), fg: String(TallyTheme.fg), acc: String(TallyTheme.acc) },
                paper: { card: "#f6f4ef", fg: "#16150f", acc: "#b8761f" }
            },
            i18n: Str.htmlI18n(data),
            names: names,
            icons: icons,
            report: data
        };
        return Html.assemble({ template: tplFile.text(), css: cssFile.text(), js: jsFile.text(), fonts: fontFile.text() }, payload);
    }

    function assetPath(name) { return Qt.resolvedUrl("html/" + name).toString().replace("file://", ""); }
    FileView { id: tplFile; path: root.assetPath("template.html"); blockLoading: true }
    FileView { id: cssFile; path: root.assetPath("report.css"); blockLoading: true }
    FileView { id: jsFile; path: root.assetPath("report.js"); blockLoading: true }
    FileView { id: fontFile; path: root.assetPath("fonts.css"); blockLoading: true }

    function run() {
        if (root.phase === "working")
            return;
        root.guard(4000);
        root.phase = "working";
        root.progress = 0.1;
        root.error = "";
        TallyTracker.flush();
        makeDir.running = true;
    }

    function fail(why) {
        root.guard(3000);
        root.job = null;
        root.error = why;
        root.phase = "error";
        Quickshell.execDetached(["notify-send", "-a", "Tally", Str.exportFailed, why]);
    }

    function finish(path) {
        root.guard(3000);
        root.job = null;
        root.lastPath = path;
        root.lastFormat = root.format;
        root.progress = 1;
        root.phase = "done";
        root.copiedRecently = false;
        if (TallyStore.openAfterExport)
            root.open();
        Quickshell.execDetached(["notify-send", "-a", "Tally", Str.saved, path]);
    }

    Process {
        id: makeDir
        command: ["mkdir", "-p", root.dir]
        onExited: code => {
            if (code !== 0) {
                root.fail("mkdir " + root.dir);
                return;
            }
            var data = root.buildData();
            root.progress = 0.25;
            if (root.format === "html") {
                // The page carries its app icons; find them first.
                root.htmlData = data;
                var wanted = [];
                for (var i = 0; i < data.apps.length && i < 12; i++)
                    wanted.push(TallyTracker.appIcon(data.apps[i].id));
                iconProc.command = ["python3", root.iconTool].concat(wanted);
                iconProc.running = true;
                return;
            }
            if (root.format === "json") {
                var path = root.dir + "/" + root.fileName("json");
                jsonFile.path = path;
                jsonFile.setText(JSON.stringify({ app: "tally-screentime", generated: new Date().toISOString(), report: data }, null, 1));
                root.finish(path);
                return;
            }
            root.pdfPath = root.dir + "/" + root.fileName("pdf");
            root.pngPath = root.format === "png" ? root.dir + "/" + root.fileName("png") : root.dir + "/.tally-" + Date.now() + ".png";
            root.job = { data: data, kind: root.kind, paper: root.look === "paper", path: root.pngPath };
        }
    }

    FileView {
        id: jsonFile
        atomicWrites: true
    }

    property var htmlData: null
    readonly property string iconTool: Qt.resolvedUrl("../tools/find_icons.py").toString().replace("file://", "")
    Process {
        id: iconProc
        stdout: StdioCollector { id: iconOut }
        onExited: code => {
            var map = {};
            try { map = JSON.parse(iconOut.text || "{}"); } catch (err) { map = {}; }
            var hpath = root.dir + "/" + root.fileName("html");
            jsonFile.path = hpath;
            jsonFile.setText(root.htmlPage(root.htmlData, map));
            root.finish(hpath);
        }
    }

    // Called by the render window when the picture has been saved (or not).
    function renderDone(ok) {
        root.job = null;
        if (!ok) {
            root.fail("render");
            return;
        }
        root.progress = 0.7;
        if (root.format === "png") {
            root.finish(root.pngPath);
            return;
        }
        pdfProc.command = ["python3", root.tool, root.pngPath, root.pdfPath, "--page", root.kind === "page" ? "a4" : "px", "--scale", String(root.kind === "card" ? 1 : 2)];
        pdfProc.running = true;
    }

    Process {
        id: pdfProc
        stderr: StdioCollector { id: pdfErr }
        onExited: code => {
            Quickshell.execDetached(["rm", "-f", root.pngPath]);
            if (code === 0)
                root.finish(root.pdfPath);
            else
                root.fail(code === 2 ? "PDF: python3 + Pillow (or ImageMagick) needed" : pdfErr.text.trim() || "PDF");
        }
    }

    function open() { Quickshell.execDetached(["xdg-open", root.lastPath]); }
    function showFolder() { Quickshell.execDetached(["xdg-open", root.dir]); }
    function copy() {
        if (root.lastFormat !== "png")
            return;
        Quickshell.execDetached(["sh", "-c", "wl-copy --type image/png < \"$1\"", "sh", root.lastPath]);
        root.copiedRecently = true;
        copiedTimer.restart();
    }
    Timer { id: copiedTimer; interval: 2500; onTriggered: root.copiedRecently = false }
}
