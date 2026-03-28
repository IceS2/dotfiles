import QtQuick
import QtQuick.Layouts
import ".." as Root

Root.BarWidget {
    id: sessionWidget
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    tintColor: Root.Theme.flamingo

    readonly property int totalCount: Root.Notifications.count
    readonly property int criticalCount: Root.Notifications.criticalCount
    readonly property bool dnd: Root.Notifications.dnd

    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton)
            Root.Notifications.toggleCenter()
        else if (mouse.button === Qt.RightButton)
            Root.Notifications.toggleDnd()
    }

    // Bell icon with notification overlay
    Item {
        Layout.preferredWidth: Root.Theme.iconFontSize
        Layout.preferredHeight: Root.Theme.iconFontSize

        Text {
            anchors.centerIn: parent
            text: sessionWidget.dnd ? "󰂛" : "󰂚"
            font.pixelSize: Root.Theme.iconFontSize
            font.family: Root.Theme.fontFamily
            color: sessionWidget.dnd ? Root.Theme.error : Root.Theme.flamingo

            Behavior on color {
                ColorAnimation { duration: Root.Theme.durationFast }
            }
        }

        // Normal notification dot (non-critical)
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: -2
            anchors.rightMargin: -2
            width: 6
            height: 6
            radius: 3
            color: Root.Theme.primary
            visible: sessionWidget.totalCount > 0 && sessionWidget.criticalCount === 0 && !sessionWidget.dnd
        }

        // Critical badge with count
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: -4
            anchors.rightMargin: -6
            width: Math.max(14, critBadgeText.implicitWidth + 6)
            height: 14
            radius: 7
            color: Root.Theme.error
            visible: sessionWidget.criticalCount > 0 && !sessionWidget.dnd

            Text {
                id: critBadgeText
                anchors.centerIn: parent
                text: sessionWidget.criticalCount > 99 ? "99+" : sessionWidget.criticalCount
                font.pixelSize: 8
                font.family: Root.Theme.fontFamilyMono
                font.weight: Font.Bold
                color: Root.Theme.surface
            }
        }
    }
}
