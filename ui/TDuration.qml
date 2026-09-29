import QtQuick

// "4 s 12 d": display numerals (Bricolage, light) with small mono units
// sitting on the same baseline.
Item {
    id: root

    property double ms: 0
    property real bigPx: 84
    property real unitPx: 20
    property real gap: 6
    property real unitMargin: 8
    property color ink: TallyTheme.fg
    property color unitInk: TallyTheme.muted
    readonly property int totalMin: Math.floor(Math.max(0, ms) / 60000)
    readonly property int hours: Math.floor(totalMin / 60)
    readonly property int mins: totalMin % 60

    implicitWidth: dUnit.x + dUnit.width
    implicitHeight: Math.round(bigPx * 0.95)

    component Big: Text {
        font.family: TallyTheme.display
        font.pixelSize: root.bigPx
        font.letterSpacing: -root.bigPx * 0.03
        font.variableAxes: ({ "wght": 300, "opsz": 72, "wdth": 100 })
        color: root.ink
        lineHeight: 0.95
        lineHeightMode: Text.ProportionalHeight
        renderType: Text.NativeRendering
    }
    component Unit: TText {
        px: root.unitPx
        color: root.unitInk
    }

    Big { id: hNum; visible: root.hours > 0; text: root.hours }
    Unit {
        id: hUnit
        visible: root.hours > 0
        text: Str.uh
        x: hNum.width + root.gap
        y: hNum.baselineOffset - baselineOffset
    }
    Big {
        id: mNum
        x: root.hours > 0 ? hUnit.x + hUnit.width + root.gap + root.unitMargin : 0
        text: root.mins
    }
    Unit {
        id: dUnit
        text: Str.um
        x: mNum.x + mNum.width + root.gap
        y: mNum.baselineOffset - baselineOffset
    }
}
