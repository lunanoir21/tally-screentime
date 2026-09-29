import QtQuick

// "‹  Bugün · Salı 29 Eyl  ›"
Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property bool canNext: true
    signal prev()
    signal next()

    height: 22

    MouseArea {
        anchors.left: parent.left
        width: 26
        height: parent.height
        cursorShape: Qt.PointingHandCursor
        onClicked: root.prev()
        TIcon { anchors.centerIn: parent; name: "left"; size: 14; color: TallyTheme.muted }
    }
    Row {
        anchors.centerIn: parent
        spacing: 6
        TText { px: 12; font.weight: Font.Medium; text: root.title }
        TText { px: 12; color: TallyTheme.muted; visible: root.subtitle !== ""; text: "· " + root.subtitle }
    }
    MouseArea {
        anchors.right: parent.right
        width: 26
        height: parent.height
        enabled: root.canNext
        cursorShape: Qt.PointingHandCursor
        onClicked: root.next()
        TIcon { anchors.centerIn: parent; name: "right"; size: 14; color: root.canNext ? TallyTheme.muted : TallyTheme.faint }
    }
}
