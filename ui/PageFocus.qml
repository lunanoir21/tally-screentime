import QtQuick
import QtQuick.Layouts
import "js/Model.js" as Model

// Odak oturumu: a 25 minute countdown as a ruler that empties minute by minute.
ColumnLayout {
    id: root

    readonly property real pageHeight: 416
    readonly property real total: TallyStore.focusMinutes * 60000
    readonly property real remain: TallyStore.focusRemaining
    readonly property int spent: Math.min(TallyStore.focusMinutes - 1, Math.floor((total - remain) / 60000))
    readonly property var apps: {
        var m = TallyStore.focusApps, out = [];
        for (var k in m) out.push({ id: k, ms: m[k] });
        out.sort((a, b) => b.ms - a.ms);
        return out.slice(0, 3);
    }
    readonly property var clockParts: Model.clock(remain).split(":")

    spacing: 0

    Item {
        Layout.fillWidth: true
        implicitHeight: 32
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 7; height: 7; radius: 4; color: TallyTheme.acc }
            TLabel { anchors.verticalCenter: parent.verticalCenter; text: TallyStore.focusPaused ? Str.focusPaused : Str.focusCaps }
        }
        TIconButton { anchors.right: parent.right; icon: "close"; onClicked: TallyStore.goto("day") }
    }

    Row {
        Layout.topMargin: 14
        TBig { bigPx: 100; text: root.clockParts[0] }
        TBig { bigPx: 100; color: TallyTheme.faint; text: ":" }
        TBig { bigPx: 100; text: root.clockParts[1] }
    }

    TRuler {
        Layout.fillWidth: true
        Layout.topMargin: 20
        count: TallyStore.focusMinutes
        filled: TallyStore.focusMinutes
        major: 5
        spent: root.spent
        accentLast: false
        accentAt: root.spent
    }
    Item {
        Layout.fillWidth: true
        Layout.topMargin: 8
        implicitHeight: 14
        TText { px: 10.5; color: TallyTheme.muted; text: Str.startedAt(Model.hhmm(TallyStore.focusStart)) }
        TText { anchors.right: parent.right; px: 10.5; color: TallyTheme.muted; text: Str.endsAt(Model.hhmm(TallyStore.focusStart + root.total)) }
    }

    TLabel { Layout.topMargin: 22; text: Str.thisSession }
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 10
        spacing: 10
        Repeater {
            model: root.apps
            Item {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 16
                TText { px: 12.5; text: TallyTracker.appName(modelData.id) }
                TText { anchors.right: parent.right; px: 12.5; text: Str.sec(modelData.ms) }
            }
        }
        TText { visible: root.apps.length === 0; px: 12; color: TallyTheme.muted; text: Str.soon }
    }

    Item { Layout.fillHeight: true }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            implicitHeight: 44
            radius: 12
            color: "transparent"
            border.width: 1
            border.color: TallyTheme.alpha(TallyTheme.fg, 0.16)
            TText { anchors.centerIn: parent; px: 12.5; font.weight: Font.Medium; text: TallyStore.focusPaused ? Str.resume : Str.pause }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: TallyStore.focusPaused ? TallyStore.resumeFocus() : TallyStore.pauseFocus()
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            implicitHeight: 44
            radius: 12
            color: TallyTheme.fg
            TText { anchors.centerIn: parent; px: 12.5; font.weight: Font.Medium; color: TallyTheme.card; text: Str.finish }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: TallyStore.stopFocus() }
        }
    }
}
