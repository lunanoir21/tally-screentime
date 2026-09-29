import QtQuick

// Colours of a report: the Tally theme in use, or light paper for printing.
QtObject {
    property bool paper: false

    readonly property color card: paper ? "#f6f4ef" : TallyTheme.card
    readonly property color fg: paper ? "#16150f" : TallyTheme.fg
    readonly property color acc: paper ? "#b8761f" : TallyTheme.acc
    // Printed text never goes lighter than about #767676.
    readonly property color muted: TallyTheme.mix(fg, card, paper ? 0.74 : 0.68)
    readonly property color faint: TallyTheme.mix(fg, card, 0.46)
    readonly property color line: TallyTheme.alpha(fg, paper ? 0.55 : 0.16)
    readonly property color hair: TallyTheme.alpha(fg, paper ? 0.28 : 0.10)
    readonly property color tickOff: TallyTheme.alpha(fg, paper ? 0.22 : 0.16)
    readonly property color tile: TallyTheme.alpha(fg, paper ? 0.10 : 0.09)
    readonly property color track: TallyTheme.alpha(fg, paper ? 0.16 : 0.10)
    readonly property color bar: TallyTheme.alpha(fg, paper ? 0.50 : 0.30)
    readonly property color panel: TallyTheme.alpha(fg, paper ? 0.05 : 0.06)
}
