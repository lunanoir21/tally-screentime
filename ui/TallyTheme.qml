pragma Singleton
import QtQuick
import "js/Themes.js" as Themes

// Three colours per theme (surface, ink, accent); every other tone is
// mixed from them, so a new theme is one line in js/Themes.js.
Item {
    id: root

    FontLoader { source: Qt.resolvedUrl("fonts/JetBrainsMono-Regular.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/JetBrainsMono-Medium.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/JetBrainsMono-Bold.ttf") }
    FontLoader { id: displayLoader; source: Qt.resolvedUrl("fonts/BricolageGrotesque.ttf") }

    readonly property string mono: "JetBrains Mono"
    readonly property string display: displayLoader.status === FontLoader.Ready ? displayLoader.name : "sans-serif"

    function mix(a, b, t) {
        return Qt.rgba(a.r * t + b.r * (1 - t), a.g * t + b.g * (1 - t), a.b * t + b.b * (1 - t), 1);
    }
    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    readonly property var current: Themes.byId(TallyStore.effectiveThemeId)

    readonly property color card: current.card
    readonly property color fg: current.fg
    readonly property color acc: current.acc

    readonly property color muted: mix(fg, card, 0.70)
    readonly property color faint: mix(fg, card, 0.42)

    readonly property color hair: alpha(fg, 0.09)        // card border
    readonly property color line: alpha(fg, 0.07)        // row dividers
    readonly property color ctl: alpha(fg, 0.07)         // icon buttons
    readonly property color ctlHover: alpha(fg, 0.12)
    readonly property color segBg: alpha(fg, 0.06)
    readonly property color segOn: alpha(fg, 0.13)
    readonly property color track: alpha(fg, 0.09)
    readonly property color tickOff: alpha(fg, 0.15)
    readonly property color cell: alpha(fg, 0.05)        // stat cells
    readonly property color tile: alpha(fg, 0.08)        // app monogram
    readonly property color outline: alpha(fg, 0.14)     // ghost buttons
    readonly property color bar: mix(fg, card, 0.55)     // non-leading bars
    readonly property color bad: "#e0876a"

    // Heatmap steps (share of the daily goal): empty, <25 %, <50 %, <75 %, more.
    readonly property var heat: [alpha(fg, 0.06), alpha(fg, 0.20), alpha(fg, 0.38), alpha(fg, 0.62), alpha(fg, 0.92)]
}
