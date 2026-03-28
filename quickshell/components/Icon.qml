import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import ".." as Root

Item {
    id: root

    // Properties
    required property string icon
    property int size: Root.Theme.iconSizeNormal

    width: size
    height: size

    // App icon
    IconImage {
        id: iconImage
        anchors.fill: parent
        source: Quickshell.iconPath(icon || "", true)
        visible: source !== ""
        mipmap: true
        smooth: true
    }
}
