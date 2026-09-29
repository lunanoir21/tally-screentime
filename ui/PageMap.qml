import QtQuick
import QtQuick.Layouts
import "js/Model.js" as Model

// Harita: sixteen weeks as a calendar heatmap, plus the shape of a week.
ColumnLayout {
    id: root

    readonly property real pageHeight: 740
    readonly property int weeks: 16
    readonly property real goalMs: (TallyStore.goalHours > 0 ? TallyStore.goalHours : 6) * 3600000
    readonly property string today: TallyTracker.todayKey
    readonly property string pick: TallyStore.mapPick || today

    // Column-major: index = week * 7 + weekday, oldest first.
    readonly property var cells: {
        var t = Model.keyToDate(today);
        var dow = (t.getDay() + 6) % 7;
        var start = new Date(t);
        start.setDate(start.getDate() - dow - (weeks - 1) * 7);
        var out = [];
        for (var n = 0; n < weeks * 7; n++) {
            var d = new Date(start);
            d.setDate(start.getDate() + n);
            var key = Model.dayKey(d);
            out.push({ key: key, ms: key > today ? -1 : TallyTracker.day(key).total });
        }
        return out;
    }
    readonly property var past: cells.filter(c => c.ms >= 0)
    readonly property real total: past.reduce((a, c) => a + c.ms, 0)
    readonly property var stats: {
        var peak = null, hits = 0, run = 0, best = 0, recorded = 0;
        var sums = [0, 0, 0, 0, 0, 0, 0], cnt = [0, 0, 0, 0, 0, 0, 0];
        for (var i = 0; i < past.length; i++) {
            var c = past[i];
            if (!peak || c.ms > peak.ms) peak = c;
            if (c.ms >= goalMs) hits++;
            if (c.ms >= goalMs / 2) { run++; best = Math.max(best, run); } else run = 0;
            if (c.ms > 0) recorded++;
            var w = Model.weekday(c.key);
            sums[w] += c.ms; cnt[w]++;
        }
        var avgs = sums.map((s, w) => cnt[w] ? s / cnt[w] : 0);
        return { peak: peak, hits: hits, streak: best, recorded: recorded, avgs: avgs, avgMax: Math.max.apply(null, avgs) };
    }
    readonly property var months: {
        var out = [], prev = -1;
        for (var w = 0; w < weeks; w++) {
            var m = Model.keyToDate(cells[w * 7].key).getMonth();
            if (m !== prev) { prev = m; out.push({ month: m, col: w }); }
        }
        return out;
    }

    function level(ms) {
        if (ms < 60000) return 0;
        var r = ms / goalMs;
        return r < 0.25 ? 1 : r < 0.5 ? 2 : r < 0.75 ? 3 : 4;
    }
    function goalLabel() {
        var min = goalMs / 120000;
        var h = Math.floor(min / 60), m = Math.round(min % 60);
        return m === 0 ? h + "s" : h > 0 ? h + "s " + m + "d" : m + "d";
    }

    spacing: 0


    TLabel { Layout.topMargin: 16; text: Str.last16 }
    Row {
        Layout.topMargin: 2
        spacing: 6
        TBig { id: hoursBig; bigPx: 64; text: Math.round(root.total / 3600000) }
        TText { y: hoursBig.baselineOffset - baselineOffset; px: 17; color: TallyTheme.muted; text: Str.hoursWord }
    }

    // ---- Heatmap --------------------------------------------------------------------------
    Item {
        Layout.fillWidth: true
        Layout.topMargin: 20
        implicitHeight: 166

        Repeater {
            model: root.months
            TText {
                required property var modelData
                x: 27 + modelData.col * 21
                px: 10
                color: TallyTheme.muted
                text: Str.month(modelData.month)
            }
        }
        Repeater {
            model: [[Str.mapDays[0], 0], [Str.mapDays[1], 2], [Str.mapDays[2], 4], [Str.mapDays[3], 6]]
            TText {
                required property var modelData
                y: 22 + modelData[1] * 21 + 3
                px: 9.5
                color: TallyTheme.faint
                text: modelData[0]
            }
        }
        Grid {
            x: 27
            y: 22
            rows: 7
            columns: root.weeks
            flow: Grid.TopToBottom
            spacing: 3
            Repeater {
                model: root.cells
                Item {
                    id: cell
                    required property var modelData
                    width: 18
                    height: 18
                    Rectangle {
                        anchors.fill: parent
                        radius: 5
                        color: cell.modelData.ms < 0 ? "transparent" : TallyTheme.heat[root.level(cell.modelData.ms)]
                        border.width: cell.modelData.ms < 0 ? 1 : 0
                        border.color: TallyTheme.alpha(TallyTheme.fg, 0.10)
                    }
                    Rectangle {
                        visible: cell.modelData.key === root.today || cell.modelData.key === root.pick
                        anchors.fill: parent
                        anchors.margins: -2.5
                        radius: 7
                        color: "transparent"
                        border.width: 1.5
                        border.color: cell.modelData.key === root.pick && root.pick !== root.today ? TallyTheme.fg : TallyTheme.acc
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: cell.modelData.ms >= 0
                        cursorShape: Qt.PointingHandCursor
                        onClicked: TallyStore.mapPick = cell.modelData.key
                    }
                }
            }
        }
    }
    Row {
        Layout.alignment: Qt.AlignRight
        Layout.topMargin: 8
        spacing: 5
        TText { px: 10; color: TallyTheme.muted; text: Str.less; anchors.verticalCenter: parent.verticalCenter }
        Repeater {
            model: 5
            Rectangle { required property int index; width: 12; height: 12; radius: 4; color: TallyTheme.heat[index]; anchors.verticalCenter: parent.verticalCenter }
        }
        TText { px: 10; color: TallyTheme.muted; text: Str.more; anchors.verticalCenter: parent.verticalCenter }
    }

    // ---- Picked day ---------------------------------------------------------------------------
    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 14
        implicitHeight: 62
        radius: 13
        color: TallyTheme.cell
        Column {
            x: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            TText { px: 10; color: TallyTheme.muted; text: Str.pickedDay }
            TText { px: 13; font.weight: Font.Medium; text: Str.dayShort(Model.weekday(root.pick)) + " " + Str.shortDate(root.pick) }
        }
        TBig {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            bigPx: 30
            text: Str.fmt(TallyTracker.day(root.pick).total)
        }
    }

    // ---- Weekday rhythm ---------------------------------------------------------------------------
    TLabel { Layout.topMargin: 24; text: Str.weekRhythm }
    Row {
        Layout.fillWidth: true
        Layout.topMargin: 12
        spacing: 10
        Repeater {
            model: 7
            Item {
                required property int index
                width: (360 - 6 * 10) / 7
                height: 80
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: Math.max(2, Math.round(root.stats.avgMax > 0 ? root.stats.avgs[index] / root.stats.avgMax * 80 : 0))
                    topLeftRadius: 5
                    topRightRadius: 5
                    bottomLeftRadius: 3
                    bottomRightRadius: 3
                    color: index === Model.weekday(root.today) ? TallyTheme.acc : TallyTheme.alpha(TallyTheme.fg, 0.34)
                }
            }
        }
    }
    Row {
        Layout.fillWidth: true
        Layout.topMargin: 7
        spacing: 10
        Repeater {
            model: 7
            Item {
                required property int index
                width: (360 - 6 * 10) / 7
                height: 15
                TText { anchors.horizontalCenter: parent.horizontalCenter; px: 10.5; color: TallyTheme.muted; text: Str.dayShort(index) }
            }
        }
    }

    // ---- Stats -----------------------------------------------------------------------------------------
    GridLayout {
        Layout.fillWidth: true
        Layout.topMargin: 22
        columns: 2
        columnSpacing: 8
        rowSpacing: 8
        TStatCell { Layout.fillWidth: true; Layout.preferredWidth: 1; padX: 13; label: Str.dailyAvgLow; value: Str.fmt(root.past.length ? root.total / root.past.length : 0) }
        TStatCell {
            Layout.fillWidth: true; Layout.preferredWidth: 1; padX: 13
            label: Str.busiestDay
            value: root.stats.peak ? Str.shortDate(root.stats.peak.key) + " · " + Str.fmt(root.stats.peak.ms) : "—"
        }
        TStatCell { Layout.fillWidth: true; Layout.preferredWidth: 1; padX: 13; label: Str.goalReached; value: Str.days(root.stats.hits) }
        TStatCell { Layout.fillWidth: true; Layout.preferredWidth: 1; padX: 13; label: Str.streakLabel(Str.fmtMarks(root.goalMs / 120000)); value: Str.days(root.stats.streak) }
    }

    Item { Layout.fillHeight: true }

    TText {
        Layout.alignment: Qt.AlignHCenter
        px: 10
        color: TallyTheme.faint
        text: "~/.local/state/tally-screentime/history.json · " + Str.daysRecorded(root.stats.recorded)
    }
}
