import QtQuick

// The 24 hours of the day, summed over the report's range.
Item {
    id: c

    property var m
    property var pal
    property real chartHeight: 90
    property real gap: 3
    property real labelPx: 11
    property bool showBaseline: false

    implicitHeight: chartHeight + 6 + labelPx * 1.5

    Row {
        spacing: c.gap
        Repeater {
            model: 24
            Item {
                required property int index
                width: (c.width - c.gap * 23) / 24
                height: c.chartHeight
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: Math.max(2, Math.round(c.m.data.hours[index] / c.m.hourMax * c.chartHeight))
                    radius: 2
                    color: index === c.m.data.peakHour ? c.pal.acc : c.m.data.hours[index] === 0 ? c.pal.tickOff : c.pal.fg
                }
            }
        }
    }
    Rectangle { visible: c.showBaseline; y: c.chartHeight; width: parent.width; height: 1; color: c.pal.fg }
    TSpaceRow { y: c.chartHeight + 6; width: parent.width; items: ["00", "06", "12", "18", "24"]; px: c.labelPx; color: c.pal.muted }
}
