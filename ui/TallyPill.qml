import QtQuick
import QtQuick.Shapes
import Quickshell
import "js/Model.js" as Model

// The bar pill. Left click: panel. Right click: settings. Hover: a tip.
//
// States: icon only / icon + time, hover, focus session (ring + countdown),
// idle (paused glyph, frozen time), goal reached (arrow, full line).
// `size` is the bar's height; the pill fills it, like the buttons around it.
Item {
    id: root

    property real size: 44
    property real barTop: 0
    property real barLeft: 0
    property string screenName: ""
    // Chrome from the host bar, so the pill sits flush beside its neighbours.
    // Unset, it falls back to the current theme.
    property color chromeBase: TallyTheme.mix(TallyTheme.fg, TallyTheme.card, 0.10)
    property color chromeHover: TallyTheme.mix(TallyTheme.fg, TallyTheme.card, 0.18)
    property color chromeText: TallyTheme.fg
    property real radius: Math.round(size * 0.29)

    readonly property real ph: size
    readonly property real px: Math.max(10, Math.round(size * 0.26))
    readonly property real goalMs: TallyStore.goalHours * 3600000
    readonly property real total: TallyTracker.today.total
    readonly property real progress: goalMs > 0 ? total / goalMs : 0
    readonly property bool session: TallyStore.focusActive
    readonly property bool idle: TallyTracker.idle && !session
    readonly property bool over: progress >= 1 && goalMs > 0
    readonly property bool showText: TallyStore.pillTime || session
    readonly property string label: session ? Model.clock(TallyStore.focusRemaining)
        : idle ? TallyTracker.barLabel + Str.idleSuffix : TallyTracker.barLabel

    visible: TallyStore.pillVisible
    implicitWidth: visible ? chrome.width : 0
    implicitHeight: size

    function publishAnchor() {
        var p = chrome.mapToItem(null, chrome.width / 2, chrome.height + (root.height - chrome.height) / 2);
        TallyStore.anchorX = p.x + root.barLeft;
        TallyStore.anchorBottom = p.y + root.barTop;
        TallyStore.anchorScreen = root.screenName;
    }
    Component.onCompleted: Qt.callLater(publishAnchor)
    onXChanged: Qt.callLater(publishAnchor)
    onWidthChanged: Qt.callLater(publishAnchor)

    Rectangle {
        id: chrome
        anchors.verticalCenter: parent.verticalCenter
        height: root.ph
        width: root.showText ? content.width + Math.round(root.size * 0.5) : root.size
        radius: root.radius
        border.width: 1
        border.color: Qt.rgba(root.chromeText.r, root.chromeText.g, root.chromeText.b, ma.containsMouse ? 0.15 : 0.08)
        color: Qt.rgba(root.chromeBase.r, root.chromeBase.g, root.chromeBase.b, ma.containsMouse ? 0.9 : root.idle ? 0.55 : 0.75)
        Behavior on color { ColorAnimation { duration: 160 } }
        Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        Row {
            id: content
            anchors.centerIn: parent
            spacing: 7

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.round(root.size * 0.4)
                height: width

                TIcon {
                    visible: !root.session
                    anchors.fill: parent
                    name: root.idle ? "pause" : root.over ? "up" : "pulse"
                    size: parent.width
                    stroke: root.over ? 2.4 : 2
                    color: root.idle ? TallyTheme.muted : TallyTheme.acc
                }
                Shape {
                    visible: root.session
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: TallyTheme.alpha(TallyTheme.fg, 0.16)
                        strokeWidth: 2
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathAngleArc { centerX: 8; centerY: 8; radiusX: 6; radiusY: 6; startAngle: 0; sweepAngle: 360 }
                    }
                    ShapePath {
                        strokeColor: TallyTheme.acc
                        strokeWidth: 2
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathAngleArc {
                            centerX: 8; centerY: 8; radiusX: 6; radiusY: 6
                            startAngle: -90
                            sweepAngle: 360 * Math.min(0.999, TallyStore.focusRemaining / (TallyStore.focusMinutes * 60000))
                        }
                    }
                }
            }
            TText {
                visible: root.showText
                anchors.verticalCenter: parent.verticalCenter
                px: root.px
                font.weight: root.idle ? Font.Normal : Font.Medium
                color: root.idle ? TallyTheme.alpha(root.chromeText, 0.6) : root.chromeText
                text: root.label
            }
        }

        // Goal line under the pill.
        Rectangle {
            visible: TallyStore.pillGoalLine && root.goalMs > 0 && !root.session
            x: root.showText ? Math.round(root.size * 0.25) : Math.round(root.size * 0.22)
            y: parent.height - 5
            width: parent.width - 2 * x
            height: 2
            radius: 1
            color: TallyTheme.alpha(TallyTheme.fg, 0.14)
            Rectangle {
                width: parent.width * Math.min(1, root.progress)
                height: 2
                radius: 1
                color: TallyTheme.acc
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: chrome
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            root.publishAnchor();
            if (mouse.button === Qt.RightButton) {
                // A click outside the card closes it just before this handler
                // runs, so "was settings showing" comes from the store.
                var was = TallyStore.panelOpen ? TallyStore.page : (TallyStore.recentlyAutoClosed("panel") ? TallyStore.lastClosedPage : "");
                if (was === "settings")
                    TallyStore.closePanel();
                else
                    TallyStore.openPanel("settings");
            } else {
                TallyStore.togglePanel();
            }
        }
    }

    // Hover tip after a short dwell (a popup surface exists only while shown).
    Timer {
        id: dwell
        interval: 400
        running: ma.containsMouse && !TallyStore.panelOpen
        onTriggered: tip.visible = true
    }
    Connections {
        target: ma
        function onContainsMouseChanged() { if (!ma.containsMouse) tip.visible = false; }
    }
    Connections {
        target: TallyStore
        function onPanelOpenChanged() { if (TallyStore.panelOpen) tip.visible = false; }
    }

    PopupWindow {
        id: tip
        visible: false
        anchor.item: chrome
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 8
        implicitWidth: tipText.implicitWidth + 22
        implicitHeight: tipText.implicitHeight + 14
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 9
            color: TallyTheme.mix(TallyTheme.fg, TallyTheme.card, 0.10)
            border.width: 1
            border.color: TallyTheme.alpha(TallyTheme.fg, 0.14)
            TText {
                id: tipText
                anchors.centerIn: parent
                px: 10.5
                text: root.total > 0
                    ? Str.tipToday(TallyTracker.barLabel, root.goalMs > 0 ? Math.round(root.progress * 100) : -1)
                    : Str.tipEmpty
            }
        }
    }
}
