import QtQuick
import ".." as Root

ColorAnimation {
    duration: Root.Theme.durationNormalMD3
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Root.Theme.curveStandard
}
