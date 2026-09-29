import QtQuick
import QtQuick.Shapes

// The report's bar chart: hours, days or weeks, with the goal as a dashed line.
Item {
    id: c

    property var m
    property var pal
    property real chartHeight: 150
    property real gap: 14
    property real labelPx: 12
    property real subPx: 11
    property real radius: 5
    property real dashWidth: 1
    property bool showBaseline: false

    readonly property int n: m.bars.length
    // A few bars must not stretch across the whole chart.
    readonly property real barW: n > 0 ? Math.min((width - gap * (n - 1)) / n, n <= 3 ? 72 : 100000) : 0

    implicitHeight: chartHeight + 8 + labels.height

    Item {
        id: plot
        width: c.width
        height: c.chartHeight

        Shape {
            visible: c.m.goalFrac > 0
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: c.pal.line
                strokeWidth: c.dashWidth
                strokeStyle: ShapePath.DashLine
                dashPattern: [3, 3]
                fillColor: "transparent"
                startX: 0
                startY: c.chartHeight * (1 - c.m.goalFrac)
                PathLine { x: c.width; y: c.chartHeight * (1 - c.m.goalFrac) }
            }
        }
        Row {
            spacing: c.gap
            Repeater {
                model: c.m.bars
                Item {
                    required property var modelData
                    width: c.barW
                    height: c.chartHeight
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: Math.max(2, Math.round(modelData.frac * c.chartHeight))
                        topLeftRadius: c.radius
                        topRightRadius: c.radius
                        bottomLeftRadius: Math.min(3, c.radius)
                        bottomRightRadius: Math.min(3, c.radius)
                        color: modelData.today ? c.pal.acc : modelData.hit ? c.pal.fg : c.pal.bar
                    }
                }
            }
        }
        Rectangle {
            visible: c.showBaseline
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: c.pal.fg
        }
    }

    Row {
        id: labels
        y: c.chartHeight + 8
        spacing: c.gap
        height: c.m.data.seriesKind === "day" ? c.labelPx * 1.5 + c.subPx * 1.5 : c.labelPx * 1.5
        Repeater {
            model: c.m.bars
            Item {
                required property var modelData
                width: c.barW
                height: parent.height
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 2
                    TText { anchors.horizontalCenter: parent.horizontalCenter; px: c.labelPx; font.weight: modelData.today ? Font.Medium : Font.Normal; color: modelData.today ? c.pal.fg : c.pal.muted; text: modelData.label }
                    TText { anchors.horizontalCenter: parent.horizontalCenter; px: c.subPx; color: c.pal.muted; text: modelData.sub; visible: modelData.sub !== "" }
                }
            }
        }
    }
}
