import QtQuick
import QtQuick.Layouts
import ".." as Root

Root.BarWidget {
    id: caffeineWidget
    acceptedButtons: Qt.LeftButton
    tintColor: Root.Theme.yellow

    readonly property bool active: Root.Caffeine.active

    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton)
            Root.Caffeine.toggle()
    }

    // Coffee icon — lit when caffeinated (idle disabled), dim otherwise.
    // Matches the glyphs shown in the Super+Shift+C toast (caffeine.sh).
    Text {
        text: caffeineWidget.active ? "󰛊" : "󰾪"
        font.pixelSize: Root.Theme.iconFontSize
        font.family: Root.Theme.fontFamily
        color: caffeineWidget.active ? Root.Theme.yellow : Root.Theme.on.surfaceVariant

        Behavior on color {
            ColorAnimation { duration: Root.Theme.durationFast }
        }
    }
}
