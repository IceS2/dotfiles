import QtQuick
import ".." as Root

Rectangle {
    id: button

    property string icon: ""
    property color iconColor: Root.Theme.on.surface
    property int size: 32
    property int iconSize: Root.Theme.iconFontSize

    readonly property alias hovered: mouseArea.containsMouse

    signal clicked()

    width: size
    height: size
    radius: Root.Theme.borderRadiusSmall
    color: mouseArea.containsMouse ? Root.Theme.surfaceContainer : "transparent"

    Behavior on color { Root.CAnim {} }

    Text {
        anchors.centerIn: parent
        text: button.icon
        font.pixelSize: button.iconSize
        font.family: Root.Theme.fontFamily
        color: button.iconColor
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}
