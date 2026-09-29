import QtQuick

// Header of the three main pages: settings button, Gün/Hafta/Harita, close.
Item {
    id: root

    property int current: 0
    height: 32

    TIconButton {
        anchors.left: parent.left
        icon: "sliders"
        iconSize: 16
        stroke: 1.6
        onClicked: TallyStore.goto("settings")
    }
    TSegmented {
        anchors.centerIn: parent
        model: [Str.tabDay, Str.tabWeek, Str.tabMap]
        currentIndex: root.current
        px: 11.5
        hPad: 14
        vPad: 5
        innerRadius: 8
        onPicked: index => TallyStore.goto(["day", "week", "map"][index])
    }
    Row {
        anchors.right: parent.right
        spacing: 8
        TIconButton {
            icon: "share"
            iconSize: 15
            stroke: 1.7
            onClicked: TallyStore.openExport(TallyStore.page === "week" ? "week" : TallyStore.page === "map" ? "all" : "day")
        }
        TIconButton {
            icon: "close"
            onClicked: TallyStore.closePanel()
        }
    }
}
