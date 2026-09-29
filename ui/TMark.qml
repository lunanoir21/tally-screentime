import QtQuick
import QtQuick.Shapes

// The Tally mark: a pulse line that ends on a tick. Drawn as paths, so it is
// sharp at any size and costs nothing while it is not changing.
Item {
    id: root

    property real size: 24
    property color ink: TallyTheme.fg
    property color accent: TallyTheme.acc

    width: size
    height: size

    Shape {
        width: 64
        height: 64
        scale: root.size / 64
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.ink
            strokeWidth: 5
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: "M7 38H17L23 16L32 50L39 26L43 34H50" }
        }
        ShapePath {
            strokeColor: root.accent
            strokeWidth: 5
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathSvg { path: "M58 20V46" }
        }
    }
}
