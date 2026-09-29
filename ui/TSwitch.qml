import QtQuick

// 38 x 22 switch.
Item {
    id: root

    property bool checked: false
    signal toggled(bool value)

    width: 38
    height: 22

    Rectangle {
        anchors.fill: parent
        radius: 11
        color: root.checked ? TallyTheme.fg : TallyTheme.alpha(TallyTheme.fg, 0.14)
        Behavior on color { ColorAnimation { duration: 140 } }
        Rectangle {
            y: 3
            x: root.checked ? 19 : 3
            width: 16
            height: 16
            radius: 8
            color: root.checked ? TallyTheme.card : TallyTheme.muted
            Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
