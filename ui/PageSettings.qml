import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import "js/Model.js" as Model
import "js/Themes.js" as Themes

// Ayarlar. Taller than the other pages, so it scrolls when the screen is short.
Flickable {
    id: root

    readonly property real pageHeight: 1010
    property bool confirmReset: false
    property bool adding: false
    property bool restoring: false
    property string restoreMsg: ""
    property bool restoreOk: true

    contentWidth: width
    contentHeight: col.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Timer { id: resetTimer; interval: 3000; onTriggered: root.confirmReset = false }

    component SRow: Item {
        id: row
        property string label: ""
        property real rowHeight: 46
        property bool clickable: false
        signal activated()
        default property alias content: holder.data
        Layout.fillWidth: true
        implicitHeight: rowHeight
        MouseArea { anchors.fill: parent; enabled: row.clickable; cursorShape: Qt.PointingHandCursor; onClicked: row.activated() }
        TText { anchors.verticalCenter: parent.verticalCenter; px: 12.5; text: row.label }
        Item {
            id: holder
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: childrenRect.width
            height: childrenRect.height
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: TallyTheme.line }
    }

    ColumnLayout {
        id: col
        width: root.width
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
                    TText { px: 11.5; font.weight: Font.Medium; text: Str.settings }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: TallyStore.goto("day") }
            }
            TIconButton { anchors.right: parent.right; icon: "close"; onClicked: TallyStore.closePanel() }
        }

        // ---- GÖRÜNÜM ---------------------------------------------------------------
        TLabel { Layout.topMargin: 22; text: Str.secLook }
        SRow { label: Str.alwaysShow; TSwitch { checked: TallyStore.pillVisible; onToggled: v => TallyStore.set("pillVisible", v) } }
        SRow {
            label: Str.pillContent
            TSegmented {
                model: [Str.pillIcon, Str.pillIconTime]
                currentIndex: TallyStore.pillTime ? 1 : 0
                onPicked: i => TallyStore.set("pillTime", i === 1)
            }
        }
        SRow { label: Str.pillGoalLine; TSwitch { checked: TallyStore.pillGoalLine; onToggled: v => TallyStore.set("pillGoalLine", v) } }
        SRow {
            label: Str.theme
            rowHeight: 52
            clickable: true
            onActivated: TallyStore.openPicker()
            Row {
                spacing: 10
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Repeater {
                        model: Themes.byId(TallyStore.themeId).sw
                        Rectangle {
                            required property var modelData
                            width: 13; height: 13; radius: 3
                            color: modelData
                            border.width: 1
                            border.color: Qt.rgba(0.5, 0.5, 0.5, 0.4)
                        }
                    }
                }
                TText { anchors.verticalCenter: parent.verticalCenter; px: 12.5; font.weight: Font.Medium; text: Str.themeName(Themes.byId(TallyStore.themeId)) }
                TIcon { anchors.verticalCenter: parent.verticalCenter; name: "right"; size: 13; color: TallyTheme.muted }
            }
        }

        SRow {
            label: Str.language
            TSegmented {
                model: [Str.langAuto, "Türkçe", "English"]
                currentIndex: Math.max(0, ["auto", "tr", "en"].indexOf(TallyStore.language))
                onPicked: i => TallyStore.set("language", ["auto", "tr", "en"][i])
            }
        }

        // ---- HEDEF -----------------------------------------------------------------------
        TLabel { Layout.topMargin: 22; text: Str.secGoal }
        SRow {
            label: Str.dailyGoalRow
            rowHeight: 52
            TStepper {
                text: Str.fmtHours(TallyStore.goalHours)
                onDec: TallyStore.set("goalHours", Math.max(0, TallyStore.goalHours - 0.5))
                onInc: TallyStore.set("goalHours", Math.min(16, TallyStore.goalHours + 0.5))
            }
        }
        SRow { label: Str.notifyNear; TSwitch { checked: TallyStore.notifyNear; onToggled: v => TallyStore.set("notifyNear", v) } }
        SRow { label: Str.notifyOver; TSwitch { checked: TallyStore.notifyOver; onToggled: v => TallyStore.set("notifyOver", v) } }

        // ---- TAKİP --------------------------------------------------------------------------
        TLabel { Layout.topMargin: 22; text: Str.secTrack }
        SRow {
            label: Str.idleAfter
            TSegmented {
                px: 11
                hPad: 10
                model: Str.idleOpts
                currentIndex: Math.max(0, [1, 3, 5, 10].indexOf(TallyStore.idleMinutes))
                onPicked: i => TallyStore.set("idleMinutes", [1, 3, 5, 10][i])
            }
        }
        SRow { label: Str.countVideo; TSwitch { checked: TallyStore.countVideo; onToggled: v => TallyStore.set("countVideo", v) } }

        Item {
            Layout.fillWidth: true
            implicitHeight: chips.y + chips.height + 14
            TText { y: 13; px: 12.5; text: Str.untracked }
            Flow {
                id: chips
                y: 40
                width: parent.width
                spacing: 6
                Repeater {
                    model: TallyStore.excluded
                    Rectangle {
                        required property var modelData
                        width: chipRow.width + 18
                        height: 25
                        radius: 9
                        color: TallyTheme.ctl
                        Row {
                            id: chipRow
                            x: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 7
                            TText { px: 11; text: modelData }
                            TIcon { anchors.verticalCenter: parent.verticalCenter; name: "close"; size: 10; stroke: 2.4; color: TallyTheme.muted }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: TallyStore.include(modelData) }
                    }
                }
                Item {
                    id: addChip
                    width: root.adding ? 150 : addText.width + 20
                    height: 25
                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            strokeColor: TallyTheme.alpha(TallyTheme.fg, 0.24)
                            strokeWidth: 1
                            strokeStyle: ShapePath.DashLine
                            dashPattern: [3, 3]
                            fillColor: "transparent"
                            PathRectangle { x: 0.5; y: 0.5; width: addChip.width - 1; height: 24; radius: 9 }
                        }
                    }
                    TText { id: addText; visible: !root.adding; anchors.centerIn: parent; px: 11; color: TallyTheme.muted; text: Str.addChip }
                    TextInput {
                        id: addInput
                        visible: root.adding
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: TallyTheme.mono
                        font.pixelSize: 11
                        color: TallyTheme.fg
                        clip: true
                        onAccepted: {
                            if (text.trim() !== "")
                                TallyStore.exclude(text.trim());
                            text = "";
                            root.adding = false;
                        }
                        Keys.onEscapePressed: { text = ""; root.adding = false; }
                        onVisibleChanged: if (visible) forceActiveFocus()
                    }
                    MouseArea { anchors.fill: parent; enabled: !root.adding; cursorShape: Qt.PointingHandCursor; onClicked: root.adding = true }
                }
            }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: TallyTheme.line }
        }

        // ---- VERİ ------------------------------------------------------------------------------
        TLabel { Layout.topMargin: 22; text: Str.secData }
        SRow {
            label: Str.keepHistory
            TSegmented {
                px: 11
                hPad: 10
                model: Str.retention
                currentIndex: Math.max(0, [90, 365, 0].indexOf(TallyStore.retentionDays))
                onPicked: i => TallyStore.set("retentionDays", [90, 365, 0][i])
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 14
            spacing: 8
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: 40
                radius: 11
                color: "transparent"
                border.width: 1
                border.color: TallyTheme.outline
                TText { anchors.centerIn: parent; px: 12; font.weight: Font.Medium; text: Str.backUp }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { TallyTracker.exportAll(); root.restoreMsg = Str.historyBackedUp; root.restoreOk = true; }
                }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: 40
                radius: 11
                color: root.restoring ? TallyTheme.segOn : "transparent"
                border.width: 1
                border.color: TallyTheme.outline
                TText { anchors.centerIn: parent; px: 12; font.weight: Font.Medium; text: Str.restore }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { root.restoring = !root.restoring; root.restoreMsg = ""; }
                }
            }
        }
        Rectangle {
            visible: root.restoring
            Layout.fillWidth: true
            Layout.topMargin: 8
            implicitHeight: 40
            radius: 11
            color: TallyTheme.cell
            border.width: 1
            border.color: TallyTheme.line
            TextInput {
                id: restoreInput
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                verticalAlignment: TextInput.AlignVCenter
                font.family: TallyTheme.mono
                font.pixelSize: 12
                color: TallyTheme.fg
                clip: true
                text: "~/tally-history.json"
                selectByMouse: true
                onVisibleChanged: if (visible) { forceActiveFocus(); selectAll(); }
                onAccepted: {
                    var r = TallyTracker.importFrom(text);
                    root.restoreOk = !r.error;
                    root.restoreMsg = r.error ? Str.importFailed : (r.added + r.replaced > 0 ? Str.importDone(r.added, r.replaced) : Str.importNothing(r.kept));
                }
                Keys.onEscapePressed: root.restoring = false
            }
            TText { visible: restoreInput.text === ""; anchors.verticalCenter: parent.verticalCenter; x: 12; px: 11.5; color: TallyTheme.faint; text: Str.restorePath }
        }
        TText {
            visible: root.restoreMsg !== ""
            Layout.fillWidth: true
            Layout.topMargin: 8
            px: 11
            wrapMode: Text.WordWrap
            color: root.restoreOk ? TallyTheme.muted : TallyTheme.bad
            text: root.restoreMsg
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            spacing: 8
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: 40
                radius: 11
                color: "transparent"
                border.width: 1
                border.color: TallyTheme.outline
                TText { anchors.centerIn: parent; px: 12; font.weight: Font.Medium; text: Str.createReport }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: TallyStore.openExport("week") }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: 40
                radius: 11
                color: root.confirmReset ? TallyTheme.alpha(TallyTheme.bad, 0.14) : "transparent"
                border.width: 1
                border.color: TallyTheme.alpha(TallyTheme.bad, 0.40)
                TText { anchors.centerIn: parent; px: 12; font.weight: Font.Medium; color: TallyTheme.bad; text: root.confirmReset ? Str.sure : Str.resetToday }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.confirmReset) {
                            TallyTracker.resetToday();
                            root.confirmReset = false;
                        } else {
                            root.confirmReset = true;
                            resetTimer.restart();
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true; implicitHeight: 20 }
        TText {
            Layout.alignment: Qt.AlignHCenter
            px: 10
            color: TallyTheme.faint
            text: "~/.local/state/tally-screentime/history.json"
        }
    }
}
