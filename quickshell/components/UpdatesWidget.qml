import QtQuick
import QtQuick.Layouts
import ".." as Root

Root.BarWidget {
    id: updatesWidget
    acceptedButtons: Qt.LeftButton
    anchorTarget: Root.Updates
    anchorProperty: "anchorX"
    tintColor: Root.Updates.hasCritical ? Root.Theme.error : Root.Theme.yellow

    // Ghost widget: parent BarPill binds visible to this
    readonly property bool hasUpdates: Root.Updates.hasUpdates

    onClicked: {
        updateAnchor()
        Root.Updates.togglePopup()
    }

    // Package icon
    Text {
        text: "󰏔"
        font.pixelSize: Root.Theme.iconFontSize
        font.family: Root.Theme.fontFamily
        color: Root.Updates.hasCritical ? Root.Theme.error : Root.Theme.yellow
        Layout.alignment: Qt.AlignVCenter

        Behavior on color {
            ColorAnimation { duration: Root.Theme.durationFast }
        }
    }

    // Update count
    Text {
        text: Root.Updates.totalCount
        font.pixelSize: Root.Theme.fontSizeSmall
        font.family: Root.Theme.fontFamilyMono
        font.weight: Root.Theme.fontWeight
        color: Root.Updates.hasCritical ? Root.Theme.error : Root.Theme.yellow
        Layout.alignment: Qt.AlignVCenter

        Behavior on color {
            ColorAnimation { duration: Root.Theme.durationFast }
        }
    }
}
