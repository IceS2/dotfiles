pragma Singleton
import QtQuick
import Quickshell.Io

/**
 * Performance Service - System monitoring via /proc, sysfs, nvidia-smi
 *
 * CPU: Two-sample /proc/stat delta (accurate usage %)
 * RAM: /proc/meminfo parsing
 * GPU: nvidia-smi query
 * Disk: df parsing
 */
PopupServiceBase {
    id: root
    _modalKey: "performance"

    function showPopup() {
        root.popupVisible = true
        // Force immediate updates on open
        root._cpuProc.running = true
        root._gpuProc.running = true
        root._diskProc.running = true
    }

    // ─── CPU State ───

    property int cpuPercent: 0
    property int cpuTemp: 0

    // Two-sample delta for accurate CPU usage
    property var _prevCpuTimes: null

    property FileView _cpuStatFile: FileView {
        path: "/proc/stat"
        watchChanges: false
        preload: false
        blockLoading: true
    }

    property FileView _cpuTempFile: FileView {
        // x86_pkg_temp is typically thermal_zone0 on Intel
        path: "/sys/class/thermal/thermal_zone0/temp"
        watchChanges: false
        preload: false
        blockLoading: true
    }

    property Process _cpuProc: Process {
        running: false
        command: ["cat", "/proc/stat"]
        stdout: SplitParser {
            onRead: data => {
                if (!data.startsWith("cpu ")) return
                var parts = data.trim().split(/\s+/)
                if (parts.length < 8) return

                // user, nice, system, idle, iowait, irq, softirq
                var user = parseInt(parts[1]) || 0
                var nice = parseInt(parts[2]) || 0
                var system = parseInt(parts[3]) || 0
                var idle = parseInt(parts[4]) || 0
                var iowait = parseInt(parts[5]) || 0
                var irq = parseInt(parts[6]) || 0
                var softirq = parseInt(parts[7]) || 0

                var totalIdle = idle + iowait
                var totalActive = user + nice + system + irq + softirq
                var total = totalIdle + totalActive

                if (root._prevCpuTimes) {
                    var dTotal = total - root._prevCpuTimes.total
                    var dIdle = totalIdle - root._prevCpuTimes.idle
                    if (dTotal > 0) {
                        root.cpuPercent = Math.round(((dTotal - dIdle) / dTotal) * 100)
                    }
                }

                root._prevCpuTimes = { total: total, idle: totalIdle }
            }
        }
        onExited: {
            // Read temperature
            root._cpuTempFile.reload()
            var tempStr = root._cpuTempFile.text()
            if (tempStr) {
                var temp = parseInt(tempStr.trim())
                if (!isNaN(temp)) root.cpuTemp = Math.round(temp / 1000)
            }
        }
    }

    // ─── RAM State ───

    property int ramPercent: 0
    property real ramUsedGb: 0
    property real ramTotalGb: 0

    property Process _ramProc: Process {
        running: false
        command: ["cat", "/proc/meminfo"]

        property real _total: 0
        property real _available: 0

        stdout: SplitParser {
            onRead: data => {
                if (data.startsWith("MemTotal:")) {
                    var val = parseInt(data.replace(/[^0-9]/g, ""))
                    if (!isNaN(val)) root._ramProc._total = val
                } else if (data.startsWith("MemAvailable:")) {
                    var val2 = parseInt(data.replace(/[^0-9]/g, ""))
                    if (!isNaN(val2)) root._ramProc._available = val2
                }
            }
        }

        onExited: {
            if (_total > 0) {
                var used = _total - _available
                root.ramPercent = Math.round((used / _total) * 100)
                root.ramUsedGb = Math.round(used / 1048576 * 10) / 10
                root.ramTotalGb = Math.round(_total / 1048576 * 10) / 10
            }
        }
    }

    // ─── GPU State (NVIDIA) ───

    property int gpuPercent: 0
    property int gpuTemp: 0
    property real gpuVramUsedGb: 0
    property real gpuVramTotalGb: 0
    property int gpuVramPercent: 0

    property Process _gpuProc: Process {
        running: false
        command: ["nvidia-smi", "--query-gpu=temperature.gpu,utilization.gpu,memory.used,memory.total", "--format=csv,noheader,nounits"]

        stdout: SplitParser {
            onRead: data => {
                if (!data || data.trim() === "") return
                var parts = data.split(",").map(function(s) { return s.trim() })
                if (parts.length >= 4) {
                    root.gpuTemp = parseInt(parts[0]) || 0
                    root.gpuPercent = parseInt(parts[1]) || 0
                    var vramUsed = parseInt(parts[2]) || 0  // MiB
                    var vramTotal = parseInt(parts[3]) || 0  // MiB
                    root.gpuVramUsedGb = Math.round(vramUsed / 1024 * 10) / 10
                    root.gpuVramTotalGb = Math.round(vramTotal / 1024 * 10) / 10
                    root.gpuVramPercent = vramTotal > 0 ? Math.round((vramUsed / vramTotal) * 100) : 0
                }
            }
        }
    }

    // ─── Extra Temperatures ───

    property int ramTemp: 0
    property int nvmeTemp: 0

    property Process _tempProc: Process {
        running: false
        command: ["bash", "-c", "for d in /sys/class/hwmon/hwmon*/; do n=$(cat \"$d/name\" 2>/dev/null); if [ \"$n\" = \"spd5118\" ]; then echo \"RAM:$(cat \"$d/temp1_input\" 2>/dev/null)\"; elif [ \"$n\" = \"nvme\" ]; then echo \"NVME:$(cat \"$d/temp1_input\" 2>/dev/null)\"; fi; done"]

        stdout: SplitParser {
            onRead: data => {
                if (data.startsWith("RAM:")) {
                    var val = parseInt(data.substring(4))
                    if (!isNaN(val)) {
                        // Average with existing if we already have a value (multiple sticks)
                        if (root.ramTemp > 0)
                            root.ramTemp = Math.round((root.ramTemp + Math.round(val / 1000)) / 2)
                        else
                            root.ramTemp = Math.round(val / 1000)
                    }
                } else if (data.startsWith("NVME:")) {
                    var val2 = parseInt(data.substring(5))
                    if (!isNaN(val2)) root.nvmeTemp = Math.round(val2 / 1000)
                }
            }
        }

        onStarted: {
            root.ramTemp = 0
        }
    }

    // ─── Disk State ───

    property var disks: []

    property var _diskBuffer: []

    property Process _diskProc: Process {
        running: false
        command: ["df", "--output=source,fstype,size,used,avail,pcent,target", "-B1"]

        stdout: SplitParser {
            onRead: data => {
                if (!data || !data.startsWith("/dev/")) return
                root._diskBuffer.push(data)
            }
        }

        onStarted: {
            root._diskBuffer = []
        }

        onExited: {
            var result = []
            for (var i = 0; i < root._diskBuffer.length; i++) {
                var parts = root._diskBuffer[i].trim().split(/\s+/)
                if (parts.length < 7) continue

                var total = parseInt(parts[2]) || 0
                var used = parseInt(parts[3]) || 0
                var pctStr = parts[5] || "0%"
                var mount = parts.slice(6).join(" ")

                // Skip small partitions (< 1GB) and special mounts
                if (total < 1073741824) continue
                if (mount.startsWith("/boot") || mount.startsWith("/snap")) continue

                result.push({
                    device: parts[0],
                    fstype: parts[1],
                    mount: mount,
                    totalGb: Math.round(total / 1073741824 * 10) / 10,
                    usedGb: Math.round(used / 1073741824 * 10) / 10,
                    percent: parseInt(pctStr) || 0
                })
            }

            root.disks = result
            root._diskBuffer = []
        }
    }

    // ─── Update Timer ───

    property Timer _fastTimer: Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root._cpuProc.running = true
            root._ramProc.running = true
            root._gpuProc.running = true
            root._tempProc.running = true
        }
    }

    property Timer _slowTimer: Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root._diskProc.running = true
        }
    }

    // ─── Icons ───

    readonly property string cpuIcon: {
        if (cpuTemp >= 90) return "󰸁"
        if (cpuPercent >= 80) return "󰘚"
        return "󰍛"
    }

    // ─── Helpers ───

    function formatPercent(val) {
        return val + "%"
    }

    function tempColor(temp) {
        if (temp >= 90) return "#f38ba8"  // error
        if (temp >= 75) return "#fab387"  // caution
        if (temp >= 60) return "#f9e2af"  // warning
        return "#a6e3a1"  // success
    }
}
