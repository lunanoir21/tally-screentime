import QtQuick

// 32 x 32 rounded button with an icon.
Rectangle {
    id: root

    property string icon: "close"
    property real iconSize: 14
    property real stroke: 1.8
    property bool dim: false
    signal clicked()

    width: 32
    height: 32
    radius: 10
    color: ma.containsMouse ? TallyTheme.ctlHover : TallyTheme.ctl
    Behavior on color { ColorAnimation { duration: 120 } }

    TIcon {
        anchors.centerIn: parent
        name: root.icon
        size: root.iconSize
        stroke: root.stroke
        color: root.dim ? TallyTheme.faint : TallyTheme.muted
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
