import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import ".." as Root

PanelWindow {
    id: borderFrame

    required property var screenObj

    // Read bar state from GlobalState
    readonly property bool barShowing: Root.GlobalState.barVisible[screenObj.name] ?? false
    property int barMargin: barShowing ? Root.GlobalState.barContentSize : Root.Theme.borderFrameThickness

    Behavior on barMargin {
        Root.Anim {
            duration: Root.Theme.durationExpressiveDefaultSpatial
            easing.bezierCurve: Root.Theme.curveExpressiveDefaultSpatial
        }
    }

    screen: screenObj
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-border"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Fully click-through
    mask: Region {}

    // Frame shape — outer rounded rect with inner cutout via OddEvenFill
    Shape {
        id: frameShape
        anchors.fill: parent
        layer.samples: 4

        // Computed margins for the inner cutout
        readonly property int t: Root.Theme.borderFrameThickness
        readonly property int innerTop: Root.GlobalState.barEdge === "top" ? borderFrame.barMargin : t
        readonly property int innerLeft: Root.GlobalState.barEdge === "left" ? borderFrame.barMargin : t
        readonly property int innerRight: t
        readonly property int innerBottom: t
        readonly property real outerR: Root.Theme.borderFrameRounding
        readonly property real innerR: Root.Theme.borderFrameRounding
        readonly property real w: width
        readonly property real h: height

        ShapePath {
            fillColor: Root.Theme.surfaceGlass
            strokeColor: "transparent"
            fillRule: ShapePath.OddEvenFill

            // Outer rounded rectangle (clockwise)
            startX: frameShape.outerR; startY: 0
            PathLine { x: frameShape.w - frameShape.outerR; y: 0 }
            PathArc { x: frameShape.w; y: frameShape.outerR; radiusX: frameShape.outerR; radiusY: frameShape.outerR }
            PathLine { x: frameShape.w; y: frameShape.h - frameShape.outerR }
            PathArc { x: frameShape.w - frameShape.outerR; y: frameShape.h; radiusX: frameShape.outerR; radiusY: frameShape.outerR }
            PathLine { x: frameShape.outerR; y: frameShape.h }
            PathArc { x: 0; y: frameShape.h - frameShape.outerR; radiusX: frameShape.outerR; radiusY: frameShape.outerR }
            PathLine { x: 0; y: frameShape.outerR }
            PathArc { x: frameShape.outerR; y: 0; radiusX: frameShape.outerR; radiusY: frameShape.outerR }

            // Inner rounded rectangle cutout
            PathMove { x: frameShape.innerLeft + frameShape.innerR; y: frameShape.innerTop }
            PathLine { x: frameShape.w - frameShape.innerRight - frameShape.innerR; y: frameShape.innerTop }
            PathArc { x: frameShape.w - frameShape.innerRight; y: frameShape.innerTop + frameShape.innerR; radiusX: frameShape.innerR; radiusY: frameShape.innerR }
            PathLine { x: frameShape.w - frameShape.innerRight; y: frameShape.h - frameShape.innerBottom - frameShape.innerR }
            PathArc { x: frameShape.w - frameShape.innerRight - frameShape.innerR; y: frameShape.h - frameShape.innerBottom; radiusX: frameShape.innerR; radiusY: frameShape.innerR }
            PathLine { x: frameShape.innerLeft + frameShape.innerR; y: frameShape.h - frameShape.innerBottom }
            PathArc { x: frameShape.innerLeft; y: frameShape.h - frameShape.innerBottom - frameShape.innerR; radiusX: frameShape.innerR; radiusY: frameShape.innerR }
            PathLine { x: frameShape.innerLeft; y: frameShape.innerTop + frameShape.innerR }
            PathArc { x: frameShape.innerLeft + frameShape.innerR; y: frameShape.innerTop; radiusX: frameShape.innerR; radiusY: frameShape.innerR }
        }
    }
}
