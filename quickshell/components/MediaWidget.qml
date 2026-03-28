import QtQuick
import QtQuick.Layouts
import ".." as Root

Root.BarWidget {
    id: mediaWidget
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    visible: Root.Media.hasPlayer
    anchorTarget: Root.Media
    tintColor: Root.Theme.maroon

    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            updateAnchor()
            Root.Media.togglePopup()
        } else if (mouse.button === Qt.RightButton) {
            Root.Media.togglePlay()
        }
    }

    onWheel: wheel => {
        if (wheel.angleDelta.y > 0) Root.Media.next()
        else Root.Media.previous()
    }

    Text {
        text: Root.Media.playIcon
        font.pixelSize: Root.Theme.iconFontSize
        font.family: Root.Theme.fontFamily
        color: Root.Media.popupVisible ? Root.Theme.maroon
            : Root.Media.isPlaying ? Root.Theme.maroon
            : Root.Theme.outline

        Behavior on color {
            ColorAnimation { duration: Root.Theme.durationFast }
        }
    }

    // Scrolling text container (fixed width)
    Item {
        id: textContainer
        Layout.preferredWidth: Root.Theme.mediaTextMaxWidth
        Layout.preferredHeight: marqueeText.implicitHeight
        clip: true

        readonly property bool overflows: marqueeText.implicitWidth > width

        function restartMarquee() {
            marqueeAnim.stop()
            if (overflows) {
                marqueeText.x = 0
                marqueeAnim.start()
            } else {
                // Restore centering binding (imperative x=0 breaks it)
                marqueeText.x = Qt.binding(function() {
                    return (textContainer.width - marqueeText.implicitWidth) / 2
                })
            }
        }

        onOverflowsChanged: restartMarquee()

        Text {
            id: marqueeText
            // Center when not scrolling; marquee animation overrides x when scrolling
            x: textContainer.overflows ? 0 : (textContainer.width - implicitWidth) / 2
            text: {
                var parts = []
                if (Root.Media.artist) parts.push(Root.Media.artist)
                if (Root.Media.title) parts.push(Root.Media.title)
                return parts.join(" - ") || "Unknown"
            }
            font.pixelSize: Root.Theme.fontSizeNormal
            font.family: Root.Theme.fontFamily
            font.weight: Root.Theme.fontWeight
            color: Root.Media.isPlaying ? Root.Theme.on.surface : Root.Theme.outline

            onTextChanged: textContainer.restartMarquee()

            Behavior on color {
                ColorAnimation { duration: Root.Theme.durationFast }
            }
        }

        SequentialAnimation {
            id: marqueeAnim
            loops: Animation.Infinite

            PauseAnimation { duration: 2000 }
            NumberAnimation {
                target: marqueeText
                property: "x"
                to: -(marqueeText.implicitWidth - textContainer.width)
                duration: Math.abs(marqueeText.implicitWidth - textContainer.width) * 30
                easing.type: Easing.Linear
            }
            PauseAnimation { duration: 2000 }
            NumberAnimation {
                target: marqueeText
                property: "x"
                to: 0
                duration: Math.abs(marqueeText.implicitWidth - textContainer.width) * 30
                easing.type: Easing.Linear
            }
        }
    }

    // Track progress bar — reparented to widget root on creation
    Item {
        id: progressWrapper
        visible: false
        width: 0; height: 0

        Rectangle {
            id: progressBar
            height: 2
            radius: 1
            color: "transparent"
            clip: true
            visible: Root.Media.hasPlayer && Root.Media.length > 0

            Rectangle {
                width: parent.width * Root.Media.progress
                height: parent.height
                radius: parent.radius
                color: Root.Theme.maroon
                opacity: Root.Media.isPlaying ? 0.7 : 0.3

                Behavior on width {
                    NumberAnimation { duration: 1000; easing.type: Easing.Linear }
                }
                Behavior on opacity {
                    NumberAnimation { duration: Root.Theme.durationFast }
                }
            }
        }

        Component.onCompleted: {
            progressBar.parent = mediaWidget
            progressBar.width = Qt.binding(function() { return mediaWidget.width })
            progressBar.y = Qt.binding(function() { return mediaWidget.height - progressBar.height })
        }
    }
}
