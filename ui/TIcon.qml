import QtQuick
import QtQuick.Shapes
import "js/Icons.js" as Icons

// Stroke icon on a 24 x 24 grid, drawn by the GPU as a path (no canvas,
// no image), so it costs nothing while nothing changes.
Item {
    id: root

    property string name: "pulse"
    property color color: TallyTheme.fg
    property real size: 14
    property real stroke: 2
    readonly property bool filled: Icons.FILLED[name] === true

    width: size
    height: size

    Shape {
        width: 24
        height: 24
        scale: root.size / 24
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.filled ? "transparent" : root.color
            strokeWidth: root.filled ? 0 : root.stroke
            fillColor: root.filled ? root.color : "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: Icons.PATHS[root.name] || "" }
        }
    }
}
