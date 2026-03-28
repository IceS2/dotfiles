import QtQuick
import ".." as Root

Item {
    id: workspacesWidget

    required property list<int> workspaceIds

    readonly property int cellSize: Root.Theme.workspaceCellSize
    readonly property int cellSpacing: 6

    implicitWidth: row.implicitWidth
    implicitHeight: cellSize

    // Track active workspace index in the list
    property int activeIndex: {
        for (var i = 0; i < workspaceIds.length; i++) {
            if (Root.Workspaces.isWorkspaceActive(workspaceIds[i]))
                return i
        }
        return -1
    }

    property int _prevActiveIndex: -1

    onActiveIndexChanged: {
        if (activeIndex < 0) return

        var newPos = activeIndex * (cellSize + cellSpacing)

        if (_prevActiveIndex >= 0 && _prevActiveIndex !== activeIndex) {
            var oldPos = _prevActiveIndex * (cellSize + cellSpacing)
            var distance = Math.abs(newPos - oldPos)
            var stretchWidth = distance + cellSize

            wormAnim.stop()

            // Phase 1: Expand — stretch to cover both old and new positions
            xExpand.from = oldPos
            xExpand.to = Math.min(oldPos, newPos)
            wExpand.from = cellSize
            wExpand.to = stretchWidth

            // Phase 2: Contract — shrink to new position
            xContract.from = Math.min(oldPos, newPos)
            xContract.to = newPos
            wContract.from = stretchWidth
            wContract.to = cellSize

            wormAnim.start()
        } else {
            highlight.x = newPos
            highlight.width = cellSize
        }
        _prevActiveIndex = activeIndex
    }

    // ─── Worm Animation ───
    SequentialAnimation {
        id: wormAnim

        ParallelAnimation {
            NumberAnimation {
                id: xExpand; target: highlight; property: "x"
                duration: 120; easing.type: Easing.OutCubic
            }
            NumberAnimation {
                id: wExpand; target: highlight; property: "width"
                duration: 120; easing.type: Easing.OutCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                id: xContract; target: highlight; property: "x"
                duration: 180; easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                id: wContract; target: highlight; property: "width"
                duration: 180; easing.type: Easing.InOutCubic
            }
        }
    }

    // ─── Sliding Highlight (behind cells) ───
    Rectangle {
        id: highlight
        visible: workspacesWidget.activeIndex >= 0
        y: 0
        width: cellSize
        height: cellSize
        radius: Root.Theme.borderRadiusMedium
        color: Root.Theme.primary

        Component.onCompleted: {
            if (workspacesWidget.activeIndex >= 0)
                x = workspacesWidget.activeIndex * (workspacesWidget.cellSize + workspacesWidget.cellSpacing)
        }

        Behavior on color {
            ColorAnimation { duration: Root.Theme.durationFast }
        }
    }

    // ─── Workspace Cells (on top of highlight) ───
    Row {
        id: row
        spacing: cellSpacing

        Repeater {
            model: workspaceIds

            Item {
                id: cell
                width: cellSize
                height: cellSize

                property bool isActive: Root.Workspaces.isWorkspaceActive(modelData)
                property bool isOccupied: !isActive && Root.Workspaces.isWorkspaceOccupied(modelData)

                Text {
                    anchors.centerIn: parent
                    text: modelData
                    font.pixelSize: Root.Theme.fontSizeTiny + 2
                    font.family: Root.Theme.fontFamily
                    font.weight: cell.isActive ? Font.Bold
                        : cell.isOccupied ? Font.DemiBold
                        : Root.Theme.fontWeight
                    color: cell.isActive ? Root.Theme.on.primary
                        : mouseArea.containsMouse ? Root.Theme.on.surface
                        : cell.isOccupied ? Root.Theme.on.surface
                        : Root.Theme.on.surfaceVariant
                    opacity: cell.isActive ? 1.0
                        : cell.isOccupied ? 0.85
                        : 0.4

                    Behavior on color {
                        ColorAnimation { duration: Root.Theme.durationFast }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: Root.Theme.durationFast }
                    }
                }


                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Root.Workspaces.switchToWorkspace(modelData)
                }
            }
        }
    }
}
