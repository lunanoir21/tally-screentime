import QtQuick
import Quickshell

// What Quickshell costs with one small window and nothing else: the floor
// Tally's numbers are compared against.
ShellRoot {
    PanelWindow {
        anchors { top: true; right: true }
        implicitWidth: 120
        implicitHeight: 48
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
    }
}
