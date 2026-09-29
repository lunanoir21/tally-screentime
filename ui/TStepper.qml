import QtQuick

// [ - ]  6s 00d  [ + ]
Row {
    id: root

    property string text: ""
    property real minWidth: 66
    property real btn: 28
    property real px: 14
    signal dec()
    signal inc()

    spacing: 8

    component Btn: Rectangle {
        property string glyph: "−"
        signal hit()
        width: root.btn
        height: root.btn
        radius: 9
        color: ma.containsMouse ? TallyTheme.ctlHover : TallyTheme.alpha(TallyTheme.fg, 0.08)
        TText { anchors.centerIn: parent; px: 14; font.weight: Font.Medium; text: parent.glyph }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.hit() }
    }

    Btn { glyph: "−"; onHit: root.dec() }
    Item {
        width: Math.max(root.minWidth, label.implicitWidth)
        height: root.btn
        TText { id: label; anchors.centerIn: parent; px: root.px; font.weight: Font.Medium; text: root.text }
    }
    Btn { glyph: "+"; onHit: root.inc() }
}
