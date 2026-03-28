pragma Singleton
import QtQuick
import Quickshell.Hyprland

QtObject {
  id: root

  // Per-monitor workspace IDs — edit this mapping when monitors change
  // Keys are Hyprland monitor names (from `hyprctl monitors`), values are workspace IDs
  readonly property var monitorWorkspaces: ({
    "DP-2": [1, 3, 5, 7, 9],
    "DP-1": [2, 4, 6, 8, 10]
  })
  readonly property var _defaultIds: [1, 2, 3, 4, 5]

  function workspaceIdsForMonitor(monitorName) {
    return monitorWorkspaces[monitorName] ?? _defaultIds
  }

  // Track active workspace IDs across ALL monitors (reactive)
  readonly property var activeWorkspaceIds: {
    const ids = []
    const monitors = Hyprland.monitors.values
    for (let i = 0; i < monitors.length; i++) {
      const ws = monitors[i].activeWorkspace
      if (ws) ids.push(ws.id)
    }
    return ids
  }

  // Track occupied workspace IDs (has windows, may or may not be active)
  // Hyprland only tracks workspaces that have windows or are active on a monitor
  readonly property var occupiedWorkspaceIds: {
    const ids = []
    const workspaces = Hyprland.workspaces.values
    for (let i = 0; i < workspaces.length; i++) {
      const ws = workspaces[i]
      if (ws && ws.id > 0) ids.push(ws.id)
    }
    return ids
  }

  function isWorkspaceActive(id) {
    // Reading activeWorkspaceIds makes this reactive when called from a binding
    return activeWorkspaceIds.indexOf(id) !== -1
  }

  function isWorkspaceOccupied(id) {
    // Reading occupiedWorkspaceIds makes this reactive when called from a binding
    return occupiedWorkspaceIds.indexOf(id) !== -1
  }

  function switchToWorkspace(id) {
    Hyprland.dispatch("workspace " + id)
  }
}
