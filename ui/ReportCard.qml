import QtQuick
import QtQuick.Layouts

// Report style "Card": a 1080 x 1350 picture made to be shared.
Rectangle {
    id: root

    property var report
    property bool paper: false
    readonly property real pixelScale: 1

    width: 1080
    height: 1350
    color: pal.card

    TReportPalette { id: pal; paper: root.paper }
    TReportModel { id: m; data: root.report }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 76
        spacing: 0

        Item {
            Layout.fillWidth: true
            implicitHeight: 48
            Row {
                spacing: 16
                anchors.verticalCenter: parent.verticalCenter
                TMark { anchors.verticalCenter: parent.verticalCenter; size: 48; ink: pal.fg; accent: pal.acc }
                TBig { anchors.verticalCenter: parent.verticalCenter; bigPx: 36; wght: 500; color: pal.fg; text: "tally" }
            }
            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: pTxt.width + 36
                height: 44
                radius: 14
                color: "transparent"
                border.width: 1
                border.color: pal.line
                TText { id: pTxt; anchors.centerIn: parent; px: 18; font.weight: Font.Medium; font.letterSpacing: 1; color: pal.fg; text: m.period }
            }
        }
        Item { Layout.fillHeight: true }

        TText { px: 16; font.weight: Font.Medium; font.letterSpacing: 2.8; color: pal.muted; text: m.title + " · " + m.heroLabel }
        Item {
            Layout.fillWidth: true
            Layout.topMargin: 10
            implicitHeight: 262
            TDuration { ms: m.heroMs; bigPx: 280; unitPx: 40; unitMargin: 16; gap: 12; ink: pal.fg; unitInk: pal.muted }
        }
        Row {
            Layout.topMargin: 26
            spacing: 14
            Rectangle {
                visible: m.hasDelta
                width: dTxt.width + 28
                height: 40
                radius: 12
                color: pal.tile
                TText { id: dTxt; anchors.centerIn: parent; px: 20; font.weight: Font.Medium; color: pal.fg; text: (m.deltaUp ? "▲ " : "▼ ") + m.deltaText }
            }
            TText { anchors.verticalCenter: parent.verticalCenter; px: 20; color: pal.muted; text: (m.hasDelta ? m.deltaSuffix + " · " : "") + m.totalText }
        }
        Item { Layout.fillHeight: true }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 14
            visible: m.hasGoal
            Item {
                Layout.fillWidth: true
                implicitHeight: 22
                TText { px: 18; color: pal.muted; text: Str.dailyGoal(m.data.goalMs / 3600000) }
                TText { anchors.right: parent.right; px: 18; color: pal.fg; text: m.rulerRight }
            }
            TRuler { Layout.fillWidth: true; count: 40; filled: m.filled; major: 10; tickWidth: 10; tallHeight: 44; shortHeight: 28; onColor: pal.fg; offColor: pal.tickOff; accentColor: pal.acc }
        }
        Item { Layout.fillHeight: true; visible: m.hasGoal }

        Item {
            Layout.fillWidth: true
            implicitHeight: 18
            TText { px: 16; font.weight: Font.Medium; font.letterSpacing: 2.4; color: pal.muted; text: m.chartTitle }
            TText { anchors.right: parent.right; px: 16; color: pal.muted; text: m.chartNote }
        }
        TReportChart {
            Layout.fillWidth: true
            Layout.topMargin: 14
            m: m
            pal: pal
            chartHeight: 240
            gap: m.data.seriesKind === "hour" ? 6 : m.data.seriesKind === "week" ? 10 : 16
            radius: 10
            labelPx: 20
            subPx: 16
            dashWidth: 2
        }
        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 16
            Repeater {
                model: m.topApps.slice(0, 3)
                Rectangle {
                    required property int index
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    implicitHeight: 196
                    radius: 20
                    color: pal.panel
                    TAppIcon {
                        x: 22; y: 22
                        appId: modelData.id
                        name: modelData.id === "" ? "" : TallyTracker.appName(modelData.id)
                        other: modelData.id === ""
                        size: 52; letterPx: 22
                        color: pal.tile; ink: pal.fg; sync: true
                    }
                    TText { anchors.right: parent.right; anchors.rightMargin: 22; y: 30; px: 17; color: pal.muted; text: "%" + Math.round(modelData.share * 100) }
                    TBig { x: 22; y: 100; bigPx: 40; wght: 500; color: pal.fg; text: Str.fmt(modelData.ms) }
                    TText { x: 22; y: 156; px: 19; font.weight: Font.Medium; color: pal.muted; text: modelData.id === "" ? Str.others(modelData.other) : TallyTracker.appName(modelData.id) }
                }
            }
        }
        Item { Layout.fillHeight: true }

        Item {
            Layout.fillWidth: true
            implicitHeight: 18
            TText { px: 16; color: pal.muted; text: "tally-screentime" }
            TText { anchors.right: parent.right; px: 16; color: pal.muted; text: m.hoursNote !== "" ? m.hoursNote : Str.privacy }
        }
    }
}
