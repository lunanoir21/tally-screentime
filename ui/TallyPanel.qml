import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// The card that hangs under the pill. Lives only while open: the host
// creates it on open and unloads it after the closing animation, so a
// closed Tally holds no window and no scene graph.
//
// Open: scale .85 -> 1 from the notch, 320 ms OutExpo. Close: content
// 150 ms, card 280 ms InExpo. Page changes cross-fade in 150 ms and the
// card eases to the new page's height in 260 ms.
PanelWindow {
    id: root

    signal dismissed()

    readonly property int pad: 40
    readonly property int cardWidth: 400
    readonly property int rightInset: 14
    readonly property real topGap: TallyStore.anchorBottom + 10
    readonly property real maxCard: Math.max(300, (screen ? screen.height : 1080) - topGap - 16)
    readonly property real wantCard: (front.item ? front.item.pageHeight : 740) + 40 + (tabbed ? 32 : 0)
    property real cardHeight: Math.min(wantCard, maxCard)
    property bool closing: false

    WlrLayershell.namespace: "tally-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    color: "transparent"

    anchors { top: true; right: true }
    margins {
        top: Math.max(0, root.topGap - root.pad)
        right: Math.max(0, root.rightInset - root.pad)
    }

    implicitWidth: cardWidth + pad * 2
    implicitHeight: maxCard + pad * 2
    mask: Region { item: cardWrap }

    // Where along the card the notch sits: straight under the pill.
    readonly property real notchX: {
        if (TallyStore.anchorX < 0 || !screen)
            return cardWidth - 40;
        var cardLeft = screen.width - rightInset - cardWidth;
        return Math.max(26, Math.min(cardWidth - 26, TallyStore.anchorX - cardLeft));
    }

    Behavior on cardHeight { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    function requestClose() {
        if (root.closing)
            return;
        root.closing = true;
        openAnim.stop();
        closeAnim.start();
    }

    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: cardWrap; property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
        NumberAnimation { target: cardWrap; property: "pop"; from: 0.85; to: 1; duration: 320; easing.type: Easing.OutExpo }
    }
    SequentialAnimation {
        id: closeAnim
        NumberAnimation { target: stage; property: "opacity"; to: 0; duration: 150; easing.type: Easing.OutQuad }
        ParallelAnimation {
            NumberAnimation { target: cardWrap; property: "pop"; to: 0.85; duration: 280; easing.type: Easing.InExpo }
            NumberAnimation { target: cardWrap; property: "opacity"; to: 0; duration: 280; easing.type: Easing.InExpo }
        }
        ScriptAction { script: root.dismissed() }
    }

    // Click outside closes. Clicking the pill clears the grab too; the
    // store remembers that so the same click doesn't reopen us. The theme
    // picker is a second window of the same session, so it joins the grab.
    HyprlandFocusGrab {
        windows: TallyStore.pickerOpen && TallyStore.pickerWin ? [root, TallyStore.pickerWin] : [root]
        active: !root.closing && !TallyTracker.demo && Quickshell.env("TALLY_KEEP_OPEN") !== "1"
        onCleared: {
            // Making a report puts a surface on screen (the render window, then
            // a notification) and the compositor reports the grab as cleared.
            // That is not a click outside: keep the card, so "Open" is there.
            if (TallyExport.guarded())
                return;
            TallyStore.autoClosed("panel");
            TallyStore.closePicker();
            TallyStore.closePanel();
        }
    }

    // ---- Pages ---------------------------------------------------------------------
    readonly property var tabOrder: ({ day: 0, week: 1, map: 2 })
    readonly property bool tabbed: TallyStore.page in tabOrder
    property string shown: ""
    property bool frontA: true
    readonly property var front: frontA ? slotA : slotB
    readonly property var back: frontA ? slotB : slotA

    function pageUrl(p) {
        switch (p) {
        case "week": return "PageWeek.qml";
        case "map": return "PageMap.qml";
        case "apps": return "PageApps.qml";
        case "app": return "PageApp.qml";
        case "settings": return "PageSettings.qml";
        case "focus": return "PageFocus.qml";
        case "export": return "PageExport.qml";
        default: return "PageDay.qml";
        }
    }
    // +1 = the new page comes from the right. Tabs follow their order; a
    // page you drill into comes from the right and goes back to the left.
    function direction(from, to) {
        if (from in tabOrder && to in tabOrder)
            return tabOrder[to] > tabOrder[from] ? 1 : -1;
        var drill = { apps: 1, app: 2, settings: 1, focus: 1, export: 2 };
        return (drill[to] || 0) >= (drill[from] || 0) && !(to in tabOrder) ? 1 : -1;
    }
    function show(p, animate) {
        if (p === root.shown)
            return;
        var dir = root.direction(root.shown, p);
        var incoming = root.back;
        var outgoing = root.front;
        root.frontA = !root.frontA;
        incoming.pendingDir = animate ? dir : 0;
        incoming.load(root.pageUrl(p));
        if (animate && outgoing.item)
            outgoing.leave(dir);
        root.shown = p;
        guard.restart();
    }
    // Safety net: whatever happened, the page the store names must end up
    // built and visible. If the slot in front is empty or still transparent
    // shortly after a change, build it again without animation.
    Timer {
        id: guard
        interval: 450
        onTriggered: {
            var f = root.front;
            var url = root.pageUrl(TallyStore.page);
            if (!f.item || f.opacity < 0.99 && !f.leaving) {
                f.pendingDir = 0;
                f.load(url);
            }
            if (root.shown !== TallyStore.page)
                root.show(TallyStore.page, false);
        }
    }
    Connections {
        target: TallyStore
        function onPageChanged() { root.show(TallyStore.page, true) }
    }

    Item {
        id: cardWrap
        x: root.pad
        y: root.pad
        width: root.cardWidth
        height: root.cardHeight
        opacity: 0
        property real pop: 0.85

        // The shadow is cast by a plain silhouette, not by the card: the
        // blur is rendered once, however often the contents change.
        Rectangle {
            id: silhouette
            anchors.fill: parent
            radius: 20
            color: "black"
            visible: false
        }
        MultiEffect {
            anchors.fill: silhouette
            source: silhouette
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.55)
            shadowBlur: 1.0
            blurMax: 60
            shadowVerticalOffset: 24
            autoPaddingEnabled: true
        }

        transform: Scale {
            origin.x: root.notchX
            origin.y: 0
            xScale: cardWrap.pop
            yScale: cardWrap.pop
        }

        // Notch: a rotated square tucked behind the card's top edge.
        Rectangle {
            width: 12
            height: 12
            rotation: 45
            x: root.notchX - width / 2
            y: -6
            color: TallyTheme.card
            border.width: 1
            border.color: TallyTheme.alpha(TallyTheme.fg, 0.14)
        }

        Rectangle {
            id: card
            anchors.fill: parent
            radius: 20
            color: TallyTheme.card
            border.width: 1
            border.color: TallyTheme.hair
            Behavior on color { ColorAnimation { duration: 200 } }

            // Hides the notch square's lower half and its border seam.
            Rectangle {
                x: root.notchX - 9
                y: 1
                width: 18
                height: 7
                color: TallyTheme.card
            }

            focus: true
            Keys.onEscapePressed: {
                if (TallyStore.pickerOpen)
                    TallyStore.closePicker();
                else if (root.tabbed)
                    TallyStore.closePanel();
                else
                    TallyStore.goto(TallyStore.page === "export" ? TallyStore.backPage : TallyStore.page === "app" ? (TallyStore.backPage === "day" ? "apps" : TallyStore.backPage) : "day");
            }
            Keys.onLeftPressed: if (root.front.item && root.front.item.shift) root.front.item.shift(TallyStore.page === "week" ? -7 : -1)
            Keys.onRightPressed: if (root.front.item && root.front.item.shift) root.front.item.shift(TallyStore.page === "week" ? 7 : 1)

            // The tab header stays put while the pages under it change.
            TTabHeader {
                id: tabs
                x: 20
                y: 20
                width: root.cardWidth - 40
                current: root.tabbed ? root.tabOrder[TallyStore.page] : 0
                opacity: root.tabbed ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }

            Item {
                id: stage
                x: 20
                y: root.tabbed ? 52 : 20
                width: root.cardWidth - 40
                height: root.cardHeight - y - 20
                clip: true
                Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

                TPageSlot {
                    id: slotA
                    property int pendingDir: 0
                    width: stage.width
                    height: stage.height
                    onReady: enter(pendingDir)
                }
                TPageSlot {
                    id: slotB
                    property int pendingDir: 0
                    width: stage.width
                    height: stage.height
                    onReady: enter(pendingDir)
                }
            }
        }
    }

    Component.onCompleted: {
        openAnim.start();
        root.show(TallyStore.page, false);
    }
}
