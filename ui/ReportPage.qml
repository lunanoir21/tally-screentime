import QtQuick
import QtQuick.Layouts

// Report style "Page": a ruled A4 sheet (794 x 1123 at 96 dpi).
Rectangle {
    id: root

    property var report
    property bool paper: false
    readonly property real pixelScale: 2

    width: 794
    height: 1123
    color: pal.card

    TReportPalette { id: pal; paper: root.paper }
    TReportModel { id: m; data: root.report }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 56
        spacing: 0

        // masthead
        Item {
            Layout.fillWidth: true
            implicitHeight: 40
            Row {
                spacing: 12
                anchors.verticalCenter: parent.verticalCenter
                TMark { anchors.verticalCenter: parent.verticalCenter; size: 34; ink: pal.fg; accent: pal.acc }
                TBig { anchors.verticalCenter: parent.verticalCenter; bigPx: 26; wght: 500; color: pal.fg; text: "tally" }
            }
            Column {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                TText { anchors.right: parent.right; px: 10; font.weight: Font.Medium; font.letterSpacing: 1.6; color: pal.muted; text: m.title }
                TText { anchors.right: parent.right; px: 13; font.weight: Font.Medium; color: pal.fg; text: m.period }
            }
        }
        Item { Layout.fillHeight: true }

        // hero
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: pal.fg }
        TText { Layout.topMargin: 18; px: 10; font.weight: Font.Medium; font.letterSpacing: 1.6; color: pal.muted; text: m.heroLabel }
        Item {
            Layout.fillWidth: true
            Layout.topMargin: 4
            implicitHeight: 108
            TDuration { ms: m.heroMs; bigPx: 118; unitPx: 24; unitMargin: 10; gap: 8; ink: pal.fg; unitInk: pal.muted }
            Rectangle {
                visible: m.hasDelta
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 8
                width: dRow.width + 24
                height: 32
                radius: 10
                color: "transparent"
                border.width: 1
                border.color: pal.fg
                Row {
                    id: dRow
                    anchors.centerIn: parent
                    spacing: 6
                    TText { px: 12; font.weight: Font.Medium; color: pal.fg; text: (m.deltaUp ? "▲ " : "▼ ") + m.deltaText }
                    TText { px: 12; color: pal.muted; text: m.deltaSuffix }
                }
            }
        }
        Item { Layout.fillHeight: true }

        // goal ruler
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10
            visible: m.hasGoal
            Item {
                Layout.fillWidth: true
                implicitHeight: 16
                TText { px: 12; color: pal.muted; text: Str.dailyGoal(m.data.goalMs / 3600000) }
                TText { anchors.right: parent.right; px: 12; font.weight: Font.Medium; color: pal.fg; text: m.rulerRight }
            }
            TRuler { Layout.fillWidth: true; count: 40; filled: m.filled; major: 10; tickWidth: 7; tallHeight: 26; shortHeight: 16; onColor: pal.fg; offColor: pal.tickOff; accentColor: pal.acc }
            TSpaceRow { Layout.fillWidth: true; items: m.rulerMarks; px: 11; color: pal.muted }
        }
        Item { Layout.fillHeight: true; visible: m.hasGoal }

        // chart
        Item {
            Layout.fillWidth: true
            implicitHeight: 13
            TText { px: 10; font.weight: Font.Medium; font.letterSpacing: 1.6; color: pal.muted; text: m.chartTitle }
            TText { anchors.right: parent.right; px: 10; color: pal.muted; text: m.chartNote }
        }
        TReportChart {
            Layout.fillWidth: true
            Layout.topMargin: 10
            m: m
            pal: pal
            chartHeight: 150
            gap: m.data.seriesKind === "hour" ? 4 : m.data.seriesKind === "week" ? 8 : 14
            labelPx: 12
            subPx: 11
            showBaseline: true
        }
        Item { Layout.fillHeight: true }

        // apps and hours
        RowLayout {
            Layout.fillWidth: true
            spacing: 36
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 12
                TText { px: 10; font.weight: Font.Medium; font.letterSpacing: 1.6; color: pal.muted; text: Str.topApps }
                TReportApps { Layout.fillWidth: true; m: m; pal: pal; tile: 32; namePx: 13; timePx: 13; rowGap: 10 }
            }
            ColumnLayout {
                Layout.preferredWidth: 270
                Layout.maximumWidth: 270
                Layout.alignment: Qt.AlignTop
                spacing: 12
                visible: m.showHours
                TText { px: 10; font.weight: Font.Medium; font.letterSpacing: 1.6; color: pal.muted; text: Str.hourlyTotal }
                TReportHours { Layout.fillWidth: true; m: m; pal: pal; chartHeight: 96; showBaseline: true }
                TText { px: 12; color: pal.muted; text: m.peakText }
                TText { Layout.fillWidth: true; px: 11; color: pal.muted; visible: m.hoursNote !== ""; wrapMode: Text.WordWrap; text: m.hoursNote }
            }
        }
        Item { Layout.fillHeight: true }

        // figures
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 72
            radius: 10
            color: "transparent"
            border.width: 1
            border.color: pal.fg
            TReportTrio { anchors.fill: parent; items: m.trio; pal: pal; outlined: true; pad: 14 }
        }
        Item { Layout.fillHeight: true }

        // footer
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: pal.hair }
        Item {
            Layout.fillWidth: true
            Layout.topMargin: 12
            implicitHeight: 14
            TText { px: 11; color: pal.muted; text: m.generated }
            TText { anchors.right: parent.right; px: 11; color: pal.muted; text: Str.privacy }
        }
    }
}
