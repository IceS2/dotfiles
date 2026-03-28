import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".." as Root

Scope {
    // Drive HyprlandData polling from Overview visibility
    // (singletons can't reference sibling singletons directly)
    Binding {
        target: Root.HyprlandData
        property: "polling"
        value: Root.Overview.popupVisible
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panel.screen)
            property bool monitorIsFocused: Hyprland.focusedMonitor?.id === monitor?.id

            readonly property var monitorWorkspaceIds: Root.Workspaces.workspaceIdsForMonitor(monitor?.name)

            screen: modelData
            visible: Root.Overview.popupVisible
            color: "transparent"

            WlrLayershell.namespace: "quickshell-overview"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: monitorIsFocused ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            mask: Region {
                item: Root.Overview.popupVisible ? keyHandler : null
            }

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Item {
                id: keyHandler
                anchors.fill: parent
                visible: Root.Overview.popupVisible
                focus: Root.Overview.popupVisible

                // Click-outside-to-close
                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: Root.Overview.hidePopup()
                }

                Keys.onPressed: event => {
                    // Close: Escape or Enter
                    if (event.key === Qt.Key_Escape || event.key === Qt.Key_Return) {
                        Root.Overview.hidePopup();
                        event.accepted = true;
                        return;
                    }

                    // Monitor workspace lists — derived from focused monitor dynamically
                    const focusedName = Hyprland.focusedMonitor?.name ?? "";
                    const focusedIds = Root.Workspaces.workspaceIdsForMonitor(focusedName);
                    const monitors = Hyprland.monitors.values;
                    const otherMonitor = monitors.find(m => m.name !== focusedName);
                    const otherIds = Root.Workspaces.workspaceIdsForMonitor(otherMonitor?.name ?? "");
                    const currentId = Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1;
                    const wsIds = focusedIds;
                    const currentIdx = wsIds.indexOf(currentId);
                    if (currentIdx === -1) return;

                    let targetId = null;

                    // Left/Right (h/l): move within current monitor's row
                    if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                        const newIdx = (currentIdx - 1 + wsIds.length) % wsIds.length;
                        targetId = wsIds[newIdx];
                    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                        const newIdx = (currentIdx + 1) % wsIds.length;
                        targetId = wsIds[newIdx];
                    }

                    // Up/Down (k/j) or Tab: jump to other monitor (same position)
                    else if (event.key === Qt.Key_Up || event.key === Qt.Key_K ||
                             event.key === Qt.Key_Down || event.key === Qt.Key_J ||
                             event.key === Qt.Key_Tab) {
                        const otherIdx = Math.min(currentIdx, otherIds.length - 1);
                        targetId = otherIds[otherIdx];
                    }

                    // Number keys: 1-5 jump to position in current monitor's list
                    else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                        const position = event.key - Qt.Key_0;
                        if (position <= wsIds.length) {
                            targetId = wsIds[position - 1];
                        }
                    }

                    if (targetId !== null) {
                        Hyprland.dispatch("workspace " + targetId);
                        event.accepted = true;
                    }
                }
            }

            ColumnLayout {
                visible: Root.Overview.popupVisible
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: 100
                }

                Root.OverviewWidget {
                    panelWindow: panel
                }
            }
        }
    }
}
