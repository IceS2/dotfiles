import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".." as Root

Item {
    id: root
    required property var panelWindow
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)

    // Overview configuration
    readonly property int overviewRows: 1
    readonly property int overviewColumns: 5
    readonly property real overviewScale: 0.16

    readonly property var monitorWorkspaceIds: Root.Workspaces.workspaceIdsForMonitor(monitor?.name)

    property var windowByAddress: Root.HyprlandData.windowByAddress
    property var monitorData: Root.HyprlandData.monitors.find(m => m.id === root.monitor?.id)
    property real scale: overviewScale
    property color activeBorderColor: Root.Theme.primary

    // Monitor transform: odd transforms (90°, 270°) swap width/height
    readonly property bool isRotated: (monitorData?.transform ?? 0) % 2 === 1

    property real workspaceImplicitWidth: {
        var w = isRotated ? monitor.height : monitor.width
        return (w / monitor.scale - (monitorData?.reserved?.[0] ?? 0) - (monitorData?.reserved?.[2] ?? 0)) * root.scale
    }
    property real workspaceImplicitHeight: {
        var h = isRotated ? monitor.width : monitor.height
        return (h / monitor.scale - (monitorData?.reserved?.[1] ?? 0) - (monitorData?.reserved?.[3] ?? 0)) * root.scale
    }

    property real workspaceNumberSize: 250 * monitor.scale
    property int workspaceZ: 0
    property int windowZ: 1
    property int windowDraggingZ: 99999
    property real workspaceSpacing: 5

    property int draggingFromWorkspace: -1
    property int draggingTargetWorkspace: -1

    implicitWidth: overviewBackground.implicitWidth
    implicitHeight: overviewBackground.implicitHeight

    Rectangle {
        id: overviewBackground
        property real padding: 10
        anchors.fill: parent

        implicitWidth: workspaceColumnLayout.implicitWidth + padding * 2
        implicitHeight: workspaceColumnLayout.implicitHeight + padding * 2
        radius: Root.Theme.borderRadiusLarge * root.scale + padding
        color: Root.Theme.surface
        border.width: 1
        border.color: Root.Theme.surfaceContainer

        ColumnLayout {
            id: workspaceColumnLayout
            z: root.workspaceZ
            anchors.centerIn: parent
            spacing: root.workspaceSpacing

            Repeater {
                model: root.overviewRows
                delegate: RowLayout {
                    id: row
                    required property int index
                    property int rowIndex: index
                    spacing: root.workspaceSpacing

                    Repeater {
                        model: root.overviewColumns
                        Rectangle {
                            id: workspace
                            required property int index
                            property int colIndex: index
                            property int workspaceValue: root.monitorWorkspaceIds[row.rowIndex * root.overviewColumns + colIndex] ?? -1
                            property color defaultWorkspaceColor: Root.Theme.surfaceContainer
                            property color hoveredWorkspaceColor: Root.ColorUtils.mix(defaultWorkspaceColor, Root.Theme.surfaceContainerHigh, 0.1)
                            property color hoveredBorderColor: Root.Theme.surfaceContainerHighest
                            property bool hoveredWhileDragging: false

                            implicitWidth: root.workspaceImplicitWidth
                            implicitHeight: root.workspaceImplicitHeight
                            color: hoveredWhileDragging ? hoveredWorkspaceColor : defaultWorkspaceColor
                            radius: Root.Theme.borderRadiusLarge * root.scale
                            border.width: 2
                            border.color: hoveredWhileDragging ? hoveredBorderColor : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: workspace.workspaceValue
                                font {
                                    pixelSize: root.workspaceNumberSize * root.scale
                                    weight: Font.DemiBold
                                    family: Root.Theme.fontFamily
                                }
                                color: Root.ColorUtils.transparentize(Root.Theme.on.surfaceVariant, 0.8)
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                onClicked: {
                                    if (root.draggingTargetWorkspace === -1) {
                                        Root.Overview.hidePopup()
                                        Hyprland.dispatch("hl.dsp.focus({ workspace = " + workspace.workspaceValue + " })")
                                    }
                                }
                            }

                            DropArea {
                                anchors.fill: parent
                                onEntered: {
                                    root.draggingTargetWorkspace = workspace.workspaceValue
                                    if (root.draggingFromWorkspace === root.draggingTargetWorkspace) return;
                                    workspace.hoveredWhileDragging = true
                                }
                                onExited: {
                                    workspace.hoveredWhileDragging = false
                                    if (root.draggingTargetWorkspace === workspace.workspaceValue)
                                        root.draggingTargetWorkspace = -1
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: windowSpace
            anchors.centerIn: parent
            width: workspaceColumnLayout.implicitWidth
            height: workspaceColumnLayout.implicitHeight

            // Window repeater — sorted by stacking order
            Repeater {
                model: ScriptModel {
                    values: {
                        return ToplevelManager.toplevels.values.filter(function(toplevel) {
                            var address = "0x" + toplevel.HyprlandToplevel.address;
                            var win = root.windowByAddress[address];
                            return root.monitorWorkspaceIds.indexOf(win?.workspace?.id) !== -1;
                        }).sort(function(a, b) {
                            var addrA = "0x" + a.HyprlandToplevel.address;
                            var addrB = "0x" + b.HyprlandToplevel.address;
                            var winA = root.windowByAddress[addrA];
                            var winB = root.windowByAddress[addrB];

                            // Pinned > floating > tiled, then by focus history
                            if (winA?.pinned !== winB?.pinned) return winA?.pinned ? 1 : -1;
                            if (winA?.floating !== winB?.floating) return winA?.floating ? 1 : -1;
                            return (winB?.focusHistoryID ?? 0) - (winA?.focusHistoryID ?? 0);
                        });
                    }
                }
                delegate: Root.OverviewWindow {
                    id: window
                    required property var modelData
                    required property int index
                    property int monitorId: windowData?.monitor
                    property var windowMonitor: Root.HyprlandData.monitors.find(m => m.id === monitorId)
                    property string address: "0x" + modelData.HyprlandToplevel.address
                    windowData: root.windowByAddress[address]
                    toplevel: modelData
                    monitorData: windowMonitor

                    // Scale relative to window's source monitor
                    readonly property bool sourceRotated: (windowMonitor?.transform ?? 0) % 2 === 1
                    property real sourceMonitorWidth: {
                        var w = sourceRotated ? (windowMonitor?.height ?? 1920) : (windowMonitor?.width ?? 1920)
                        return w / (windowMonitor?.scale ?? 1) - (windowMonitor?.reserved?.[0] ?? 0) - (windowMonitor?.reserved?.[2] ?? 0)
                    }
                    property real sourceMonitorHeight: {
                        var h = sourceRotated ? (windowMonitor?.width ?? 1080) : (windowMonitor?.height ?? 1080)
                        return h / (windowMonitor?.scale ?? 1) - (windowMonitor?.reserved?.[1] ?? 0) - (windowMonitor?.reserved?.[3] ?? 0)
                    }

                    scale: Math.min(
                        root.workspaceImplicitWidth / sourceMonitorWidth,
                        root.workspaceImplicitHeight / sourceMonitorHeight
                    )

                    availableWorkspaceWidth: root.workspaceImplicitWidth
                    availableWorkspaceHeight: root.workspaceImplicitHeight
                    widgetMonitorId: root.monitor.id

                    property bool atInitPosition: (initX === x && initY === y)
                    property int workspaceIdx: root.monitorWorkspaceIds.indexOf(windowData?.workspace?.id ?? -1)
                    property int workspaceColIndex: workspaceIdx >= 0 ? workspaceIdx % root.overviewColumns : 0
                    property int workspaceRowIndex: workspaceIdx >= 0 ? Math.floor(workspaceIdx / root.overviewColumns) : 0
                    xOffset: (root.workspaceImplicitWidth + root.workspaceSpacing) * workspaceColIndex
                    yOffset: (root.workspaceImplicitHeight + root.workspaceSpacing) * workspaceRowIndex

                    Timer {
                        id: updateWindowPosition
                        interval: 150
                        repeat: false
                        onTriggered: {
                            window.x = Math.round(Math.max((window.windowData?.at[0] - (window.windowMonitor?.x ?? 0) - (window.monitorData?.reserved?.[0] ?? 0)) * root.scale, 0) + window.xOffset)
                            window.y = Math.round(Math.max((window.windowData?.at[1] - (window.windowMonitor?.y ?? 0) - (window.monitorData?.reserved?.[1] ?? 0)) * root.scale, 0) + window.yOffset)
                        }
                    }

                    z: atInitPosition ? (root.windowZ + index) : root.windowDraggingZ
                    Drag.hotSpot.x: targetWindowWidth / 2
                    Drag.hotSpot.y: targetWindowHeight / 2

                    MouseArea {
                        id: dragArea
                        anchors.fill: parent
                        z: 100
                        hoverEnabled: true
                        onEntered: window.hovered = true
                        onExited: window.hovered = false
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        drag.target: parent
                        onPressed: (mouse) => {
                            root.draggingFromWorkspace = window.windowData?.workspace.id
                            window.pressed = true
                            window.Drag.active = true
                            window.Drag.source = window
                            window.Drag.hotSpot.x = mouse.x
                            window.Drag.hotSpot.y = mouse.y
                        }
                        onReleased: {
                            var targetWorkspace = root.draggingTargetWorkspace
                            window.pressed = false
                            window.Drag.active = false
                            root.draggingFromWorkspace = -1
                            if (targetWorkspace !== -1 && targetWorkspace !== window.windowData?.workspace.id) {
                                Hyprland.dispatch("hl.dsp.window.move({ workspace = " + targetWorkspace
                                    + ", silent = true, window = \"address:" + window.windowData?.address + "\" })")
                                updateWindowPosition.restart()
                            } else {
                                window.x = window.initX
                                window.y = window.initY
                            }
                        }
                        onClicked: (event) => {
                            if (!window.windowData) return;

                            if (event.button === Qt.LeftButton) {
                                Root.Overview.hidePopup()
                                Hyprland.dispatch("hl.dsp.focus({ window = \"address:" + window.windowData.address + "\" })")
                                event.accepted = true
                            } else if (event.button === Qt.MiddleButton) {
                                Hyprland.dispatch("hl.dsp.window.close({ window = \"address:" + window.windowData.address + "\" })")
                                event.accepted = true
                            }
                        }

                        ToolTip.visible: dragArea.containsMouse && !window.Drag.active
                        ToolTip.delay: 500
                        ToolTip.text: (window.windowData?.title ?? "Unknown") + "\n[" + (window.windowData?.class ?? "unknown") + "]" + (window.windowData?.xwayland ? " [XWayland]" : "")
                    }
                }
            }

            // Focused workspace indicator (mauve border)
            Rectangle {
                id: focusedWorkspaceIndicator
                property int activeWorkspaceIdx: root.monitorWorkspaceIds.indexOf(root.monitor.activeWorkspace?.id ?? -1)
                property int activeWorkspaceRowIndex: activeWorkspaceIdx >= 0 ? Math.floor(activeWorkspaceIdx / root.overviewColumns) : 0
                property int activeWorkspaceColIndex: activeWorkspaceIdx >= 0 ? activeWorkspaceIdx % root.overviewColumns : 0
                x: (root.workspaceImplicitWidth + root.workspaceSpacing) * activeWorkspaceColIndex
                y: (root.workspaceImplicitHeight + root.workspaceSpacing) * activeWorkspaceRowIndex
                z: root.windowZ
                width: root.workspaceImplicitWidth
                height: root.workspaceImplicitHeight
                color: "transparent"
                radius: Root.Theme.borderRadiusLarge * root.scale
                border.width: 2
                border.color: root.activeBorderColor

                Behavior on x {
                    NumberAnimation {
                        duration: Root.Theme.durationExpressiveEffects
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Root.Theme.curveExpressiveEffects
                    }
                }
                Behavior on y {
                    NumberAnimation {
                        duration: Root.Theme.durationExpressiveEffects
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Root.Theme.curveExpressiveEffects
                    }
                }
            }
        }
    }
}
