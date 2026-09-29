import QtQuick
import "js/Model.js" as Model
import Quickshell
import Quickshell.Wayland

// "Karart" limit mode: dims one screen and asks for a decision.
PanelWindow {
    id: root

    WlrLayershell.namespace: "tally-dim"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    color: Qt.rgba(0, 0, 0, 0.82)
    anchors { top: true; bottom: true; left: true; right: true }

    readonly property var lim: TallyStore.limitOf(TallyStore.dimApp)

    Column {
        anchors.centerIn: parent
        spacing: 14
        TBig { anchors.horizontalCenter: parent.horizontalCenter; bigPx: 44; wght: 500; color: "#ececec"; text: Str.hitLimit(TallyTracker.appName(TallyStore.dimApp)) }
        TText { anchors.horizontalCenter: parent.horizontalCenter; px: 13; color: "#8d8d92"; text: Str.limitLine(root.lim.min / 60) }
        Item { width: 1; height: 10 }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 160; height: 44; radius: 12
            color: "#ececec"
            TText { anchors.centerIn: parent; px: 12.5; font.weight: Font.Medium; color: "#0f0f10"; text: Str.keepGoing }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: TallyStore.dimApp = "" }
        }
    }
}
