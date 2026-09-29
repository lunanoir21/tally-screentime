import QtQuick

// A row of short labels with equal gaps between them (justify: space-between).
Item {
    id: root

    property var items: []
    property real px: 10
    property color color: TallyTheme.faint

    implicitHeight: px * 1.4

    function layout() {
        var n = root.items.length;
        var sum = 0;
        for (var i = 0; i < n; i++) {
            var it = rep.itemAt(i);
            if (!it)
                return;
            sum += it.implicitWidth;
        }
        var gap = n > 1 ? (root.width - sum) / (n - 1) : 0;
        var x = 0;
        for (var j = 0; j < n; j++) {
            var t = rep.itemAt(j);
            t.x = x;
            x += t.implicitWidth + gap;
        }
    }
    onWidthChanged: layout()
    onItemsChanged: Qt.callLater(layout)

    Repeater {
        id: rep
        model: root.items
        TText {
            required property var modelData
            px: root.px
            color: root.color
            text: modelData
            onImplicitWidthChanged: root.layout()
            Component.onCompleted: root.layout()
        }
    }
}
