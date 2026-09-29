import QtQuick
import "js/Model.js" as Model

// Monogram tile, name + share, time, and a 3 px bar.
Item {
    id: root

    property string appId: ""
    property string name: ""
    property real share: 0      // 0..1
    property real rel: 0        // 0..1, bar length
    property double ms: 0
    property bool lead: false   // accent bar (the top app)
    property bool clickable: appId !== ""
    signal clicked()

    implicitHeight: 28
    height: 28

    TAppIcon {
        id: tile
        appId: root.appId
        name: root.name
        other: root.appId === ""
    }

    Item {
        anchors.left: tile.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 25

        TText {
            id: nameText
            px: 13
            font.weight: Font.Medium
            text: root.name
            elide: Text.ElideRight
            width: Math.min(implicitWidth, parent.width - timeText.width - shareText.width - 24)
        }
        TText {
            id: shareText
            anchors.left: nameText.right
            anchors.leftMargin: 6
            anchors.baseline: nameText.baseline
            px: 10.5
            color: TallyTheme.faint
            text: "%" + Math.round(root.share * 100)
        }
        TText {
            id: timeText
            anchors.right: parent.right
            anchors.baseline: nameText.baseline
            px: 12.5
            text: Str.fmt(root.ms)
        }
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 3
            radius: 2
            color: TallyTheme.track
            Rectangle {
                width: Math.max(2, parent.width * root.rel)
                height: 3
                radius: 2
                color: root.lead ? TallyTheme.acc : TallyTheme.bar
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.clickable
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
