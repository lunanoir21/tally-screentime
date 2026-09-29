import QtQuick
import QtQuick.Layouts
import "js/Model.js" as Model

// Rapor: what to export, in which style and format.
ColumnLayout {
    id: root

    readonly property real pageHeight: 772
    readonly property var scopes: ["day", "week", "all"]
    readonly property var kinds: ["page", "card", "board"]
    readonly property var formats: ["png", "pdf", "html", "json"]
    readonly property var infos: scopes.map(s => TallyExport.buildData(s))
    readonly property bool busy: TallyExport.phase === "working"

    spacing: 0

    // ---- header ---------------------------------------------------------------------------------------
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
                TText { px: 11.5; font.weight: Font.Medium; text: Str.back }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: TallyStore.goto(TallyStore.backPage) }
        }
        TIconButton { anchors.right: parent.right; icon: "close"; onClicked: TallyStore.closePanel() }
    }

    TBig { Layout.topMargin: 16; bigPx: 28; wght: 500; text: Str.exportTitle }

    // ---- what ---------------------------------------------------------------------------------------------
    TLabel { Layout.topMargin: 18; text: Str.secWhat }
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 10
        spacing: 8
        Repeater {
            model: root.scopes
            Rectangle {
                id: card
                required property int index
                required property string modelData
                readonly property bool on: TallyExport.scope === modelData
                readonly property var info: root.infos[index]
                Layout.fillWidth: true
                implicitHeight: 54
                radius: 13
                color: on ? TallyTheme.segOn : "transparent"
                border.width: 1
                border.color: on ? TallyTheme.fg : TallyTheme.alpha(TallyTheme.fg, 0.12)
                Behavior on color { ColorAnimation { duration: 140 } }
                Rectangle {
                    x: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: 14; height: 14; radius: 7
                    color: "transparent"
                    border.width: 1.5
                    border.color: card.on ? TallyTheme.fg : TallyTheme.alpha(TallyTheme.fg, 0.35)
                    Rectangle { anchors.centerIn: parent; width: 6; height: 6; radius: 3; color: TallyTheme.fg; visible: card.on }
                }
                Column {
                    x: 40
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    TText { px: 13; font.weight: Font.Medium; text: card.modelData === "day" ? Str.scopeDay : card.modelData === "week" ? Str.scopeWeek : Str.scopeAll }
                    TText { px: 11; color: TallyTheme.muted; text: card.modelData === "day" ? Str.shortDate(card.info.from) : Str.shortDate(card.info.from) + " – " + Str.shortDate(card.info.to) + " · " + Str.scopeSub(card.modelData, card.info.dayCount) }
                }
                TText { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; px: 13; font.weight: Font.Medium; text: Str.fmt(card.info.total) }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: TallyExport.scope = card.modelData }
            }
        }
    }

    // ---- style -----------------------------------------------------------------------------------------------
    TLabel { Layout.topMargin: 18; text: Str.secKind }
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 10
        spacing: 8
        Repeater {
            model: root.kinds
            Rectangle {
                id: tile
                required property int index
                required property string modelData
                readonly property bool on: TallyExport.kind === modelData
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: 92
                radius: 13
                opacity: TallyExport.format === "html" || TallyExport.format === "json" ? 0.4 : 1
                color: on ? TallyTheme.segOn : "transparent"
                border.width: 1
                border.color: on ? TallyTheme.fg : TallyTheme.alpha(TallyTheme.fg, 0.12)
                Behavior on color { ColorAnimation { duration: 140 } }

                // a small drawing of the sheet
                Item {
                    x: 12; y: 12; width: parent.width - 24; height: 46
                    Rectangle {
                        id: sheet
                        anchors.centerIn: parent
                        width: tile.modelData === "page" ? 32 : tile.modelData === "card" ? 36 : 64
                        height: tile.modelData === "page" ? 46 : tile.modelData === "card" ? 46 : 38
                        radius: 4
                        color: tile.modelData === "page" ? "#f1efe9" : "#17171a"
                        border.width: 1
                        border.color: TallyTheme.alpha(TallyTheme.fg, 0.25)
                        Column {
                            x: 5; y: 5
                            spacing: 3
                            Rectangle { width: tile.modelData === "board" ? 16 : 12; height: 8; radius: 1.5; color: tile.modelData === "page" ? "#16150f" : "#ececec" }
                            Row {
                                spacing: 1.5
                                Repeater { model: 8; Rectangle { required property int index; width: 1.6; height: index < 6 ? 5 : 3; y: 0; radius: 0.8; color: index === 5 ? "#e0a458" : (tile.modelData === "page" ? "#16150f" : "#ececec"); opacity: index < 6 ? 1 : 0.3 } }
                            }
                            Row {
                                visible: tile.modelData !== "page"
                                spacing: 2
                                Repeater { model: 5; Rectangle { required property int index; width: tile.modelData === "board" ? 7 : 4; height: 3 + index * 1.6; radius: 0.8; color: "#ececec"; opacity: 0.55 } }
                            }
                        }
                    }
                }
                TText { anchors.horizontalCenter: parent.horizontalCenter; y: 68; px: 12; font.weight: tile.on ? Font.Medium : Font.Normal; color: tile.on ? TallyTheme.fg : TallyTheme.muted; text: tile.modelData === "page" ? Str.kindA : tile.modelData === "card" ? Str.kindB : Str.kindC }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: TallyExport.kind = tile.modelData }
            }
        }
    }
    TText { Layout.topMargin: 8; px: 11; color: TallyTheme.muted; text: Str.kindNote[root.kinds.indexOf(TallyExport.kind)] }

    // ---- format ---------------------------------------------------------------------------------------------------
    TLabel { Layout.topMargin: 16; text: Str.secFormat }
    TSegmented {
        Layout.fillWidth: true
        Layout.topMargin: 10
        model: ["PNG", "PDF", "HTML", "JSON"]
        currentIndex: root.formats.indexOf(TallyExport.format)
        px: 12
        fill: true
        vPad: 8
        innerRadius: 9
        onPicked: i => TallyExport.format = root.formats[i]
    }
    TText { Layout.topMargin: 8; px: 11; color: TallyTheme.muted; text: Str.formatNote[root.formats.indexOf(TallyExport.format)] }

    Item {
        Layout.fillWidth: true
        Layout.topMargin: 12
        implicitHeight: 40
        opacity: TallyExport.format === "json" ? 0.4 : 1
        enabled: TallyExport.format !== "json"
        TText { anchors.verticalCenter: parent.verticalCenter; px: 12.5; text: Str.look }
        TSegmented {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            model: [Str.lookTheme, Str.lookPaper]
            currentIndex: TallyExport.look === "paper" ? 1 : 0
            onPicked: i => TallyExport.look = i === 1 ? "paper" : "theme"
        }
        Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: TallyTheme.line }
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: 40
        TText { anchors.verticalCenter: parent.verticalCenter; px: 12.5; text: Str.openWhenSaved }
        TSwitch {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            checked: TallyStore.openAfterExport
            onToggled: v => TallyStore.set("openAfterExport", v)
        }
        Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: TallyTheme.line }
    }

    Item { Layout.fillHeight: true }

    // ---- go / status ---------------------------------------------------------------------------------------------------
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 10

        // working: the ruler fills as the report is made
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.busy
            spacing: 8
            Item {
                Layout.fillWidth: true
                implicitHeight: 14
                TText { px: 12; font.weight: Font.Medium; text: Str.working }
                TText { anchors.right: parent.right; px: 12; color: TallyTheme.muted; text: "%" + Math.round(TallyExport.progress * 100) }
            }
            TRuler { Layout.fillWidth: true; count: 30; filled: Math.round(TallyExport.progress * 30); major: 10; tallHeight: 22; shortHeight: 14 }
        }

        // done
        Rectangle {
            Layout.fillWidth: true
            visible: TallyExport.phase === "done"
            implicitHeight: doneCol.implicitHeight + 24
            radius: 13
            color: TallyTheme.cell
            border.width: 1
            border.color: TallyTheme.line
            TIcon { x: 14; y: 14; name: "check"; size: 16; stroke: 2.4; color: TallyTheme.acc }
            Column {
                id: doneCol
                x: 42
                y: 12
                width: parent.width - 56
                spacing: 8
                TText { px: 12.5; font.weight: Font.Medium; text: Str.saved }
                TText { width: parent.width; px: 10.5; color: TallyTheme.muted; elide: Text.ElideMiddle; text: TallyExport.lastPath }
                Row {
                    spacing: 8
                    Repeater {
                        model: TallyExport.lastFormat === "png" ? [Str.openFile, Str.showFolder, TallyExport.copiedRecently ? Str.copied : Str.copyImage] : [Str.openFile, Str.showFolder]
                        Rectangle {
                            required property int index
                            required property string modelData
                            width: lbl.width + 24
                            height: 28
                            radius: 8
                            color: index === 0 ? TallyTheme.fg : "transparent"
                            border.width: index === 0 ? 0 : 1
                            border.color: TallyTheme.outline
                            TText { id: lbl; anchors.centerIn: parent; px: 11; font.weight: Font.Medium; color: index === 0 ? TallyTheme.card : TallyTheme.fg; text: modelData }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: index === 0 ? TallyExport.open() : index === 1 ? TallyExport.showFolder() : TallyExport.copy()
                            }
                        }
                    }
                }
            }
        }

        TText { visible: TallyExport.phase === "error"; px: 11.5; color: TallyTheme.bad; wrapMode: Text.WordWrap; Layout.fillWidth: true; text: Str.exportFailed + " · " + TallyExport.error }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 46
            radius: 13
            color: TallyTheme.fg
            opacity: root.busy ? 0.5 : 1
            TText { anchors.centerIn: parent; px: 13; font.weight: Font.Medium; color: TallyTheme.card; text: Str.doExport }
            MouseArea { anchors.fill: parent; enabled: !root.busy; cursorShape: Qt.PointingHandCursor; onClicked: TallyExport.run() }
        }
        TText { Layout.alignment: Qt.AlignHCenter; px: 10.5; color: TallyTheme.faint; text: "~/Pictures/tally" }
    }
}
