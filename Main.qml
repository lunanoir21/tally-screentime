import QtQuick
import Quickshell
import "ui" as Tally

// Try Tally on its own, without a shell of your own:
//
//     quickshell -p /path/to/tally/Main.qml
//
// A small bar in the top-right corner holds the pill; everything else is the
// same Tally that a real bar would load with one TallyHost and one TallyPill.
ShellRoot {
    Tally.TallyHost {}

    PanelWindow {
        id: win
        anchors { top: true; right: true }
        margins { top: 8; right: 12 }
        implicitWidth: pill.implicitWidth + 16
        implicitHeight: 48
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        Tally.TallyPill {
            id: pill
            anchors.centerIn: parent
            size: 48
            barTop: 8
            barLeft: 0
            screenName: win.screen ? win.screen.name : ""
        }
    }
}
