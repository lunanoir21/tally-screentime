import QtQuick

// One of the panel's two page slots. A page arrives by sliding in from the
// side it is coming from while the other slot slides out; the slot that
// leaves unloads its page when it is gone.
Loader {
    id: slot

    property real slide: 0
    property bool leaving: false
    signal ready()

    x: slide
    opacity: 0

    // Point the slot at a page; it announces itself with ready() once built.
    // A slot that still holds the very page being asked for (it was leaving
    // and has not been emptied yet) gets no `loaded` signal from a same-URL
    // assignment, so it is announced by hand: without this the page would
    // stay built but invisible.
    function load(url) {
        leaveAnim.stop();
        leaving = false;
        opacity = 0;
        var cur = source.toString();
        if (item && cur.length >= url.length && cur.slice(cur.length - url.length) === url)
            ready();
        else
            source = url;
    }
    function enter(dir) {
        leaveAnim.stop();
        leaving = false;
        slide = dir * 26;
        opacity = 0;
        enterAnim.restart();
    }
    function leave(dir) {
        enterAnim.stop();
        leaving = true;
        leaveAnim.dir = -dir * 26;
        leaveAnim.restart();
    }

    onLoaded: {
        item.width = Qt.binding(() => slot.width);
        item.height = Qt.binding(() => slot.height);
        slot.ready();
    }

    ParallelAnimation {
        id: enterAnim
        NumberAnimation { target: slot; property: "slide"; to: 0; duration: 300; easing.type: Easing.OutCubic }
        NumberAnimation { target: slot; property: "opacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
    }
    SequentialAnimation {
        id: leaveAnim
        property real dir: 0
        ParallelAnimation {
            NumberAnimation { target: slot; property: "slide"; to: leaveAnim.dir; duration: 180; easing.type: Easing.InCubic }
            NumberAnimation { target: slot; property: "opacity"; to: 0; duration: 150; easing.type: Easing.InQuad }
        }
        ScriptAction { script: if (slot.leaving) slot.source = "" }
    }
}
