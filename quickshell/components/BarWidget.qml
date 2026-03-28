import QtQuick
import QtQuick.Layouts
import ".." as Root

Item {
    id: barWidget
    implicitWidth: contentLayout.implicitWidth
    implicitHeight: contentLayout.implicitHeight

    // Children declared inside BarWidget go into the RowLayout
    default property alias content: contentLayout.data

    // MouseArea configuration
    property int acceptedButtons: Qt.LeftButton | Qt.RightButton

    // Popup anchor — set anchorTarget to a service with an anchorX property
    // and the widget will auto-update it on creation and resize
    property QtObject anchorTarget: null
    property string anchorProperty: "anchorX"

    function updateAnchor() {
        if (anchorTarget) anchorTarget[anchorProperty] = mapToGlobal(width / 2, 0).x
    }

    Component.onCompleted: if (anchorTarget) Qt.callLater(updateAnchor)
    onWidthChanged: if (anchorTarget) Qt.callLater(updateAnchor)

    // Category color — used by BarPill for hover tint and active border
    property color tintColor: Root.Theme.on.surface

    // Exposed state
    readonly property alias hovered: mouseArea.containsMouse
    readonly property alias pressed: mouseArea.pressed

    // Signals
    signal clicked(var mouse)
    signal wheel(var wheel)

    RowLayout {
        id: contentLayout
        anchors.fill: parent
        spacing: Root.Theme.spacingSmall
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: barWidget.acceptedButtons

        onClicked: mouse => barWidget.clicked(mouse)
        onWheel: wheel => barWidget.wheel(wheel)
    }

    // Subtle opacity feedback on hover (scale removed — overflows pill containers)
    opacity: mouseArea.containsMouse ? 1.0 : 0.85

    Behavior on opacity {
        NumberAnimation {
            duration: Root.Theme.durationFast
            easing.type: Easing.OutCubic
        }
    }
}
