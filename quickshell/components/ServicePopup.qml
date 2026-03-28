import QtQuick
import Quickshell
import ".." as Root

/**
 * ServicePopup — auto-wired PopupPanel for services extending PopupServiceBase.
 *
 * Eliminates ~13 lines of boilerplate per popup by binding showing, screen,
 * panelX (centered + clamped), contentPadding, and onCloseRequested from
 * a single `service` property.
 *
 * Usage:
 *   Root.ServicePopup {
 *       service: Root.Audio
 *       layerNamespace: "quickshell-audio"
 *       panelWidth: Root.Theme.popupWidthWide
 *   }
 */
Root.PopupPanel {
    required property var service

    showing: service.popupVisible
    screen: service.activeScreen ?? Quickshell.screens[0]
    growDirection: "down"
    panelX: Math.min(
        Math.max(service.anchorX - panelWidth / 2, Root.Theme.gapOuter),
        width - panelWidth - Root.Theme.gapOuter
    )
    contentPadding: Root.Theme.paddingMedium

    onCloseRequested: service.hidePopup()
}
