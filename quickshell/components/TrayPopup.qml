import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import ".." as Root

Root.PopupPanel {
    id: trayPopupWindow

    showing: Root.Tray.popupVisible
    screen: Root.Tray.activeScreen ?? Quickshell.screens[0]
    layerNamespace: "quickshell-tray-popup"
    growDirection: "down"
    panelX: Math.min(
        Math.max(Root.Tray.popupAnchorX - panelWidth / 2, Root.Theme.gapOuter),
        width - panelWidth - Root.Theme.gapOuter
    )
    // Auto-size: 5 icons per row, each trayIconSize + spacing
    panelWidth: 5 * Root.Theme.trayIconSize + 4 * Root.Theme.spacingSmall + Root.Theme.paddingSmall * 2
    contentPadding: Root.Theme.paddingSmall

    onCloseRequested: Root.Tray.hidePopup()

    // ─── Icon grid ───
    Flow {
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Root.Theme.spacingSmall

        Repeater {
            model: SystemTray.items.values

            Item {
                id: trayItem
                required property var modelData

                width: Root.Theme.trayIconSize
                height: Root.Theme.trayIconSize
                visible: modelData.status !== Status.Passive

                Rectangle {
                    anchors.fill: parent
                    radius: Root.Theme.borderRadiusSmall
                    color: itemMouse.containsMouse ? Root.Theme.surfaceContainer : "transparent"
                    Behavior on color { Root.CAnim {} }
                }

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 20
                    source: trayItem.modelData.icon
                }

                // NeedsAttention dot
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 2
                    anchors.rightMargin: 2
                    width: 6
                    height: 6
                    radius: 3
                    color: Root.Theme.error
                    visible: trayItem.modelData.status === Status.NeedsAttention
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                    onClicked: mouse => {
                        var screenX = trayItem.mapToGlobal(trayItem.width / 2, 0).x
                        switch (mouse.button) {
                        case Qt.LeftButton:
                            if (trayItem.modelData.onlyMenu) {
                                Root.Tray.showMenu(trayItem.modelData, screenX)
                            } else {
                                trayItem.modelData.activate()
                            }
                            break
                        case Qt.RightButton:
                            Root.Tray.showMenu(trayItem.modelData, screenX)
                            break
                        case Qt.MiddleButton:
                            trayItem.modelData.secondaryActivate()
                            break
                        }
                    }

                    onWheel: wheel => {
                        if (wheel.angleDelta.y !== 0)
                            trayItem.modelData.scroll(wheel.angleDelta.y / 120, false)
                        if (wheel.angleDelta.x !== 0)
                            trayItem.modelData.scroll(wheel.angleDelta.x / 120, true)
                    }
                }

                scale: itemMouse.containsMouse ? Root.Theme.hoverScale : 1.0

                Behavior on scale {
                    ScaleAnimator {
                        duration: Root.Theme.durationFast
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}
