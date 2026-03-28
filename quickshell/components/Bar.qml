import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".." as Root

PanelWindow {
    id: barWindow

    required property var screenObj

    // ─── Configuration ───
    property bool persistent: true
    property bool barVisible: true

    // ─── Content Slots (data aliases — children go directly into layout) ───
    default property alias startContent: _startRow.data
    property alias centerContent: _centerItem.data
    property alias endContent: _endRow.data

    // ─── Computed ───
    readonly property int contentSize: Root.Theme.barHeight
    readonly property int triggerSize: Root.Theme.barTriggerSize
    readonly property bool shouldBeVisible: persistent || barVisible || hoverArea.containsMouse

    // ─── GlobalState sync ───
    Component.onCompleted: {
        Root.GlobalState.barEdge = "top"
        Root.GlobalState.barContentSize = barWindow.contentSize
        Root.GlobalState.setBarVisible(screenObj.name, shouldBeVisible)
    }
    onShouldBeVisibleChanged: Root.GlobalState.setBarVisible(screenObj.name, shouldBeVisible)

    // ─── Screen & Layer ───
    screen: screenObj
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-bar"

    // When hidden, don't reserve screen space (symmetric gaps)
    exclusionMode: barWindow.shouldBeVisible ? ExclusionMode.Auto : ExclusionMode.Ignore

    // ─── Anchors ───
    anchors {
        top: true
        left: true
        right: true
    }

    // ─── Size: animates between triggerSize and contentSize ───
    implicitHeight: barWindow.shouldBeVisible ? contentSize : triggerSize

    Behavior on implicitHeight {
        enabled: !barWindow.persistent
        Root.Anim {
            duration: Root.Theme.durationExpressiveDefaultSpatial
            easing.bezierCurve: Root.Theme.curveExpressiveDefaultSpatial
        }
    }

    // ─── Hover Detection ───
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    // ─── Content ───
    // No background — BorderFrame provides the visual backdrop
    Item {
        id: barContent

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: barWindow.contentSize

        clip: true
        visible: barWindow.implicitHeight > barWindow.triggerSize

        // Start + End pushed to edges
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Root.Theme.paddingSmall
            anchors.rightMargin: Root.Theme.paddingSmall
            spacing: Root.Theme.spacingMedium

            RowLayout {
                id: _startRow
                spacing: Root.Theme.pillGap
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                id: _endRow
                spacing: Root.Theme.pillGap
            }
        }

        // Center content truly centered on screen
        Row {
            id: _centerItem
            anchors.centerIn: parent
        }
    }
}
