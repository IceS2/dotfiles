import QtQuick
import ".." as Root

Rectangle {
    id: listItem

    // Required from ListView model
    required property var modelData
    required property int index

    // Children go into the content area
    default property alias content: contentArea.data

    // State
    property bool isSelected: ListView.isCurrentItem

    // Signals
    signal clicked()
    signal hovered()

    // Appearance
    width: ListView.view ? ListView.view.width - 8 : 0
    height: Root.Theme.itemHeightNormal
    color: isSelected ? Root.Theme.surfaceContainerHigh : "transparent"
    radius: Root.Theme.borderRadiusMedium

    Behavior on color {
        ColorAnimation { duration: Root.Theme.durationFast }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onEntered: listItem.hovered()
        onClicked: listItem.clicked()
    }

    // Expose hover state for children that need it
    readonly property alias itemHovered: mouseArea.containsMouse

    Item {
        id: contentArea
        anchors.fill: parent
    }
}
