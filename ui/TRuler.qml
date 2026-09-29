import QtQuick

// The signature: a row of tick marks. `filled` of `count` are ink, the
// one at filled-1 takes the accent, the rest are faint. Every `major`-th
// tick is taller.
Item {
    id: root

    property int count: 40
    property int filled: 0
    property int major: 10
    property real tickWidth: 6
    property real tallHeight: 22
    property real shortHeight: 14
    property bool accentLast: true
    // Index drawn in the accent; -1 = none. Defaults to the last filled tick.
    property int accentAt: accentLast ? filled - 1 : -1
    // Ticks before this index are drawn as "spent" (focus countdown).
    property int spent: 0
    property color onColor: TallyTheme.fg
    property color offColor: TallyTheme.tickOff
    property color accentColor: TallyTheme.acc

    implicitHeight: tallHeight

    Repeater {
        model: root.count
        Rectangle {
            required property int index
            x: index * (root.width - root.tickWidth) / Math.max(1, root.count - 1)
            width: root.tickWidth
            height: index % root.major === 0 ? root.tallHeight : root.shortHeight
            anchors.bottom: parent.bottom
            radius: 2
            color: index < root.spent ? root.offColor
                 : index >= root.filled ? root.offColor
                 : index === root.accentAt ? root.accentColor
                 : root.onColor
        }
    }
}
