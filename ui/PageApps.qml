import QtQuick
import QtQuick.Layouts
import "js/Model.js" as Model

// Every app of the day, most used first.
ColumnLayout {
    id: root

    readonly property real pageHeight: 772
    readonly property string key: TallyStore.viewKey || TallyTracker.todayKey
    readonly property var d: TallyTracker.day(key)
    readonly property var apps: Model.appRows(d.apps, d.total, 0)

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
                TText { px: 11.5; font.weight: Font.Medium; text: Str.tabDay }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: TallyStore.goto("day") }
        }
        TIconButton { anchors.right: parent.right; icon: "close"; onClicked: TallyStore.closePanel() }
    }

    TLabel { Layout.topMargin: 20; text: Str.appsOfDay(Str.shortDate(root.key)) }
    TText { Layout.topMargin: 6; px: 12; color: TallyTheme.muted; text: Str.fmt(root.d.total) + " · " + Str.appCount(root.apps.length) }

    Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.topMargin: 16
        clip: true
        contentHeight: list.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: list
            width: parent.width
            spacing: 11
            Repeater {
                model: root.apps
                TAppRow {
                    required property int index
                    required property var modelData
                    Layout.fillWidth: true
                    appId: modelData.id
                    name: TallyTracker.appName(modelData.id)
                    share: modelData.share
                    rel: modelData.rel
                    ms: modelData.ms
                    lead: index === 0
                    onClicked: TallyStore.openApp(modelData.id)
                }
            }
        }
    }
}
