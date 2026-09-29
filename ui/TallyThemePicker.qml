import QtQuick
import Quickshell
import Quickshell.Wayland
import "js/Themes.js" as Themes

// Theme picker: a launcher-style list (five swatches, name, source) with a
// live preview on the right. Up/Down move, Enter applies, Esc closes. The
// widget behind re-themes while a row is highlighted and snaps back if you
// cancel.
PanelWindow {
    id: root

    signal dismissed()

    readonly property int pad: 40
    readonly property bool wide: (screen ? screen.width : 1920) >= 1100
    readonly property int listW: 420
    readonly property int listH: 524
    readonly property int previewW: 444
    readonly property int bodyW: wide ? listW + 40 + previewW : listW
    property bool closing: false

    property string query: ""
    readonly property var rows: Themes.LIST.filter(t => query === "" || Str.themeName(t).toLowerCase().indexOf(query.toLowerCase()) !== -1)
    property int sel: 0
    readonly property var cur: rows.length ? rows[Math.min(sel, rows.length - 1)] : Themes.byId(TallyStore.themeId)

    WlrLayershell.namespace: "tally-themes"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    color: "transparent"

    anchors { top: true; left: true }
    margins {
        left: Math.max(0, ((screen ? screen.width : 1920) - bodyW) / 2 - pad)
        top: Math.max(0, ((screen ? screen.height : 1080) - listH) / 2 - pad)
    }
    implicitWidth: bodyW + pad * 2
    implicitHeight: listH + pad * 2
    mask: Region { item: body }

    // Fixed launcher palette: the picker looks the same whatever theme is applied.
    readonly property color cBg: "#0e0e0f"
    readonly property color cText: "#ececec"
    readonly property color cMuted: "#8d8d92"
    readonly property color cDim: "#6e6e73"

    function apply() {
        if (!root.rows.length)
            return;
        TallyStore.set("themeId", root.cur.id);
        TallyStore.closePicker();
    }
    function move(n) {
        if (!rows.length)
            return;
        sel = (sel + n + rows.length) % rows.length;
        list.positionViewAtIndex(sel, ListView.Contain);
    }
    onSelChanged: if (root.cur) TallyStore.previewId = root.cur.id
    onQueryChanged: sel = 0

    Component.onCompleted: {
        TallyStore.pickerWin = root;
        sel = Math.max(0, Themes.indexOf(TallyStore.themeId));
        Qt.callLater(() => { list.positionViewAtIndex(sel, ListView.Contain); search.forceActiveFocus(); });
        openAnim.start();
    }
    Component.onDestruction: {
        if (TallyStore.pickerWin === root)
            TallyStore.pickerWin = null;
    }

    function requestClose() {
        if (closing)
            return;
        closing = true;
        openAnim.stop();
        closeAnim.start();
    }
    NumberAnimation { id: openAnim; target: body; property: "opacity"; from: 0; to: 1; duration: 140; easing.type: Easing.OutQuad }
    SequentialAnimation {
        id: closeAnim
        NumberAnimation { target: body; property: "opacity"; to: 0; duration: 110; easing.type: Easing.InQuad }
        ScriptAction { script: root.dismissed() }
    }

    Item {
        id: body
        x: root.pad
        y: root.pad
        width: root.bodyW
        height: root.listH
        opacity: 0

        // ---- List -----------------------------------------------------------------------
        Rectangle {
            id: listCard
            width: root.listW
            height: root.listH
            radius: 16
            color: root.cBg
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.09)
            clip: true

            Item {
                id: bar
                width: parent.width
                height: 52
                TIcon { x: 18; anchors.verticalCenter: parent.verticalCenter; name: "search"; size: 15; stroke: 2; color: root.cMuted }
                TextInput {
                    id: search
                    x: 43
                    width: parent.width - 43 - 90
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: TallyTheme.mono
                    font.pixelSize: 14
                    color: root.cText
                    clip: true
                    onTextChanged: root.query = text
                    Keys.onUpPressed: root.move(-1)
                    Keys.onDownPressed: root.move(1)
                    Keys.onReturnPressed: root.apply()
                    Keys.onEnterPressed: root.apply()
                    Keys.onEscapePressed: TallyStore.closePicker()
                    TText { visible: search.text === "" && !search.preeditText; anchors.fill: parent; verticalAlignment: Text.AlignVCenter; px: 14; color: root.cDim; text: Str.searchThemes }
                }
                TText { anchors.right: parent.right; anchors.rightMargin: 18; anchors.verticalCenter: parent.verticalCenter; px: 11; color: root.cDim; text: Str.themeCount(root.rows.length) }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.07) }
            }

            TText { x: 18; y: 52 + 12; px: 10; font.weight: Font.Medium; font.letterSpacing: 1.6; color: root.cMuted; text: Str.allThemes }

            ListView {
                id: list
                x: 8
                y: 52 + 12 + 13 + 6
                width: parent.width - 16
                height: 400
                clip: true
                model: root.rows
                currentIndex: root.sel
                boundsBehavior: Flickable.StopAtBounds
                delegate: Rectangle {
                    id: row
                    required property int index
                    required property var modelData
                    width: list.width
                    height: 40
                    radius: 9
                    color: index === root.sel ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

                    Row {
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Repeater {
                            model: row.modelData.sw
                            Rectangle {
                                required property var modelData
                                width: 14; height: 14; radius: 3
                                color: modelData
                                border.width: 1
                                border.color: Qt.rgba(0.5, 0.5, 0.5, 0.4)
                            }
                        }
                    }
                    TText { x: 12 + 5 * 14 + 4 * 2 + 14; anchors.verticalCenter: parent.verticalCenter; px: 15; color: root.cText; text: Str.themeName(row.modelData) }
                    TIcon {
                        visible: row.modelData.id === TallyStore.themeId
                        anchors.right: tag.left
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        name: "check"; size: 14; stroke: 2.4; color: TallyTheme.acc
                    }
                    TText { id: tag; anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; px: 12; color: root.cMuted; text: Str.themeTag(row.modelData.tag) }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.sel = row.index;
                            if (!root.wide)
                                root.apply();
                        }
                    }
                }
            }

            Item {
                y: parent.height - 46
                width: parent.width
                height: 46
                Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.07) }
                TText { x: 18; anchors.verticalCenter: parent.verticalCenter; px: 11.5; color: root.cMuted; text: Str.defaultTheme("Noir") }
                TText { anchors.right: parent.right; anchors.rightMargin: 18; anchors.verticalCenter: parent.verticalCenter; px: 11.5; color: root.cMuted; text: Str.pickerKeys }
            }
        }

        // ---- Preview ------------------------------------------------------------------------
        Item {
            id: preview
            visible: root.wide
            x: root.listW + 40
            width: root.previewW
            height: parent.height

            readonly property color pCard: root.cur.card
            readonly property color pFg: root.cur.fg
            readonly property color pAcc: root.cur.acc
            readonly property color pMuted: TallyTheme.mix(pFg, pCard, 0.68)

            Item {
                width: parent.width
                height: 44
                Column {
                    spacing: 6
                    TText { px: 10; font.weight: Font.Medium; font.letterSpacing: 1.6; color: root.cMuted; text: Str.preview }
                    TBig { bigPx: 34; wght: 500; color: root.cText; text: Str.themeName(root.cur) }
                }
                Row {
                    anchors.right: parent.right
                    spacing: 6
                    Repeater {
                        model: root.cur.sw
                        Column {
                            required property var modelData
                            spacing: 5
                            Rectangle { width: 26; height: 26; radius: 7; color: modelData; border.width: 1; border.color: Qt.rgba(0.5, 0.5, 0.5, 0.4) }
                            TText { anchors.horizontalCenter: parent.horizontalCenter; px: 9; color: root.cMuted; text: modelData }
                        }
                    }
                }
            }

            // bar strip
            Rectangle {
                y: 44 + 22
                width: parent.width
                height: 40
                radius: 12
                color: preview.pCard
                border.width: 1
                border.color: TallyTheme.alpha(preview.pFg, 0.10)
                Row {
                    x: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5
                    Rectangle { width: 6; height: 6; radius: 3; color: preview.pFg }
                    Rectangle { width: 6; height: 6; radius: 3; color: TallyTheme.alpha(preview.pFg, 0.30) }
                    Rectangle { width: 6; height: 6; radius: 3; color: TallyTheme.alpha(preview.pFg, 0.30) }
                }
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: pillRow.width + 20
                    height: 26
                    radius: 9
                    color: TallyTheme.alpha(preview.pFg, 0.08)
                    Row {
                        id: pillRow
                        anchors.centerIn: parent
                        spacing: 7
                        TIcon { anchors.verticalCenter: parent.verticalCenter; name: "pulse"; size: 14; color: preview.pAcc }
                        TText { px: 11.5; font.weight: Font.Medium; color: preview.pFg; text: "4s 12d" }
                    }
                    Rectangle {
                        x: 10; y: parent.height - 4
                        width: parent.width - 20; height: 2; radius: 1
                        color: TallyTheme.alpha(preview.pFg, 0.14)
                        Rectangle { width: parent.width * 0.7; height: 2; radius: 1; color: preview.pAcc }
                    }
                }
            }

            // mini panel
            Rectangle {
                y: 44 + 22 + 40 + 14
                width: parent.width
                height: miniCol.implicitHeight + 36
                radius: 16
                color: preview.pCard
                border.width: 1
                border.color: TallyTheme.alpha(preview.pFg, 0.10)
                Column {
                    id: miniCol
                    x: 18
                    y: 18
                    width: parent.width - 36
                    spacing: 14
                    Item {
                        width: parent.width
                        height: 50
                        Row {
                            spacing: 5
                            TBig { id: mh; bigPx: 52; color: preview.pFg; text: "4" }
                            TText { y: mh.baselineOffset - baselineOffset; px: 14; color: preview.pMuted; text: Str.uh }
                            TBig { id: mm; bigPx: 52; color: preview.pFg; text: "12" }
                            TText { y: mm.baselineOffset - baselineOffset; px: 14; color: preview.pMuted; text: Str.um }
                        }
                        TText { anchors.right: parent.right; anchors.bottom: parent.bottom; px: 11; color: preview.pMuted; text: Str.ofGoal70 }
                    }
                    Item {
                        width: parent.width
                        height: 18
                        Repeater {
                            model: 40
                            Rectangle {
                                required property int index
                                x: index * (parent.width - 6) / 39
                                anchors.bottom: parent.bottom
                                width: 6
                                height: index % 10 === 0 ? 18 : 12
                                radius: 2
                                color: index === 27 ? preview.pAcc : index < 28 ? preview.pFg : TallyTheme.alpha(preview.pFg, 0.15)
                            }
                        }
                    }
                    Repeater {
                        model: [["F", "Firefox", "1s 38d", 1.0], ["k", "kitty", "1s 14d", 0.76], ["Z", "Zed", "38d", 0.39]]
                        Item {
                            required property int index
                            required property var modelData
                            width: miniCol.width
                            height: 22
                            Rectangle {
                                width: 22; height: 22; radius: 7
                                color: TallyTheme.alpha(preview.pFg, 0.09)
                                TText { anchors.centerIn: parent; px: 10.5; font.weight: Font.Bold; color: preview.pFg; text: modelData[0] }
                            }
                            TText { x: 32; anchors.verticalCenter: parent.verticalCenter; px: 12; font.weight: Font.Medium; color: preview.pFg; text: modelData[1] }
                            Rectangle {
                                x: 32 + 72
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 32 - 72 - 60
                                height: 3; radius: 2
                                color: TallyTheme.alpha(preview.pFg, 0.09)
                                Rectangle { width: parent.width * modelData[3]; height: 3; radius: 2; color: index === 0 ? preview.pAcc : TallyTheme.alpha(preview.pFg, 0.55) }
                            }
                            TText { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; px: 11.5; color: preview.pFg; text: modelData[2] }
                        }
                    }
                }
            }

            Row {
                y: parent.height - 38
                spacing: 10
                Rectangle {
                    readonly property bool isApplied: root.cur.id === TallyStore.themeId
                    width: applyText.width + 40
                    height: 38
                    radius: 11
                    color: isApplied ? Qt.rgba(1, 1, 1, 0.12) : root.cText
                    TText { id: applyText; anchors.centerIn: parent; px: 12.5; font.weight: Font.Medium; color: parent.isApplied ? root.cText : root.cBg; text: parent.isApplied ? Str.applied : Str.apply }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.apply() }
                }
                TText { anchors.verticalCenter: parent.verticalCenter; px: 11; color: root.cMuted; text: Str.accentFromTheme }
            }
        }
    }
}
