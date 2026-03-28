import QtQuick
import ".." as Root

NumberAnimation {
    duration: Root.Theme.durationNormalMD3
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Root.Theme.curveStandard
}
