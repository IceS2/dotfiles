pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Caffeine Service — manual idle inhibitor toggle.
 *
 * hypridle (see hypr/hypridle.conf) owns the lock + suspend timers and ignores
 * systemd inhibitors, so "caffeinating" means stopping the daemon. The actual
 * toggle + toast lives in hypr/scripts/caffeine.sh (single source of truth,
 * shared with the Super+Shift+C keybind); this service just runs it and polls
 * `pidof hypridle` so the bar icon stays in sync no matter how it was toggled.
 *
 * active == true  →  caffeinated (hypridle stopped, no lock/suspend)
 */
QtObject {
    id: root

    // ─── Public State ───

    // True when idle handling is disabled (hypridle not running).
    property bool active: false

    // ─── Toggle ───

    function toggle() {
        root._toggleProc.running = true
    }

    property Process _toggleProc: Process {
        running: false
        command: ["bash", "-c", "$HOME/.config/hypr/scripts/caffeine.sh"]
        onExited: root.refresh()
    }

    // ─── State Sync ───

    // pidof exits 0 when hypridle is running → not caffeinated.
    function refresh() {
        root._checkProc.running = true
    }

    property Process _checkProc: Process {
        running: false
        command: ["pidof", "hypridle"]
        onExited: (exitCode, exitStatus) => {
            root.active = (exitCode !== 0)
        }
    }

    // Poll so mouse toggle + keybind toggle + external changes stay in sync.
    property Timer _pollTimer: Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
