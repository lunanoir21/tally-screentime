import QtQuick
import Quickshell
import Quickshell.Wayland
import "js/Themes.js" as Themes

// First run: language, what Tally is, a look, a goal. One screen at a
// time, each sliding in from the side it comes from. Enter goes forward.
PanelWindow {
    id: root

    readonly property int pad: 40
    readonly property int cardW: 600
    readonly property int cardH: 470
    readonly property int steps: 4
    property int step: TallyStore.tourStart
    property bool closing: false

    WlrLayershell.namespace: "tally-onboarding"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    color: "transparent"

    anchors { top: true; left: true }
    margins {
        left: Math.max(0, ((screen ? screen.width : 1920) - cardW) / 2 - pad)
        top: Math.max(0, ((screen ? screen.height : 1080) - cardH) / 2 - pad)
    }
    implicitWidth: cardW + pad * 2
    implicitHeight: cardH + pad * 2
    mask: Region { item: card }

    function go(to) {
        if (to < 0 || to >= steps || to === step)
            return;
        var dir = to > step ? 1 : -1;
        step = to;
        content.x = dir * 28;
        content.opacity = 0;
        enter.restart();
    }
    // `skip` ends the tour from any step; it is marked done like a finished one.
    function forward(skip) {
        if (skip === true || step === steps - 1) {
            closing = true;
            closeAnim.start();
        } else {
            go(step + 1);
        }
    }

    Component.onCompleted: {
        content.opacity = 0;
        fadeIn.start();
        enter.start();
    }
    NumberAnimation { id: fadeIn; target: card; property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
    ParallelAnimation {
        id: enter
        NumberAnimation { target: content; property: "x"; to: 0; duration: 300; easing.type: Easing.OutCubic }
        NumberAnimation { target: content; property: "opacity"; to: 1; duration: 240; easing.type: Easing.OutCubic }
    }
    SequentialAnimation {
        id: closeAnim
        NumberAnimation { target: card; property: "opacity"; to: 0; duration: 180; easing.type: Easing.InQuad }
        ScriptAction { script: TallyStore.finishOnboarding() }
    }

    Rectangle {
        id: card
        x: root.pad
        y: root.pad
        width: root.cardW
        height: root.cardH
        radius: 20
        color: TallyTheme.card
        border.width: 1
        border.color: TallyTheme.hair
        focus: true
        Keys.onReturnPressed: root.forward()
        Keys.onEnterPressed: root.forward()
        Keys.onEscapePressed: root.forward(true)
        Keys.onRightPressed: root.go(root.step + 1)
        Keys.onLeftPressed: root.go(root.step - 1)
        Behavior on color { ColorAnimation { duration: 200 } }

        // ---- Header: mark + step dots -------------------------------------------------------------
        Row {
            x: 40
            y: 30
            spacing: 10
            TMark { anchors.verticalCenter: parent.verticalCenter; size: 22 }
            TBig { anchors.verticalCenter: parent.verticalCenter; bigPx: 20; wght: 500; text: "tally" }
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 40
            y: 34
            spacing: 6
            Repeater {
                model: root.steps
                Rectangle {
                    required property int index
                    width: index === root.step ? 22 : 6
                    height: 6
                    radius: 3
                    color: index === root.step ? TallyTheme.acc : TallyTheme.tickOff
                    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                }
            }
        }

        // ---- Content --------------------------------------------------------------------------------------
        Item {
            x: 40
            y: 76
            width: 520
            height: 300
            clip: true

            Item {
                id: content
                width: 520
                height: 300

                // 0 · language
                Item {
                    visible: root.step === 0
                    anchors.fill: parent
                    TBig { bigPx: 40; wght: 500; text: Str.obLangTitle }
                    TText { y: 62; width: 520; px: 13; color: TallyTheme.muted; wrapMode: Text.WordWrap; text: Str.obLangBody }
                    Row {
                        y: 130
                        spacing: 20
                        Repeater {
                            model: [["tr", "Türkçe", "TR"], ["en", "English", "EN"]]
                            Rectangle {
                                id: lang
                                required property var modelData
                                readonly property bool on: Str.tr === (modelData[0] === "tr") && TallyStore.language !== "auto"
                                width: 250
                                height: 110
                                radius: 16
                                color: on ? TallyTheme.segOn : TallyTheme.cell
                                border.width: 1
                                border.color: on ? TallyTheme.fg : TallyTheme.line
                                Behavior on color { ColorAnimation { duration: 160 } }
                                TLabel { x: 20; y: 18; text: modelData[2] }
                                TBig { x: 20; y: 46; bigPx: 34; wght: 500; text: modelData[1] }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: TallyStore.set("language", modelData[0])
                                }
                            }
                        }
                    }
                    Item {
                        y: 262
                        width: autoText.width
                        height: 20
                        TText { id: autoText; px: 12; color: TallyStore.language === "auto" ? TallyTheme.fg : TallyTheme.muted; text: (TallyStore.language === "auto" ? "● " : "○ ") + "Auto · " + (Str.tr ? "sistem dili" : "system language") }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: TallyStore.set("language", "auto") }
                    }
                }

                // 1 · what it is
                Item {
                    visible: root.step === 1
                    anchors.fill: parent
                    TBig { bigPx: 40; wght: 500; text: Str.obWhatTitle }
                    TText { y: 62; width: 520; px: 13; color: TallyTheme.muted; wrapMode: Text.WordWrap; text: Str.obWhatBody }
                    TRuler { y: 118; width: 520; count: 40; filled: 28; major: 10 }
                    Column {
                        y: 168
                        spacing: 14
                        Repeater {
                            model: [["pulse", Str.obPoint1], ["check", Str.obPoint2], ["pause", Str.obPoint3]]
                            Row {
                                required property var modelData
                                spacing: 14
                                Rectangle {
                                    width: 30; height: 30; radius: 9
                                    color: TallyTheme.tile
                                    TIcon { anchors.centerIn: parent; name: modelData[0]; size: 14; color: TallyTheme.acc }
                                }
                                TText { anchors.verticalCenter: parent.verticalCenter; width: 470; px: 12.5; wrapMode: Text.WordWrap; text: modelData[1] }
                            }
                        }
                    }
                }

                // 2 · look
                Item {
                    visible: root.step === 2
                    anchors.fill: parent
                    TBig { bigPx: 40; wght: 500; text: Str.obLookTitle }
                    TText { y: 62; width: 520; px: 13; color: TallyTheme.muted; wrapMode: Text.WordWrap; text: Str.obLookBody }
                    Grid {
                        y: 122
                        columns: 3
                        spacing: 14
                        Repeater {
                            model: ["noir", "vantablack", "ultrawhite", "catppuccin", "gruvbox", "tokyonight"].map(id => Themes.byId(id))
                            Rectangle {
                                id: look
                                required property var modelData
                                readonly property bool on: TallyStore.themeId === modelData.id
                                width: 164
                                height: 78
                                radius: 14
                                color: modelData.card
                                border.width: on ? 2 : 1
                                border.color: on ? modelData.acc : Qt.rgba(0.5, 0.5, 0.5, 0.35)
                                Row {
                                    x: 14; y: 16
                                    spacing: 3
                                    Repeater {
                                        model: look.modelData.sw
                                        Rectangle { required property var modelData; width: 16; height: 16; radius: 4; color: modelData; border.width: 1; border.color: Qt.rgba(0.5, 0.5, 0.5, 0.4) }
                                    }
                                }
                                TText { x: 14; y: 46; px: 13; font.weight: Font.Medium; color: look.modelData.fg; text: Str.themeName(look.modelData) }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: TallyStore.set("themeId", look.modelData.id) }
                            }
                        }
                    }
                }

                // 3 · goal
                Item {
                    visible: root.step === 3
                    anchors.fill: parent
                    TBig { bigPx: 40; wght: 500; text: Str.obGoalTitle }
                    TText { y: 62; width: 520; px: 13; color: TallyTheme.muted; wrapMode: Text.WordWrap; text: Str.obGoalBody }
                    Column {
                        y: 116
                        width: 520
                        Item {
                            width: 520; height: 52
                            TText { anchors.verticalCenter: parent.verticalCenter; px: 12.5; text: Str.obGoalRow }
                            TStepper {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: Str.fmtHours(TallyStore.goalHours)
                                onDec: TallyStore.set("goalHours", Math.max(0.5, TallyStore.goalHours - 0.5))
                                onInc: TallyStore.set("goalHours", Math.min(16, TallyStore.goalHours + 0.5))
                            }
                            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: TallyTheme.line }
                        }
                        Item {
                            width: 520; height: 52
                            TText { anchors.verticalCenter: parent.verticalCenter; px: 12.5; text: Str.pillContent }
                            TSegmented {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                model: [Str.pillIcon, Str.pillIconTime]
                                currentIndex: TallyStore.pillTime ? 1 : 0
                                onPicked: i => TallyStore.set("pillTime", i === 1)
                            }
                            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: TallyTheme.line }
                        }
                        Item {
                            width: 520; height: 52
                            TText { anchors.verticalCenter: parent.verticalCenter; px: 12.5; text: Str.notifyNear }
                            TSwitch {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                checked: TallyStore.notifyNear
                                onToggled: v => TallyStore.set("notifyNear", v)
                            }
                            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: TallyTheme.line }
                        }
                    }
                    TText { y: 282; px: 11; color: TallyTheme.faint; text: Str.obHint }
                }
            }
        }

        // ---- Footer -------------------------------------------------------------------------------------------
        Item {
            x: 40
            y: root.cardH - 74
            width: 520
            height: 44

            Rectangle {
                visible: root.step > 0
                width: backText.width + 36
                height: 40
                radius: 12
                color: "transparent"
                border.width: 1
                border.color: TallyTheme.outline
                TText { id: backText; anchors.centerIn: parent; px: 12.5; font.weight: Font.Medium; text: Str.back }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.go(root.step - 1) }
            }
            TText { anchors.centerIn: parent; px: 10.5; color: TallyTheme.faint; text: Str.obStep(root.step, root.steps) }
            Item {
                visible: root.step < root.steps - 1
                anchors.right: nextBtn.left
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                width: skipText.width
                height: 24
                TText { id: skipText; anchors.centerIn: parent; px: 12; color: skipMa.containsMouse ? TallyTheme.fg : TallyTheme.muted; text: Str.skip }
                MouseArea { id: skipMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.forward(true) }
            }
            Rectangle {
                id: nextBtn
                anchors.right: parent.right
                width: nextText.width + 44
                height: 40
                radius: 12
                color: TallyTheme.fg
                TText { id: nextText; anchors.centerIn: parent; px: 12.5; font.weight: Font.Medium; color: TallyTheme.card; text: root.step === root.steps - 1 ? Str.obStart : Str.next }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.forward() }
            }
        }
    }
}
