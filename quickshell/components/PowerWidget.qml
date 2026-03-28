import QtQuick
import QtQuick.Layouts
import ".." as Root

Root.BarWidget {
    id: powerWidget
    tintColor: Root.Theme.error

    onClicked: mouse => {
        Root.PowerMenu.togglePopup()
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: "󰐥"
        font.pixelSize: Root.Theme.iconFontSize
        font.family: Root.Theme.fontFamily
        color: Root.PowerMenu.popupVisible ? Root.Theme.error : Root.Theme.on.surface
        opacity: Root.PowerMenu.popupVisible ? 1.0 : 0.85

        Behavior on color {
            ColorAnimation { duration: Root.Theme.durationFast }
        }
    }
}
