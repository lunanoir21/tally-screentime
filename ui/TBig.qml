import QtQuick

// Display numerals: Bricolage Grotesque at its light weight.
Text {
    property real bigPx: 64
    property int wght: 300

    font.family: TallyTheme.display
    font.pixelSize: bigPx
    font.letterSpacing: -bigPx * 0.03
    font.variableAxes: ({ "wght": wght, "opsz": Math.min(96, Math.max(12, bigPx)), "wdth": 100 })
    color: TallyTheme.fg
    lineHeight: 0.95
    lineHeightMode: Text.ProportionalHeight
    textFormat: Text.PlainText
    renderType: Text.NativeRendering
}
