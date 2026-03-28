import QtQuick
import QtQuick.Layouts
import ".." as Root

Root.BarWidget {
    id: volumeWidget
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    anchorTarget: Root.Audio
    anchorProperty: "anchorX"
    tintColor: Root.Theme.rosewater

    readonly property int volumePercent: Root.Audio.volumePercent
    readonly property bool muted: Root.Audio.muted
    readonly property string volumeIcon: Root.Audio.volumeIcon
    readonly property color iconColor: {
        if (Root.Audio.initializing) return Root.Theme.on.surfaceVariant
        if (muted) return Root.Theme.error
        if (volumePercent > 100) return Root.Theme.caution
        return Root.Theme.rosewater
    }

    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            updateAnchor()
            Root.Audio.togglePopup()
        } else if (mouse.button === Qt.RightButton) {
            Root.Audio.toggleMute()
        }
    }

    onWheel: wheel => {
        var delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
        Root.Audio.adjustVolume(delta)
        Root.Toast.showProgress(Root.Audio.volumeIcon, Root.Audio.volumePercent / 100, Root.Audio.muted)
    }

    Text {
        text: volumeIcon
        font.pixelSize: Root.Theme.iconFontSize
        font.family: Root.Theme.fontFamily
        color: iconColor

        Behavior on color {
            ColorAnimation { duration: Root.Theme.durationFast }
        }
    }
}
