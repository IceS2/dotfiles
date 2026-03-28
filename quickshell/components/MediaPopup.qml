import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import ".." as Root

Root.ServicePopup {
    id: mediaPopup

    service: Root.Media
    layerNamespace: "quickshell-media"
    panelWidth: Root.Theme.mediaPopupWidth
    showBorder: false

    // ─── Keyboard Shortcuts ───
    Shortcut { sequence: "Space"; onActivated: Root.Media.togglePlay() }
    Shortcut { sequence: "Left"; onActivated: Root.Media.seek(Math.max(0, Root.Media.position - 5)) }
    Shortcut { sequence: "Right"; onActivated: Root.Media.seek(Math.min(Root.Media.length, Root.Media.position + 5)) }
    Shortcut { sequence: "N"; onActivated: Root.Media.next() }
    Shortcut { sequence: "P"; onActivated: Root.Media.smartPrevious() }
    Shortcut { sequence: "S"; onActivated: Root.Media.toggleShuffle() }
    Shortcut { sequence: "R"; onActivated: Root.Media.cycleLoop() }

    // Drive Cava active state from popup visibility
    Binding {
        target: Root.Cava
        property: "active"
        value: Root.Media.popupVisible && Root.Media.hasPlayer
    }

    // ─── Blurred Album Art Background ───
    // MultiEffect forces texture updates via ShaderEffectSource even with visible:false
    Item {
        id: bgBlurContainer
        x: -Root.Theme.paddingMedium
        y: 0
        width: mainColumn.width + Root.Theme.paddingMedium * 2
        height: mainColumn.height
        z: -1

        Image {
            id: bgSource
            anchors.fill: parent
            source: Root.Media.artUrl
            sourceSize: Qt.size(64, 64)
            fillMode: Image.PreserveAspectCrop
            smooth: true
            visible: false
        }

        MultiEffect {
            source: bgSource
            anchors.fill: bgSource
            blurEnabled: true
            blur: 1.0
            blurMax: 64
            maskEnabled: true
            maskSource: bgMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 0.5
            opacity: 0.3
        }

        Item {
            id: bgMask
            width: bgBlurContainer.width
            height: bgBlurContainer.height
            layer.enabled: true
            layer.smooth: true
            visible: false

            Rectangle {
                anchors.fill: parent
                radius: Root.Theme.borderRadiusLarge
                color: "white"
                antialiasing: true
            }
        }
    }

    ColumnLayout {
        id: mainColumn
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Root.Theme.spacingMedium

        // ─── Album Art + Equalizer Bars ───
        RowLayout {
            Layout.fillWidth: true
            spacing: Root.Theme.spacingMedium

            // Square album art with rounded corners
            Item {
                Layout.preferredWidth: Root.Theme.mediaArtSize
                Layout.preferredHeight: Root.Theme.mediaArtSize

                Rectangle {
                    id: artBg
                    anchors.fill: parent
                    radius: Root.Theme.borderRadiusLarge
                    color: Root.Theme.surfaceContainer

                    Text {
                        anchors.centerIn: parent
                        text: "󰎈"
                        font.pixelSize: 36
                        font.family: Root.Theme.fontFamily
                        color: Root.Theme.outline
                        visible: artSource.status !== Image.Ready
                    }
                }

                Image {
                    id: artSource
                    anchors.fill: parent
                    source: Root.Media.artUrl
                    sourceSize: Qt.size(Root.Theme.mediaArtSize, Root.Theme.mediaArtSize)
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    visible: false
                    asynchronous: true
                }

                MultiEffect {
                    anchors.fill: parent
                    source: artSource
                    maskEnabled: true
                    maskSource: artMask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 0.5

                    // Crossfade on track change
                    opacity: artSource.status === Image.Ready ? 1.0 : 0.0
                    Behavior on opacity {
                        NumberAnimation { duration: Root.Theme.durationExpressiveEffects; easing.type: Easing.InOutQuad }
                    }
                }

                Item {
                    id: artMask
                    width: Root.Theme.mediaArtSize
                    height: Root.Theme.mediaArtSize
                    layer.enabled: true
                    layer.smooth: true
                    visible: false

                    Rectangle {
                        anchors.fill: parent
                        radius: Root.Theme.borderRadiusLarge
                        color: "white"
                        antialiasing: true
                    }
                }

                // Click to raise player window
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Root.Media.raisePlayer()
                }
            }

            // Vertical equalizer bars
            Item {
                id: barsContainer
                Layout.fillWidth: true
                Layout.preferredHeight: 100

                Repeater {
                    model: 32

                    Rectangle {
                        required property int index
                        readonly property real amplitude: index < Root.Cava.smoothBars.length
                            ? Root.Cava.smoothBars[index] : 0.0

                        width: 3
                        radius: 1.5
                        height: Math.max(2, amplitude * barsContainer.height * 0.9)
                        color: Root.Theme.primary
                        opacity: amplitude > 0.01 ? (0.4 + 0.6 * amplitude) : 0.15
                        antialiasing: true

                        x: index * (barsContainer.width / 32) + (barsContainer.width / 32 - width) / 2
                        y: barsContainer.height - height

                        Behavior on height {
                            NumberAnimation { duration: Root.Theme.durationInstant; easing.type: Easing.OutQuad }
                        }
                        Behavior on opacity {
                            NumberAnimation { duration: 80 }
                        }
                    }
                }
            }
        }

        // ─── Track Info (centered) ───
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Root.Theme.spacingTiny

            Text {
                text: Root.Media.title || "No media"
                font.pixelSize: Root.Theme.fontSizeLarge
                font.family: Root.Theme.fontFamily
                font.weight: Font.Bold
                color: Root.Media.hasPlayer ? Root.Theme.on.surface : Root.Theme.outline
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            Text {
                text: Root.Media.artist
                font.pixelSize: Root.Theme.fontSizeNormal
                font.family: Root.Theme.fontFamily
                color: Root.Theme.on.surfaceVariant
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                visible: text !== ""
            }

            Text {
                text: Root.Media.album
                font.pixelSize: Root.Theme.fontSizeSmall
                font.family: Root.Theme.fontFamily
                color: Root.Theme.outline
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                visible: text !== ""
            }
        }

        // ─── Transport Controls (5 buttons) ───
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Root.Theme.spacingMedium

            // Shuffle
            Root.IconButton {
                icon: Root.Media.shuffleIcon
                size: 32
                iconSize: 16
                iconColor: Root.Media.shuffle ? Root.Theme.primary : Root.Theme.outline
                opacity: Root.Media.shuffleSupported ? 1.0 : 0.3
                onClicked: Root.Media.toggleShuffle()
            }

            // Previous (smart)
            Root.IconButton {
                icon: "󰒮"
                size: 36
                iconColor: Root.Media.activePlayer && Root.Media.activePlayer.canGoPrevious
                    ? Root.Theme.on.surface : Root.Theme.outline
                opacity: Root.Media.activePlayer && Root.Media.activePlayer.canGoPrevious ? 1.0 : 0.3
                onClicked: Root.Media.smartPrevious()
            }

            // Play/Pause (morphing)
            Item {
                id: playPauseContainer
                width: playPauseBg.width
                height: playPauseBg.height
                opacity: Root.Media.hasPlayer ? 1.0 : 0.3

                Rectangle {
                    id: playPauseBg
                    width: playPauseMouse.containsMouse ? 48 : 44
                    height: width
                    radius: width / 2
                    color: playPauseMouse.containsMouse ? Root.Theme.primary : Root.Theme.surfaceContainer
                    anchors.centerIn: parent
                    scale: playPauseMouse.pressed ? 0.9 : 1.0

                    Behavior on width {
                        NumberAnimation { duration: Root.Theme.durationExpressiveEffects; easing.type: Easing.OutBack }
                    }
                    Behavior on color { Root.CAnim {} }
                    Behavior on scale {
                        NumberAnimation { duration: Root.Theme.durationFast; easing.type: Easing.OutQuad }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: Root.Media.playIcon
                        font.pixelSize: 24
                        font.family: Root.Theme.fontFamily
                        color: playPauseMouse.containsMouse ? Root.Theme.surface : Root.Theme.primary
                        Behavior on color { Root.CAnim {} }
                    }

                    MouseArea {
                        id: playPauseMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Root.Media.togglePlay()
                    }
                }
            }

            // Next
            Root.IconButton {
                icon: "󰒭"
                size: 36
                iconColor: Root.Media.activePlayer && Root.Media.activePlayer.canGoNext
                    ? Root.Theme.on.surface : Root.Theme.outline
                opacity: Root.Media.activePlayer && Root.Media.activePlayer.canGoNext ? 1.0 : 0.3
                onClicked: Root.Media.next()
            }

            // Repeat
            Root.IconButton {
                icon: Root.Media.loopIcon
                size: 32
                iconSize: 16
                iconColor: Root.Media.loopActive ? Root.Theme.primary : Root.Theme.outline
                opacity: Root.Media.loopSupported ? 1.0 : 0.3
                onClicked: Root.Media.cycleLoop()
            }
        }

        // ─── Wave Seek Bar ───
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Root.Theme.spacingTiny
            visible: Root.Media.hasPlayer && Root.Media.length > 0

            Item {
                id: seekContainer
                Layout.fillWidth: true
                Layout.preferredHeight: 16

                property bool isDragging: false
                property real dragProgress: 0
                readonly property real displayProgress: isDragging ? dragProgress : Root.Media.progress

                // Wave phase animation
                property real wavePhase: 0
                Timer {
                    interval: 50
                    repeat: true
                    running: Root.Media.isPlaying && Root.Media.popupVisible
                    onTriggered: seekContainer.wavePhase = (seekContainer.wavePhase + 0.15) % (2 * Math.PI * 100)
                }

                // Track background
                Rectangle {
                    id: trackBg
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 4
                    radius: 2
                    color: Root.Theme.surfaceContainerHigh
                }

                // Full-width wave Canvas — draws solid fill + wavy top edge in one pass
                Canvas {
                    id: waveFill
                    anchors.left: trackBg.left
                    anchors.right: trackBg.right
                    anchors.verticalCenter: trackBg.verticalCenter
                    height: 8

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        var fillW = seekContainer.displayProgress * width
                        if (fillW < 1) return

                        var midY = height / 2
                        var trackH = 4
                        var accentColor = Root.Theme.primary.toString()

                        // Solid fill (covers gray track completely)
                        ctx.fillStyle = accentColor
                        ctx.fillRect(0, midY - trackH / 2, fillW, trackH)

                        // Wavy top edge decoration (only while playing)
                        if (Root.Media.isPlaying) {
                            var amp = 1.5
                            var freq = 0.08
                            ctx.beginPath()
                            ctx.moveTo(0, midY - trackH / 2)
                            for (var x = 0; x <= fillW; x += 2) {
                                var yOff = Math.sin(x * freq + seekContainer.wavePhase) * amp
                                ctx.lineTo(x, midY - trackH / 2 - 1 + yOff)
                            }
                            ctx.lineTo(fillW, midY - trackH / 2)
                            ctx.closePath()
                            ctx.fill()
                        }
                    }

                    // Repaint on progress or phase change
                    Connections {
                        target: seekContainer
                        function onDisplayProgressChanged() { waveFill.requestPaint() }
                        function onWavePhaseChanged() { waveFill.requestPaint() }
                    }
                }

                // Handle
                Rectangle {
                    width: 12
                    height: 12
                    radius: 6
                    color: Root.Theme.primary
                    visible: seekArea.containsMouse || seekContainer.isDragging
                    x: seekContainer.displayProgress * trackBg.width - 6
                    anchors.verticalCenter: trackBg.verticalCenter
                }

                MouseArea {
                    id: seekArea
                    anchors.fill: parent
                    hoverEnabled: true

                    onPressed: function(mouse) {
                        seekContainer.isDragging = true
                        seekContainer.dragProgress = Math.max(0, Math.min(1, mouse.x / trackBg.width))
                    }

                    onPositionChanged: function(mouse) {
                        if (seekContainer.isDragging)
                            seekContainer.dragProgress = Math.max(0, Math.min(1, mouse.x / trackBg.width))
                    }

                    onReleased: {
                        if (seekContainer.isDragging) {
                            Root.Media.seek(seekContainer.dragProgress * Root.Media.length)
                            seekContainer.isDragging = false
                        }
                    }
                }
            }

            // Time labels
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: Root.Media.formatTime(
                        seekContainer.isDragging
                            ? seekContainer.dragProgress * Root.Media.length
                            : Root.Media.position
                    )
                    font.pixelSize: Root.Theme.fontSizeTiny
                    font.family: Root.Theme.fontFamily
                    color: Root.Theme.outline
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: Root.Media.formatTime(Root.Media.length)
                    font.pixelSize: Root.Theme.fontSizeTiny
                    font.family: Root.Theme.fontFamily
                    color: Root.Theme.outline
                }
            }
        }

        // ─── Player Selector Drawer ───
        Item {
            id: playerDrawer
            Layout.fillWidth: true
            Layout.preferredHeight: drawerContent.height
            visible: Root.Media.players.length > 1

            property bool open: false

            // Close drawer when popup hides
            Connections {
                target: Root.Media
                function onPopupVisibleChanged() {
                    if (!Root.Media.popupVisible) playerDrawer.open = false
                }
            }

            Column {
                id: drawerContent
                width: parent.width

                // Header — current player + chevron
                Rectangle {
                    width: drawerContent.width
                    height: 32
                    radius: Root.Theme.borderRadiusSmall
                    color: headerMouse.containsMouse ? Root.Theme.surfaceContainer : "transparent"

                    Behavior on color { Root.CAnim {} }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Root.Theme.paddingSmall
                        anchors.rightMargin: Root.Theme.paddingSmall

                        Text {
                            text: Root.Media.playerName
                            font.pixelSize: Root.Theme.fontSizeSmall
                            font.family: Root.Theme.fontFamily
                            color: Root.Theme.on.surfaceVariant
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "󰅂"
                            font.pixelSize: Root.Theme.fontSizeSmall
                            font.family: Root.Theme.fontFamily
                            color: Root.Theme.outline
                            rotation: playerDrawer.open ? 90 : 0

                            Behavior on rotation {
                                NumberAnimation { duration: Root.Theme.durationExpressiveEffects; easing.type: Easing.OutCubic }
                            }
                        }
                    }

                    MouseArea {
                        id: headerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: playerDrawer.open = !playerDrawer.open
                    }
                }

                // Drawer body (animated height)
                Item {
                    width: drawerContent.width
                    height: playerDrawer.open ? drawerEntries.height : 0
                    clip: true

                    Behavior on height {
                        NumberAnimation { duration: Root.Theme.durationExpressiveEffects; easing.type: Easing.OutCubic }
                    }

                    Column {
                        id: drawerEntries
                        width: parent.width
                        topPadding: Root.Theme.spacingTiny

                        Repeater {
                            model: Root.Media.players

                            Rectangle {
                                required property var modelData
                                required property int index

                                width: drawerEntries.width
                                height: 36
                                radius: Root.Theme.borderRadiusSmall
                                color: entryMouse.containsMouse ? Root.Theme.surfaceContainer : "transparent"

                                Behavior on color { Root.CAnim {} }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Root.Theme.paddingSmall
                                    anchors.rightMargin: Root.Theme.paddingSmall
                                    spacing: Root.Theme.spacingSmall

                                    // Active indicator dot
                                    Rectangle {
                                        width: 6
                                        height: 6
                                        radius: 3
                                        color: Root.Theme.primary
                                        visible: modelData === Root.Media.activePlayer
                                    }

                                    Text {
                                        text: modelData.identity
                                        font.pixelSize: Root.Theme.fontSizeSmall
                                        font.family: Root.Theme.fontFamily
                                        color: modelData === Root.Media.activePlayer
                                            ? Root.Theme.primary : Root.Theme.on.surfaceVariant
                                        font.weight: modelData === Root.Media.activePlayer
                                            ? Font.DemiBold : Font.Normal
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    // Playing status icon
                                    Text {
                                        text: modelData.isPlaying ? "󰐊" : (modelData.trackTitle ? "󰏤" : "")
                                        font.pixelSize: Root.Theme.fontSizeTiny
                                        font.family: Root.Theme.fontFamily
                                        color: modelData.isPlaying ? Root.Theme.success : Root.Theme.outline
                                        visible: text !== ""
                                    }
                                }

                                MouseArea {
                                    id: entryMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Root.Media.setPlayer(modelData)
                                        playerDrawer.open = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
