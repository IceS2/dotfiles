import QtQuick
import QtQuick.Layouts
import ".." as Root

Root.BarWidget {
    id: clockWidget
    acceptedButtons: Qt.LeftButton
    anchorTarget: Root.Calendar
    tintColor: Root.Theme.lavender

    onClicked: {
        updateAnchor()
        Root.Calendar.togglePopup()
    }

    onWheel: wheel => {
        if (Root.Weather.locations.length > 1) {
            if (wheel.angleDelta.y > 0) Root.Weather.cyclePrimary(-1)
            else Root.Weather.cyclePrimary(1)
        }
    }

    property string format: "hh:mm"
    property bool _hasWeather: Root.Weather.locations.length > 0 && Root.Weather.primaryTemp !== "--"

    // Weather icon
    Text {
        visible: clockWidget._hasWeather
        text: Root.Weather.primaryIcon
        font.pixelSize: Root.Theme.iconFontSize
        font.family: Root.Theme.fontFamily
        color: Root.Theme.sky

        Behavior on color {
            ColorAnimation { duration: Root.Theme.durationFast }
        }
    }

    // Weather temperature
    Text {
        visible: clockWidget._hasWeather
        text: Root.Weather.primaryTemp
        font.pixelSize: Root.Theme.fontSizeNormal
        font.family: Root.Theme.fontFamily
        font.weight: Root.Theme.fontWeight
        color: Root.Theme.on.surface
    }

    // Weather/clock separator
    Text {
        visible: clockWidget._hasWeather
        text: "\u00B7"
        font.pixelSize: Root.Theme.fontSizeNormal
        font.family: Root.Theme.fontFamily
        color: Root.Theme.outline
    }

    // Clock icon
    Text {
        text: "󰃭"
        font.pixelSize: Root.Theme.iconFontSize
        font.family: Root.Theme.fontFamily
        color: Root.Theme.lavender

        Behavior on color {
            ColorAnimation { duration: Root.Theme.durationFast }
        }
    }

    // Clock time
    Text {
        text: Root.Clock.formatTime(format)
        font.pixelSize: Root.Theme.fontSizeNormal
        font.family: Root.Theme.fontFamilyMono
        font.weight: Root.Theme.fontWeight
        color: Root.Theme.on.surface
    }
}
