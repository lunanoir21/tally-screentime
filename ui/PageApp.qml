import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "js/Model.js" as Model

// Uygulama detayı: today, fourteen days, session stats, daily limit.
ColumnLayout {
    id: root

    readonly property real pageHeight: 772
    readonly property string id: TallyStore.appId
    readonly property string key: TallyStore.viewKey || TallyTracker.todayKey
    readonly property var lim: TallyStore.limitOf(id)
    readonly property real limMs: lim.min * 60000
    readonly property var days: {
        var out = [];
        for (var i = 13; i >= 0; i--) {
            var k = Model.shiftKey(TallyTracker.todayKey, -i);
            var d = TallyTracker.day(k);
            out.push({ key: k, ms: d.apps[id] || 0, s: (d.s || {})[id] || [0, 0] });
        }
        return out;
    }
    readonly property real todayMs: days[13].ms
    readonly property real todayTotal: TallyTracker.today.total
    readonly property real avg: days.reduce((a, x) => a + x.ms, 0) / 14
    readonly property real maxMs: Math.max.apply(null, days.map(x => x.ms))
    readonly property real scaleMin: Math.max(maxMs / 60000, lim.on ? lim.min * 1.5 : 0, 30)
    readonly property bool excluded: TallyStore.isExcluded(id)

    spacing: 0

    Item {
        Layout.fillWidth: true
        implicitHeight: 32
        Rectangle {
            width: back.width + 20
            height: 32
            radius: 10
            color: TallyTheme.ctl
            Row {
                id: back
                x: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                TIcon { anchors.verticalCenter: parent.verticalCenter; name: "left"; size: 14; stroke: 2; color: TallyTheme.fg }
                TText { px: 11.5; font.weight: Font.Medium; text: Str.apps }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: TallyStore.goto(TallyStore.backPage === "day" ? "apps" : TallyStore.backPage) }
        }
        TIconButton { anchors.right: parent.right; icon: "close"; onClicked: TallyStore.closePanel() }
    }

    Row {
        Layout.topMargin: 20
        spacing: 14
        TAppIcon { appId: root.id; name: TallyTracker.appName(root.id); size: 56; letterPx: 24 }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            TBig { bigPx: 30; wght: 500; text: TallyTracker.appName(root.id) }
            TText { px: 11; color: TallyTheme.muted; text: Str.appId(root.id) }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.topMargin: 20
        implicitHeight: 76
        TLabel { text: Str.todayCaps }
        TDuration { y: 15; ms: root.todayMs; bigPx: 64; unitPx: 17; unitMargin: 7 }
        Rectangle {
            visible: root.todayTotal > 0
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            width: shareRow.width + 18
            height: 26
            radius: 9
            color: TallyTheme.ctl
            Row {
                id: shareRow
                anchors.centerIn: parent
                spacing: 5
                TText { px: 11; font.weight: Font.Medium; text: "%" + Math.round(root.todayMs / Math.max(1, root.todayTotal) * 100) }
                TText { px: 11; color: TallyTheme.muted; text: Str.ofTotal }
            }
        }
    }

    // ---- 14 days ------------------------------------------------------------------------------
    Item {
        Layout.fillWidth: true
        Layout.topMargin: 22
        implicitHeight: 13
        TLabel { text: Str.last14 }
        TText { anchors.right: parent.right; px: 10; color: TallyTheme.muted; visible: root.lim.on; text: Str.dashedLimit(root.lim.min / 60) }
    }
    Item {
        Layout.fillWidth: true
        Layout.topMargin: 10
        implicitHeight: 84
        Shape {
            visible: root.lim.on
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: TallyTheme.alpha(TallyTheme.fg, 0.26)
                strokeWidth: 1
                strokeStyle: ShapePath.DashLine
                dashPattern: [3, 3]
                fillColor: "transparent"
                startX: 0
                startY: 84 - Math.min(84, root.lim.min / root.scaleMin * 84) + 0.5
                PathLine { x: 360; y: 84 - Math.min(84, root.lim.min / root.scaleMin * 84) + 0.5 }
            }
        }
        Row {
            anchors.fill: parent
            spacing: 5
            Repeater {
                model: root.days
                Item {
                    required property int index
                    required property var modelData
                    width: (parent.width - 13 * 5) / 14
                    height: parent.height
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: Math.max(2, Math.round(modelData.ms / 60000 / root.scaleMin * 84))
                        topLeftRadius: 4
                        topRightRadius: 4
                        bottomLeftRadius: 2
                        bottomRightRadius: 2
                        color: index === 13 ? TallyTheme.acc
                             : (root.lim.on && modelData.ms > root.limMs) ? TallyTheme.fg
                             : TallyTheme.alpha(TallyTheme.fg, 0.30)
                    }
                }
            }
        }
    }
    TSpaceRow { Layout.fillWidth: true; Layout.topMargin: 6; items: [Str.shortDate(root.days[0].key), Str.shortDate(root.days[7].key), Str.shortDate(root.days[13].key)] }

    GridLayout {
        Layout.fillWidth: true
        Layout.topMargin: 18
        columns: 3
        columnSpacing: 8
        TStatCell { Layout.fillWidth: true; Layout.preferredWidth: 1; label: Str.sessionsToday; value: String(root.days[13].s[0]) }
        TStatCell { Layout.fillWidth: true; Layout.preferredWidth: 1; label: Str.longest; value: Str.fmt(root.days[13].s[1]) }
        TStatCell { Layout.fillWidth: true; Layout.preferredWidth: 1; label: Str.avg14; value: Str.fmt(root.avg) }
    }

    // ---- Limit ---------------------------------------------------------------------------------------
    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 22
        implicitHeight: limitCol.implicitHeight + 28
        radius: 14
        color: "transparent"
        border.width: 1
        border.color: TallyTheme.alpha(TallyTheme.fg, 0.10)

        ColumnLayout {
            id: limitCol
            x: 14
            y: 14
            width: parent.width - 28
            spacing: 13

            Item {
                Layout.fillWidth: true
                implicitHeight: 22
                TText { anchors.verticalCenter: parent.verticalCenter; px: 13; font.weight: Font.Medium; text: Str.dailyLimit }
                TSwitch {
                    anchors.right: parent.right
                    checked: root.lim.on
                    onToggled: value => TallyStore.setLimit(root.id, { on: value })
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 13
                opacity: root.lim.on ? 1 : 0.45
                enabled: root.lim.on

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 30
                    Rectangle {
                        width: 30; height: 30; radius: 9
                        color: TallyTheme.alpha(TallyTheme.fg, 0.08)
                        TText { anchors.centerIn: parent; px: 15; font.weight: Font.Medium; text: "−" }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: TallyStore.setLimit(root.id, { min: Math.max(30, root.lim.min - 30) }) }
                    }
                    TText { anchors.centerIn: parent; px: 18; font.weight: Font.Medium; text: Str.fmtHours(root.lim.min / 60) }
                    Rectangle {
                        anchors.right: parent.right
                        width: 30; height: 30; radius: 9
                        color: TallyTheme.alpha(TallyTheme.fg, 0.08)
                        TText { anchors.centerIn: parent; px: 15; font.weight: Font.Medium; text: "+" }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: TallyStore.setLimit(root.id, { min: Math.min(720, root.lim.min + 30) }) }
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 4
                        radius: 2
                        color: TallyTheme.track
                        Rectangle { width: parent.width * Math.min(1, root.todayMs / Math.max(1, root.limMs)); height: 4; radius: 2; color: TallyTheme.acc }
                    }
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 14
                        TText { px: 10.5; color: TallyTheme.muted; text: Str.used(Str.fmt(root.todayMs)) }
                        TText { anchors.right: parent.right; px: 10.5; text: root.todayMs >= root.limMs ? Str.limitExceeded : Str.leftOf(Str.fmt(root.limMs - root.todayMs)) }
                    }
                }
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 28
                    TText { anchors.verticalCenter: parent.verticalCenter; px: 11.5; color: TallyTheme.muted; text: Str.atLimit }
                    TSegmented {
                        anchors.right: parent.right
                        model: [Str.modeNotify, Str.modeWarn, Str.modeDim]
                        currentIndex: Math.max(0, ["notify", "warn", "dim"].indexOf(root.lim.mode))
                        onPicked: index => TallyStore.setLimit(root.id, { mode: ["notify", "warn", "dim"][index] })
                    }
                }
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.topMargin: 14
        implicitHeight: 22
        TText { x: 4; anchors.verticalCenter: parent.verticalCenter; px: 12; text: Str.stopTracking }
        TSwitch {
            anchors.right: parent.right
            checked: root.excluded
            onToggled: value => {
                if (value) { TallyStore.exclude(root.id); TallyStore.goto("apps"); }
                else TallyStore.include(root.id);
            }
        }
    }

    Item { Layout.fillHeight: true }
}
