import QtQuick
import QtQuick.Layouts

// Report style "Board": a 1600 x 900 dashboard, everything at a glance.
Rectangle {
    id: root

    property var report
    property bool paper: false
    readonly property real pixelScale: 2

    width: 1600
    height: 900
    color: pal.card

    TReportPalette { id: pal; paper: root.paper }
    TReportModel { id: m; data: root.report }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 56
        spacing: 0

        Item {
            Layout.fillWidth: true
            implicitHeight: 40
            Row {
                spacing: 14
                anchors.verticalCenter: parent.verticalCenter
                TMark { anchors.verticalCenter: parent.verticalCenter; size: 40; ink: pal.fg; accent: pal.acc }
                TBig { anchors.verticalCenter: parent.verticalCenter; bigPx: 30; wght: 500; color: pal.fg; text: "tally" }
            }
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 18
                TText { px: 16; font.weight: Font.Medium; font.letterSpacing: 2.4; color: pal.muted; text: m.title }
                TText { px: 16; font.weight: Font.Medium; color: pal.fg; text: m.period }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 34
            Layout.bottomMargin: 30
            spacing: 48

            // hero
            ColumnLayout {
                Layout.preferredWidth: 420
                Layout.fillHeight: true
                spacing: 0
                TText { px: 12; font.weight: Font.Medium; font.letterSpacing: 1.8; color: pal.muted; text: m.heroLabel }
                Item {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    implicitHeight: 152
                    TDuration { ms: m.heroMs; bigPx: 168; unitPx: 28; unitMargin: 10; gap: 8; ink: pal.fg; unitInk: pal.muted }
                }
                Row {
                    Layout.topMargin: 10
                    spacing: 10
                    visible: m.hasDelta
                    TText { px: 15; font.weight: Font.Medium; color: pal.fg; text: (m.deltaUp ? "▲ " : "▼ ") + m.deltaText }
                    TText { px: 15; color: pal.muted; text: m.deltaSuffix }
                }
                Item { Layout.fillHeight: true }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    visible: m.hasGoal
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 18
                        TText { px: 14; color: pal.muted; text: Str.dailyGoal(m.data.goalMs / 3600000) }
                        TText { anchors.right: parent.right; px: 14; color: pal.fg; text: "%" + Math.round(m.ratio * 100) }
                    }
                    TRuler { Layout.fillWidth: true; count: 40; filled: m.filled; major: 10; tickWidth: 6; tallHeight: 30; shortHeight: 20; onColor: pal.fg; offColor: pal.tickOff; accentColor: pal.acc }
                }
                Item { Layout.fillHeight: true }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Repeater {
                        model: m.trio
                        Item {
                            required property int index
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 46
                            Rectangle { visible: index > 0; width: parent.width; height: 1; color: pal.hair }
                            TText { anchors.verticalCenter: parent.verticalCenter; px: 13; color: pal.muted; text: modelData.label }
                            TText { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; px: 16; font.weight: Font.Medium; color: pal.fg; text: modelData.value }
                        }
                    }
                }
            }

            // charts
            ColumnLayout {
                Layout.preferredWidth: 640
                Layout.fillHeight: true
                spacing: 0
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 16
                    TText { px: 12; font.weight: Font.Medium; font.letterSpacing: 1.8; color: pal.muted; text: m.chartTitle }
                    TText { anchors.right: parent.right; px: 12; color: pal.muted; text: m.chartNote }
                }
                TReportChart {
                    Layout.fillWidth: true
                    Layout.topMargin: 12
                    m: m
                    pal: pal
                    chartHeight: 330
                    gap: m.data.seriesKind === "hour" ? 6 : m.data.seriesKind === "week" ? 10 : 14
                    radius: 10
                    labelPx: 15
                    subPx: 13
                    dashWidth: 2
                }
                Item { Layout.fillHeight: true }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    visible: m.showHours
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 16
                        TText { px: 12; font.weight: Font.Medium; font.letterSpacing: 1.8; color: pal.muted; text: Str.hourlyTotal }
                        TText { anchors.right: parent.right; px: 12; color: pal.muted; text: m.peakText }
                    }
                    TReportHours { Layout.fillWidth: true; m: m; pal: pal; chartHeight: 84; gap: 4; labelPx: 12 }
                }
            }

            // apps
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 18
                TText { px: 12; font.weight: Font.Medium; font.letterSpacing: 1.8; color: pal.muted; text: Str.topApps }
                TReportApps { Layout.fillWidth: true; m: m; pal: pal; tile: 40; namePx: 16; timePx: 15; rowGap: 22; barH: 4 }
                Item { Layout.fillHeight: true }
            }
        }
        Item {
            Layout.fillWidth: true
            implicitHeight: 16
            TText { px: 13; color: pal.muted; text: "tally-screentime · " + m.generated }
            TText { anchors.right: parent.right; px: 13; color: pal.muted; text: m.hoursNote !== "" ? m.hoursNote : Str.privacy }
        }
    }
}
