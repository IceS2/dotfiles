pragma Singleton
import QtQuick
import Quickshell.Io

/**
 * Updates Service — periodic package update checker via checkupdates + paru -Qua.
 *
 * Ghost widget pattern: hasUpdates drives bar visibility.
 * Critical packages (linux, nvidia) trigger error coloring.
 * 4-hour check interval, toast on first detection of new updates.
 */
PopupServiceBase {
    id: root
    _modalKey: "updates"

    signal updatesDetected(string icon, string message)

    // ─── Public State ───

    property int officialCount: 0
    property int aurCount: 0
    readonly property int totalCount: officialCount + aurCount
    property var officialPackages: []    // [{name, oldVer, newVer}]
    property var aurPackages: []         // [{name, oldVer, newVer}]
    property var criticalPackages: []    // subset of official+aur matching kernel/nvidia
    readonly property bool hasCritical: criticalPackages.length > 0
    readonly property bool hasUpdates: totalCount > 0
    property string lastChecked: ""      // "2h ago" style relative time
    property bool checking: false

    // ─── Critical Package Patterns ───

    readonly property var _criticalNames: [
        "linux", "linux-headers", "linux-lts", "linux-lts-headers",
        "nvidia-dkms", "nvidia-utils", "lib32-nvidia-utils", "nvidia-open-dkms"
    ]

    // ─── Internal State ───

    property int _prevTotalCount: -1
    property var _lastCheckTime: null

    // ─── Check Logic ───

    function refresh() {
        if (root.checking) return
        root.checking = true
        root._officialBuffer = []
        root._aurBuffer = []
        root._officialProc.running = true
    }

    property var _officialBuffer: []
    property var _aurBuffer: []

    property Process _officialProc: Process {
        running: false
        command: ["checkupdates"]

        stdout: SplitParser {
            onRead: data => {
                if (data.trim()) root._officialBuffer.push(data.trim())
            }
        }

        onExited: (exitCode, exitStatus) => {
            // checkupdates exits 2 when no updates available — that's fine
            root._aurProc.running = true
        }
    }

    property Process _aurProc: Process {
        running: false
        command: ["paru", "-Qua"]

        stdout: SplitParser {
            onRead: data => {
                if (data.trim()) root._aurBuffer.push(data.trim())
            }
        }

        onExited: (exitCode, exitStatus) => {
            root._processResults()
        }
    }

    function _parsePackageLine(line) {
        // Format: "name oldver -> newver"
        var parts = line.split(/\s+/)
        if (parts.length >= 4 && parts[2] === "->") {
            return { name: parts[0], oldVer: parts[1], newVer: parts[3] }
        }
        // Fallback: "name oldver newver" (paru -Qua sometimes omits ->)
        if (parts.length >= 3) {
            return { name: parts[0], oldVer: parts[1], newVer: parts[parts.length - 1] }
        }
        return null
    }

    function _processResults() {
        var official = []
        for (var i = 0; i < _officialBuffer.length; i++) {
            var pkg = _parsePackageLine(_officialBuffer[i])
            if (pkg) official.push(pkg)
        }

        var aur = []
        for (var j = 0; j < _aurBuffer.length; j++) {
            var aurPkg = _parsePackageLine(_aurBuffer[j])
            if (aurPkg) aur.push(aurPkg)
        }

        // Detect critical packages
        var critical = []
        var allPkgs = official.concat(aur)
        for (var k = 0; k < allPkgs.length; k++) {
            if (_criticalNames.indexOf(allPkgs[k].name) >= 0) {
                critical.push(allPkgs[k])
            }
        }

        root.officialPackages = official
        root.aurPackages = aur
        root.criticalPackages = critical
        root.officialCount = official.length
        root.aurCount = aur.length

        // Signal toast if count changed and updates available
        var newTotal = official.length + aur.length
        if (newTotal > 0 && newTotal !== root._prevTotalCount) {
            root.updatesDetected("󰏔", newTotal + " update" + (newTotal !== 1 ? "s" : "") + " available")
        }
        root._prevTotalCount = newTotal

        // Update timing
        root._lastCheckTime = new Date()
        root._updateLastChecked()
        root.checking = false
    }

    // ─── Relative Time Display ───

    function _updateLastChecked() {
        if (!root._lastCheckTime) {
            root.lastChecked = "never"
            return
        }
        var now = new Date()
        var diffMs = now - root._lastCheckTime
        var diffMin = Math.floor(diffMs / 60000)
        if (diffMin < 1) root.lastChecked = "just now"
        else if (diffMin < 60) root.lastChecked = diffMin + "m ago"
        else {
            var diffHrs = Math.floor(diffMin / 60)
            root.lastChecked = diffHrs + "h ago"
        }
    }

    property Timer _lastCheckedTimer: Timer {
        interval: 60000
        running: root._lastCheckTime !== null
        repeat: true
        onTriggered: root._updateLastChecked()
    }

    // ─── Periodic Check Timer (4 hours) ───

    property Timer _checkTimer: Timer {
        interval: 14400000  // 4 hours
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // ─── Launch Update Script ───

    property Process _launchProc: Process {
        running: false
    }

    function launchUpdate() {
        root._launchProc.command = [
            "kitty", "--title", "System Update", "-e",
            "bash", "-c", "~/.dotfiles/tools/scripts/update.sh; echo; echo 'Press any key to close...'; read -n1"
        ]
        root._launchProc.running = true
        root.hidePopup()
    }
}
