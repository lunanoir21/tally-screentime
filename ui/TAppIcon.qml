import QtQuick
import Quickshell

// An app's icon on a soft tile; its first letter until (or unless) the icon loads.
Rectangle {
    id: root

    property string appId: ""
    property string name: ""
    property real size: 28
    property real letterPx: 12
    // The "others" row has no app behind it.
    property bool other: false
    property color ink: TallyTheme.fg
    // Reports load icons synchronously so a picture is never taken half-drawn.
    property bool sync: false

    width: size
    height: size
    radius: Math.round(size * 0.29)
    color: TallyTheme.tile

    readonly property string source: other || appId === "" ? "" : Quickshell.iconPath(TallyTracker.appIcon(appId), true)

    Image {
        id: icon
        anchors.centerIn: parent
        width: Math.round(root.size * 0.66)
        height: width
        sourceSize: Qt.size(width * 2, height * 2)
        fillMode: Image.PreserveAspectFit
        asynchronous: !root.sync
        smooth: true
        source: root.source
        visible: status === Image.Ready
    }
    TText {
        anchors.centerIn: parent
        visible: !icon.visible
        px: root.letterPx
        color: root.ink
        font.weight: Font.Bold
        text: root.other ? "·" : (root.name !== "" ? root.name.charAt(0).toUpperCase() : "?")
    }
}
