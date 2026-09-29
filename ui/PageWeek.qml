import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import "js/Model.js" as Model

// Hafta: seven days as bars against the goal line.
ColumnLayout {
    id: root

    readonly property real pageHeight: 740
    readonly property string endKey: TallyStore.weekEnd || TallyTracker.todayKey
    readonly property bool isCurrent: endKey >= TallyTracker.todayKey
    readonly property var list: {
        var out = [];
        for (var i = 6; i >= 0; i--) {
            var k = Model.shiftKey(endKey, -i);
            out.push({ key: k, day: TallyTracker.day(k) });
        }
        return out;
    }
    readonly property var prevList: {
        var out = [];
        for (var i = 13; i >= 7; i--)
            out.push(TallyTracker.day(Model.shiftKey(endKey, -i)));
        return out;
    }
    readonly property real sum: Model.sumTotal(list.map(x => x.day))
    readonly property real prevSum: Model.sumTotal(prevList)
    readonly property real goalMin: TallyStore.goalHours * 60
    readonly property real maxMin: Math.max.apply(null, list.map(x => x.day.total / 60000))
    readonly property real scaleMin: Math.max(goalMin * 1.11, maxMin, 60)
    readonly property int hits: list.filter(x => goalMin > 0 && x.day.total / 60000 >= goalMin).length
    readonly property var apps: Model.appRows(Model.mergeApps(list.map(x => x.day)), sum, 5)
    readonly property var longest: {
        var best = list[0];
        for (var i = 1; i < list.length; i++)
            if (list[i].day.total > best.day.total) best = list[i];
        return best;
    }

    function shift(n) {
        var next = Model.shiftKey(root.endKey, n);
        if (next > TallyTracker.todayKey)
            next = TallyTracker.todayKey;
        TallyStore.weekEnd = next === TallyTracker.todayKey ? "" : next;
    }
    function exportWeek() {
        var days = {};
        for (var i = 0; i < list.length; i++)
            days[list[i].key] = list[i].day;
        TallyTracker.exportTo(Quickshell.env("HOME") + "/tally-week-" + endKey + ".json", { days: days }, Str.weekExported);
    }

    spacing: 0


    TNav {
        Layout.fillWidth: true
        Layout.topMargin: 14
        title: root.isCurrent ? Str.last7 : Str.sevenDays
        subtitle: Str.shortDate(root.list[0].key) + " – " + Str.shortDate(root.endKey)
        canNext: !root.isCurrent
        onPrev: root.shift(-7)
        onNext: root.shift(7)
    }

    TLabel { Layout.topMargin: 16; text: Str.dailyAvg }
    Item {
        Layout.fillWidth: true
        Layout.topMargin: 2
        implicitHeight: 61
        TDuration { ms: root.sum / 7; bigPx: 64; unitPx: 17; unitMargin: 7 }
        Rectangle {
            visible: root.prevSum > 0
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            width: chipRow.width + 18
            height: 26
            radius: 9
            color: TallyTheme.ctl
            Row {
                id: chipRow
                anchors.centerIn: parent
                spacing: 5
                TIcon { anchors.verticalCenter: parent.verticalCenter; name: root.sum >= root.prevSum ? "up" : "down"; size: 11; stroke: 2.4; color: TallyTheme.acc }
                TText { px: 11; font.weight: Font.Medium; text: "%" + Math.round(Math.abs(root.sum - root.prevSum) / Math.max(1, root.prevSum) * 100) }
                TText { px: 11; color: TallyTheme.muted; text: Str.fromLastWeek }
            }
        }
    }

    // ---- Chart -----------------------------------------------------------------------
    Item {
        Layout.fillWidth: true
        Layout.topMargin: 20
        implicitHeight: 13
        TLabel { text: Str.dayByDay }
        TText { anchors.right: parent.right; px: 10; color: TallyTheme.muted; visible: root.goalMin > 0; text: Str.dashedGoal(TallyStore.goalHours) }
    }
    Item {
        Layout.fillWidth: true
        Layout.topMargin: 10
        implicitHeight: 130

        Shape {
            visible: root.goalMin > 0
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: TallyTheme.alpha(TallyTheme.fg, 0.26)
                strokeWidth: 1
                strokeStyle: ShapePath.DashLine
                dashPattern: [3, 3]
                fillColor: "transparent"
                startX: 0
                startY: 130 - Math.min(130, root.goalMin / root.scaleMin * 130) + 0.5
                PathLine { x: 360; y: 130 - Math.min(130, root.goalMin / root.scaleMin * 130) + 0.5 }
            }
        }
        Row {
            anchors.fill: parent
            spacing: 8
            Repeater {
                model: root.list
                Item {
                    required property int index
                    required property var modelData
                    readonly property real m: modelData.day.total / 60000
                    width: (parent.width - 6 * 8) / 7
                    height: parent.height
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: Math.max(2, Math.round(m / root.scaleMin * 130))
                        topLeftRadius: 6
                        topRightRadius: 6
                        bottomLeftRadius: 3
                        bottomRightRadius: 3
                        color: modelData.key === TallyTracker.todayKey ? TallyTheme.acc
                             : (root.goalMin > 0 && m >= root.goalMin) ? TallyTheme.fg
                             : TallyTheme.alpha(TallyTheme.fg, 0.30)
                    }
                }
            }
        }
    }
    Row {
        Layout.fillWidth: true
        Layout.topMargin: 8
        spacing: 8
        Repeater {
            model: root.list
            Column {
                required property var modelData
                width: (360 - 6 * 8) / 7
                spacing: 2
                TText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    px: 11
                    font.weight: modelData.key === TallyTracker.todayKey ? Font.Medium : Font.Normal
                    color: modelData.key === TallyTracker.todayKey ? TallyTheme.fg : TallyTheme.muted
                    text: Str.dayShort(Model.weekday(modelData.key))
                }
                TText { anchors.horizontalCenter: parent.horizontalCenter; px: 9.5; color: TallyTheme.muted; text: Str.fmtTight(modelData.day.total) }
            }
        }
    }

    // ---- Stats -----------------------------------------------------------------------------
    GridLayout {
        Layout.fillWidth: true
        Layout.topMargin: 18
        columns: 3
        columnSpacing: 8
        TStatCell { Layout.fillWidth: true; Layout.preferredWidth: 1; label: Str.total; value: Str.fmt(root.sum) }
        TStatCell { Layout.fillWidth: true; Layout.preferredWidth: 1; label: Str.longestDay; value: Str.dayShort(Model.weekday(root.longest.key)) + " · " + Str.fmt(root.longest.day.total) }
        TStatCell { Layout.fillWidth: true; Layout.preferredWidth: 1; label: Str.goalReached; value: Str.ofSeven(root.hits) }
    }

    // ---- Apps -----------------------------------------------------------------------------------
    TLabel { Layout.topMargin: 20; text: Str.topThisWeek }
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 10
        spacing: 11
        Repeater {
            model: root.apps
            TAppRow {
                required property int index
                required property var modelData
                Layout.fillWidth: true
                appId: modelData.id
                name: modelData.id === "" ? Str.others(modelData.other) : TallyTracker.appName(modelData.id)
                share: modelData.share
                rel: modelData.rel
                ms: modelData.ms
                lead: index === 0
                onClicked: TallyStore.openApp(modelData.id)
            }
        }
    }

    Item { Layout.fillHeight: true }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 42
        radius: 12
        color: "transparent"
        border.width: 1
        border.color: TallyTheme.outline
        TText { anchors.centerIn: parent; px: 12; font.weight: Font.Medium; text: Str.createReport }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: TallyStore.openExport("week") }
    }
}
