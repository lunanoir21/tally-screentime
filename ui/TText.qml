import QtQuick

// The one text primitive: mono, themed ink, plain text (external strings
// such as window titles must never be interpreted as rich text).
Text {
    property real px: 12
    color: TallyTheme.fg
    font.family: TallyTheme.mono
    font.pixelSize: px
    textFormat: Text.PlainText
    renderType: Text.NativeRendering
}
