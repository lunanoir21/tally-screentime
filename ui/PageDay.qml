import QtQuick
import QtQuick.Layouts
import "js/Model.js" as Model

// Gün: the day's total against the goal ruler, hour by hour, and the top apps.
ColumnLayout {
    id: root

    readonly property real pageHeight: 740
    readonly property string key: TallyStore.viewKey || TallyTracker.todayKey
    readonly property bool isToday: key === TallyTracker.todayKey
    readonly property var d: TallyTracker.day(key)
    readonly property real goalMs: TallyStore.goalHours * 3600000
    readonly property real prevTotal: TallyTracker.day(Model.shiftKey(key, -1)).total
    readonly property var apps: Model.appRows(d.apps, d.total, 5)
    readonly property int appCount: Object.keys(d.apps).length
    readonly property int curHour: isToday ? (TallyTracker.today, new Date().getHours()) : 24

    function shift(n) {
        var next = Model.shiftKey(root.key, n);
        if (next > TallyTracker.todayKey)
            return;
        TallyStore.viewKey = next === TallyTracker.todayKey ? "" : next;
    }
    function title() {
        if (isToday) return Str.today;
        if (key === Model.shiftKey(TallyTracker.todayKey, -1)) return Str.yesterday;
        return Str.dayShort(Model.weekday(key));
    }
    function peak() {
        var best = -1, bi = 0;
        var h = d.h || [];
        for (var i = 0; i < h.length; i++)
            if (h[i] > best) { best = h[i]; bi = i; }
        return best > 0 ? { hour: bi, min: Math.round(best / 60000) } : null;
    }

    spacing: 0


    TNav {
        Layout.fillWidth: true
        Layout.topMargin: 14
        title: root.title()
        subtitle: Str.longDate(root.key)
        canNext: !root.isToday
        onPrev: root.shift(-1)
        onNext: root.shift(1)
    }

    // ---- Hero --------------------------------------------------------------
    TLabel { Layout.topMargin: 16; text: Str.focusedTime }
    Item {
        Layout.fillWidth: true
        Layout.topMargin: 2
        implicitHeight: 80

        TDuration { ms: root.d.total; bigPx: 84; unitPx: 20; unitMargin: 8 }

        Rectangle {
            visible: root.prevTotal > 0
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            width: deltaRow.width + 18
            height: 26
            radius: 9
            color: TallyTheme.ctl
            Row {
                id: deltaRow
                anchors.centerIn: parent
                spacing: 5
                TIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.d.total >= root.prevTotal ? "up" : "down"
                    size: 11
                    stroke: 2.4
                    color: TallyTheme.acc
                }
                TText { px: 11; font.weight: Font.Medium; text: Str.fmt(Math.abs(root.d.total - root.prevTotal)) }
                TText { px: 11; color: TallyTheme.muted; text: (root.isToday ? Str.fromYesterday : Str.fromPrevDay) }
            }
        }
    }

    // ---- Goal ruler ----------------------------------------------------------
    Item {
        Layout.fillWidth: true
        Layout.topMargin: 18
        implicitHeight: 15
        visible: root.goalMs > 0
        TText { px: 11; color: TallyTheme.muted; text: Str.dailyGoal(TallyStore.goalHours) }
        TText {
            anchors.right: parent.right
            px: 11
            text: root.d.total >= root.goalMs
                ? Str.goalOver(Str.fmt(root.d.total - root.goalMs))
                : Str.goalLeft(Math.round(root.d.total / root.goalMs * 100), Str.fmt(root.goalMs - root.d.total))
        }
    }
    TRuler {
        visible: root.goalMs > 0
        Layout.fillWidth: true
        Layout.topMargin: 10
        count: 40
        filled: Math.floor(Math.min(1, root.d.total / Math.max(1, root.goalMs)) * 40)
    }
    TSpaceRow {
        visible: root.goalMs > 0
        Layout.fillWidth: true
        Layout.topMargin: 6
        items: [0, 1, 2, 3, 4].map(i => Str.fmtMarks(TallyStore.goalHours * 60 * i / 4))
    }
    TText {
        visible: root.goalMs <= 0
        Layout.topMargin: 18
        px: 11
        color: TallyTheme.muted
        text: Str.goalOff
    }

    // ---- Hour by hour ----------------------------------------------------------
    Item {
        Layout.fillWidth: true
        Layout.topMargin: 22
        implicitHeight: 13
        TLabel { text: Str.hourByHour }
        TText {
            anchors.right: parent.right
            px: 10
            color: TallyTheme.muted
            visible: root.peak() !== null && root.peak().min >= 1
            text: root.peak() ? Str.peak(String(root.peak().hour).padStart(2, "0") + ":00", root.peak().min) : ""
        }
    }
    Item {
        Layout.fillWidth: true
        Layout.topMargin: 10
        implicitHeight: 52
        Row {
            anchors.fill: parent
            spacing: 3
            Repeater {
                model: 24
                Rectangle {
                    required property int index
                    readonly property real m: ((root.d.h || [])[index] || 0) / 60000
                    width: (parent.width - 23 * 3) / 24
                    anchors.bottom: parent.bottom
                    height: index > root.curHour ? 2 : Math.max(3, Math.round(m / 60 * 52))
                    radius: index > root.curHour ? 1 : 3
                    color: index === root.curHour ? TallyTheme.acc
                         : (m === 0 || index > root.curHour) ? TallyTheme.alpha(TallyTheme.fg, 0.12)
                         : TallyTheme.alpha(TallyTheme.fg, 0.78)
                }
            }
        }
    }
    TSpaceRow { Layout.fillWidth: true; Layout.topMargin: 6; items: ["00", "06", "12", "18", "24"] }

    // ---- Apps ---------------------------------------------------------------------
    Item {
        Layout.fillWidth: true
        Layout.topMargin: 22
        implicitHeight: 13
        TLabel { text: Str.appsLabel }
        MouseArea {
            anchors.right: parent.right
            width: allText.width
            height: parent.height
            cursorShape: Qt.PointingHandCursor
            onClicked: TallyStore.goto("apps")
            TText { id: allText; px: 10; text: Str.allApps(root.appCount) }
        }
    }
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

    // ---- Footer -----------------------------------------------------------------------
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 46
        radius: 13
        color: TallyTheme.fg
        TIcon { x: 16; anchors.verticalCenter: parent.verticalCenter; name: "play"; size: 14; color: TallyTheme.card }
        TText {
            x: 39
            anchors.verticalCenter: parent.verticalCenter
            px: 13
            font.weight: Font.Medium
            color: TallyTheme.card
            text: TallyStore.focusActive ? Str.focusSession : Str.startFocus
        }
        TText {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            px: 13
            color: TallyTheme.card
            opacity: 0.65
            text: TallyStore.focusActive ? Model.clock(TallyStore.focusRemaining) : TallyStore.focusMinutes + ":00"
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: TallyStore.focusActive ? TallyStore.goto("focus") : TallyStore.startFocus()
        }
    }
    TText {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 9
        px: 10.5
        color: TallyTheme.muted
        visible: (root.d.best || [0])[0] >= 60000
        text: Str.longestRun(Str.fmt((root.d.best || [0, 0])[0]), Model.hhmm((root.d.best || [0, 0])[1]))
    }
}
