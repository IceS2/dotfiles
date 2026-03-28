import QtQuick
import QtQuick.Layouts
import ".." as Root

Rectangle {
    id: card

    required property var notif
    property bool showActions: false
    property bool isPopup: false

    // ─── Hover state (exposed for popup timer binding) ───
    readonly property bool hovered: cardMouse.containsMouse

    // ─── Appearance ───
    color: cardMouse.containsMouse ? Root.ColorUtils.applyAlpha(Root.Theme.surface, 0.45) : Root.Theme.surfaceGlass
    radius: Root.Theme.windowRounding

    // ─── Hover depth: raise above siblings for border visibility ───
    z: cardMouse.containsMouse ? 1 : 0
    border.color: {
        if (cardMouse.containsMouse) return Root.Theme.primary  // Hover — bright purple feedback
        switch (notif.urgency) {
            case 0: return Root.Theme.outline   // Low — subtle
            case 2: return Root.Theme.error        // Critical — red
            default: return Root.Theme.surfaceContainer  // Normal — matches launcher border
        }
    }
    border.width: Root.Theme.borderWidthNormal

    Behavior on color {
        ColorAnimation { duration: Root.Theme.durationFast }
    }
    Behavior on border.color {
        ColorAnimation { duration: Root.Theme.durationFast }
    }

    implicitWidth: parent?.width ?? 360
    implicitHeight: contentLayout.implicitHeight + Root.Theme.paddingMedium * 2

    // ─── Card-level hover + click actions ───
    // MouseArea wraps content (Caelestia pattern): parent MouseArea reliably
    // gets hover even when cursor is over child MouseAreas (dismiss button).
    // Left = default action, Right = dismiss, Middle = clear all.
    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            if (event.button === Qt.RightButton) {
                Root.Notifications.dismiss(card.notif)
            } else if (event.button === Qt.MiddleButton) {
                Root.Notifications.clearAll()
            } else if (event.button === Qt.LeftButton) {
                // Invoke "default" action if present (opens the app)
                if (card.notif.notification) {
                    const actions = card.notif.notification.actions
                    for (let i = 0; i < actions.length; i++) {
                        if (actions[i].identifier === "default") {
                            actions[i].invoke()
                            Root.Notifications.dismiss(card.notif)
                            return
                        }
                    }
                }
            }
        }

        RowLayout {
            id: contentLayout
            anchors.fill: parent
            anchors.margins: Root.Theme.paddingMedium
            scale: cardMouse.containsMouse ? 1.02 : 1.0
            Behavior on scale {
                NumberAnimation { duration: Root.Theme.durationFast; easing.type: Easing.OutCubic }
            }
            spacing: Root.Theme.spacingSmall

            // ─── App Icon ───
            Item {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                Layout.alignment: Qt.AlignTop

                Root.Icon {
                    anchors.fill: parent
                    icon: card.notif.appIcon
                    size: 24
                    visible: card.notif.appIcon !== ""
                }

                // Fallback icon
                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: Root.Theme.surfaceContainer
                    visible: card.notif.appIcon === ""

                    Text {
                        anchors.centerIn: parent
                        text: "󰂚"
                        font.pixelSize: 14
                        font.family: Root.Theme.fontFamily
                        color: Root.Theme.primary
                    }
                }
            }

            // ─── Text Content ───
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                // Header: app name + timestamp
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Root.Theme.spacingSmall

                    Text {
                        text: card.notif.appName
                        font.pixelSize: Root.Theme.fontSizeCaption
                        font.family: Root.Theme.fontFamily
                        font.weight: Root.Theme.fontWeight
                        color: Root.Theme.outline
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: card.notif.timeStr
                        font.pixelSize: Root.Theme.fontSizeCaption
                        font.family: Root.Theme.fontFamily
                        color: Root.Theme.outline
                    }
                }

                // Summary (title)
                Text {
                    Layout.fillWidth: true
                    text: card.notif.summary
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    font.weight: Font.Bold
                    color: Root.Theme.on.surface
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.WordWrap
                }

                // Body
                Text {
                    Layout.fillWidth: true
                    text: "<style>a { color: " + Root.Theme.primary + "; }</style>" + card.notif.body
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    color: Root.Theme.on.surfaceVariant
                    elide: Text.ElideRight
                    maximumLineCount: card.showActions ? 6 : 3
                    wrapMode: Text.WordWrap
                    textFormat: Text.RichText
                    visible: card.notif.body !== ""
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }

                // Progress bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 4
                    radius: 2
                    color: Root.Theme.surfaceContainer
                    visible: card.notif.progress >= 0

                    Rectangle {
                        width: parent.width * Math.max(0, card.notif.progress)
                        height: parent.height
                        radius: 2
                        color: card.notif.progress >= 1.0 ? Root.Theme.success : Root.Theme.primary

                        Behavior on width {
                            NumberAnimation {
                                duration: Root.Theme.durationNormal
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on color { Root.CAnim {} }
                    }
                }

                // Action buttons (use index-based access to preserve C++ types)
                Flow {
                    id: actionsFlow
                    Layout.fillWidth: true
                    spacing: Root.Theme.spacingSmall
                    visible: card.notif.notification && card.notif.notification.actions.length > 0

                    Repeater {
                        model: card.notif.notification ? card.notif.notification.actions.length : 0

                        Rectangle {
                            required property int index
                            readonly property var action: card.notif.notification?.actions[index] ?? null
                            readonly property string actionText: action?.text ?? ""
                            readonly property string actionId: action?.identifier ?? ""
                            visible: actionText.trim() !== "" && actionId !== "default"
                            width: visible ? actionLabel.implicitWidth + Root.Theme.paddingMedium * 2 : 0
                            height: visible ? 24 : 0
                            radius: 12
                            color: actionMouse.containsMouse ? Root.Theme.surfaceContainerHigh : Root.Theme.surfaceContainer
                            border.color: actionMouse.containsMouse ? Root.Theme.primary : Root.Theme.surfaceContainerHigh
                            border.width: 1

                            Behavior on color { Root.CAnim {} }
                            Behavior on border.color { Root.CAnim {} }

                            Text {
                                id: actionLabel
                                anchors.centerIn: parent
                                text: parent.actionText
                                font.pixelSize: Root.Theme.fontSizeCaption
                                font.family: Root.Theme.fontFamily
                                font.weight: Root.Theme.fontWeight
                                color: actionMouse.containsMouse ? Root.Theme.primary : Root.Theme.on.surfaceVariant
                            }

                            MouseArea {
                                id: actionMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Root.Notifications.invokeAction(card.notif, index)
                            }
                        }
                    }
                }
            }

            // ─── Notification Image ───
            Rectangle {
                readonly property int imgSize: card.isPopup ? 48 : 64
                Layout.preferredWidth: imgSize
                Layout.preferredHeight: imgSize
                Layout.alignment: Qt.AlignVCenter
                radius: Root.Theme.borderRadiusSmall
                color: Root.Theme.surfaceContainer
                visible: card.notif.image !== ""
                clip: true

                Image {
                    id: notifImage
                    anchors.fill: parent
                    source: card.notif.image
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    mipmap: true
                    // Hide parent container if image fails to load (stale handles after restart)
                    onStatusChanged: {
                        if (status === Image.Error) parent.visible = false;
                    }
                }
            }

            // ─── Dismiss Button ───
            Rectangle {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                Layout.alignment: Qt.AlignTop
                radius: Root.Theme.borderRadiusSmall
                color: dismissHover.containsMouse ? Root.Theme.error : "transparent"
                border.color: dismissHover.containsMouse ? Root.Theme.error : Root.Theme.surfaceContainerHigh
                border.width: 1
                opacity: dismissHover.containsMouse ? 1.0 : 0.6

                Behavior on color { Root.CAnim {} }
                Behavior on opacity {
                    NumberAnimation { duration: Root.Theme.durationFast }
                }

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    font.pixelSize: 14
                    font.family: Root.Theme.fontFamily
                    font.weight: Font.Bold
                    color: Root.Theme.on.surface
                }

                MouseArea {
                    id: dismissHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Root.Notifications.dismiss(card.notif)
                }
            }
        }
    }
}
