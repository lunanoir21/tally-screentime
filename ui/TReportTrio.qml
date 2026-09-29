import QtQuick

// Three figures side by side.
Row {
    id: c

    property var items: []
    property var pal
    property real labelPx: 11
    property real valuePx: 17
    property real pad: 14
    property real radius: 12
    property bool outlined: false
    property real cellGap: 10

    spacing: outlined ? 0 : cellGap

    Repeater {
        model: c.items
        Rectangle {
            required property int index
            required property var modelData
            width: (c.width - (c.outlined ? 0 : c.cellGap * 2)) / 3
            height: col.implicitHeight + c.pad * 2
            radius: c.outlined ? 0 : c.radius
            color: c.outlined ? "transparent" : c.pal.panel
            Rectangle { visible: c.outlined && index > 0; width: 1; height: parent.height; color: c.pal.fg }
            Column {
                id: col
                x: c.pad + 2
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                TText { width: (c.width - (c.outlined ? 0 : c.cellGap * 2)) / 3 - c.pad * 2 - 2; elide: Text.ElideRight; px: c.labelPx; color: c.pal.muted; text: modelData.label }
                TText { width: (c.width - (c.outlined ? 0 : c.cellGap * 2)) / 3 - c.pad * 2 - 2; elide: Text.ElideRight; px: c.valuePx; font.weight: Font.Medium; color: c.pal.fg; text: modelData.value }
            }
        }
    }
}
