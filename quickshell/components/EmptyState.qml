import QtQuick
import QtQuick.Layouts
import ".." as Root

Item {
    id: root

    // Properties
    property string message: "No results found"
    property string subtext: ""
    property string icon: ""
    property int iconSize: Root.Theme.iconSizeLarge

    anchors.centerIn: parent
    width: parent.width
    height: 200

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Root.Theme.spacingLarge

        // Icon (if provided)
        Text {
            text: icon
            font.pixelSize: iconSize
            color: Root.Theme.on.surfaceVariant
            Layout.alignment: Qt.AlignHCenter
            visible: icon !== ""
        }

        // Message
        Text {
            text: message
            font.pixelSize: Root.Theme.fontSizeLarge
            font.family: Root.Theme.fontFamily
            font.weight: Root.Theme.fontWeight
            color: Root.Theme.on.surfaceVariant
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
        }

        // Subtext (optional)
        Text {
            text: subtext
            font.pixelSize: Root.Theme.fontSizeSmall
            font.family: Root.Theme.fontFamily
            color: Root.Theme.outline
            opacity: 0.7
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
            visible: subtext !== ""
        }
    }
}
