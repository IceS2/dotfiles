pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

QtObject {
    id: root

    property var windowList: []
    property var addresses: []
    property var windowByAddress: ({})
    property var monitors: []

    // Set from components (e.g. OverviewPanel) — singletons can't reference siblings
    property bool polling: false

    function updateWindowList() {
        getClients.running = true;
    }

    function updateMonitors() {
        getMonitors.running = true;
    }

    function updateAll() {
        updateWindowList();
        updateMonitors();
    }

    // Only poll while active
    property Connections _hyprlandConn: Connections {
        enabled: root.polling
        target: Hyprland
        function onRawEvent(event) {
            root.updateAll();
        }
    }

    onPollingChanged: {
        if (polling) updateAll();
    }

    property Process _getClients: Process {
        id: getClients
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            id: clientsCollector
            onStreamFinished: {
                try {
                    root.windowList = JSON.parse(clientsCollector.text);
                } catch (e) {
                    console.warn("HyprlandData: failed to parse clients:", e)
                    root.windowList = []
                }
                var tempWinByAddress = {};
                for (var i = 0; i < root.windowList.length; ++i) {
                    var win = root.windowList[i];
                    tempWinByAddress[win.address] = win;
                }
                root.windowByAddress = tempWinByAddress;
                root.addresses = root.windowList.map(function(win) { return win.address; });
            }
        }
    }

    property Process _getMonitors: Process {
        id: getMonitors
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            id: monitorsCollector
            onStreamFinished: {
                try {
                    root.monitors = JSON.parse(monitorsCollector.text);
                } catch (e) {
                    console.warn("HyprlandData: failed to parse monitors:", e)
                    root.monitors = []
                }
            }
        }
    }
}
