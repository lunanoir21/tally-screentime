import QtQuick
import Quickshell
import Quickshell.Wayland

// A click-through window, parked off screen, that lives just long enough to
// draw a report and photograph it.
PanelWindow {
    id: win

    required property var job

    // The report's size in css pixels.
    readonly property size box: job.kind === "card" ? Qt.size(1080, 1350) : job.kind === "board" ? Qt.size(1600, 900) : Qt.size(794, 1123)

    WlrLayershell.namespace: "tally-render"
    WlrLayershell.layer: WlrLayer.Background
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    color: "transparent"
    implicitWidth: box.width
    implicitHeight: box.height
    // Parked beyond the left edge, so it is never on screen; empty input
    // region, so it never takes a click.
    anchors { left: true; top: true }
    margins { left: -(box.width + 64); top: 0 }
    mask: Region {}

    Loader {
        id: view
        Component.onCompleted: {
            var file = win.job.kind === "card" ? "ReportCard.qml" : win.job.kind === "board" ? "ReportBoard.qml" : "ReportPage.qml";
            view.setSource(file, { report: win.job.data, paper: win.job.paper });
        }
    }

    // Give the fonts and icons a moment, then take the picture.
    Timer {
        interval: 900
        running: view.item !== null
        onTriggered: {
            TallyExport.progress = 0.45;
            var it = view.item;
            var s = it.pixelScale;
            it.grabToImage(function (result) {
                TallyExport.renderDone(result.saveToFile(win.job.path));
            }, Qt.size(it.width * s, it.height * s));
        }
    }
    // A picture that never comes back must not hang the export page.
    Timer {
        interval: 15000
        running: true
        onTriggered: TallyExport.fail("timeout")
    }
}
