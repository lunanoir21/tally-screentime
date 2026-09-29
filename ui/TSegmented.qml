import QtQuick

// Pill-shaped segmented control. `model` is a list of labels. The
// highlight is one rectangle that slides to the chosen segment.
Rectangle {
    id: root

    property var model: []
    property int currentIndex: 0
    property real px: 11
    property real hPad: 11
    property real vPad: 4
    property real innerRadius: 7
    // Stretch the segments to share the whole width.
    property bool fill: false
    signal picked(int index)

    // Geometry of the chosen segment, kept in step by the delegates.
    property real hx: 0
    property real hw: 0
    function follow() {
        var it = rep.itemAt(root.currentIndex);
        if (it) {
            root.hx = it.x;
            root.hw = it.width;
        }
    }
    onCurrentIndexChanged: follow()

    implicitWidth: fill ? 0 : row.implicitWidth + 6
    implicitHeight: row.implicitHeight + 6
    radius: innerRadius + 3
    color: TallyTheme.segBg

    Rectangle {
        x: 3 + root.hx
        y: 3
        width: root.hw
        height: row.implicitHeight
        radius: root.innerRadius
        color: TallyTheme.segOn
        visible: root.hw > 0
        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    }

    Row {
        id: row
        x: 3
        y: 3
        spacing: 2
        Repeater {
            id: rep
            model: root.model
            Item {
                id: seg
                required property int index
                required property var modelData
                width: root.fill ? (root.width - 6 - 2 * (root.model.length - 1)) / root.model.length : label.implicitWidth + root.hPad * 2
                height: label.implicitHeight + root.vPad * 2
                onXChanged: if (index === root.currentIndex) root.follow()
                onWidthChanged: if (index === root.currentIndex) root.follow()
                Component.onCompleted: if (index === root.currentIndex) root.follow()
                TText {
                    id: label
                    anchors.centerIn: parent
                    px: root.px
                    text: seg.modelData
                    color: seg.index === root.currentIndex ? TallyTheme.fg : TallyTheme.muted
                    font.weight: seg.index === root.currentIndex ? Font.Medium : Font.Normal
                    Behavior on color { ColorAnimation { duration: 160 } }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(seg.index)
                }
            }
        }
    }
}
