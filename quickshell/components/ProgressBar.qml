import QtQuick
import ".." as Root

/**
 * ProgressBar — reusable track + fill + optional handle + drag component.
 *
 * Non-interactive mode (default): simple track with animated fill.
 * Interactive mode: adds a drag handle and emits valueChanged on user input.
 *
 * Usage:
 *   Root.ProgressBar {
 *       Layout.fillWidth: true
 *       value: Root.Audio.volumePercent / 100
 *       fillColor: Root.Audio.muted ? Root.Theme.error : Root.Theme.primary
 *       interactive: true
 *       onAdjusted: newValue => Root.Audio.setVolume(Math.round(newValue * 100))
 *   }
 */
Item {
    id: bar

    property real value: 0              // 0.0–1.0
    property color fillColor: Root.Theme.primary
    property color trackColor: Root.Theme.surfaceContainerHigh
    property int trackHeight: 4
    property bool interactive: false

    signal adjusted(real newValue)

    implicitHeight: interactive ? 24 : trackHeight

    // Track background
    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: bar.trackHeight
        radius: height / 2
        color: bar.trackColor

        // Fill
        Rectangle {
            width: Math.max(0, Math.min(1, bar.value)) * parent.width
            height: parent.height
            radius: parent.radius
            color: bar.fillColor

            Behavior on width {
                NumberAnimation {
                    duration: bar.interactive ? Root.Theme.durationInstant : Root.Theme.durationSlow
                    easing.type: bar.interactive ? Easing.Linear : Easing.OutCubic
                }
            }
            Behavior on color { Root.CAnim {} }
        }
    }

    // Handle (interactive only)
    Rectangle {
        id: handle
        width: 14
        height: 14
        radius: 7
        color: bar.fillColor
        visible: bar.interactive && (sliderArea.containsMouse || sliderArea.pressed)
        x: Math.max(0, Math.min(1, bar.value)) * track.width - 7
        anchors.verticalCenter: track.verticalCenter
    }

    // Drag area (interactive only)
    MouseArea {
        id: sliderArea
        anchors.fill: parent
        enabled: bar.interactive
        hoverEnabled: bar.interactive

        function _updateValue(mouseX) {
            var v = Math.max(0, Math.min(1, mouseX / track.width))
            bar.adjusted(v)
        }

        onPressed: function(mouse) { _updateValue(mouse.x) }
        onPositionChanged: function(mouse) {
            if (pressed) _updateValue(mouse.x)
        }
    }
}
