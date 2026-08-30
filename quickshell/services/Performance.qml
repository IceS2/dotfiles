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
        root.updateKernelMetrics()
        root._gpuProc.running = true
        root._diskProc.running = true
    }

    // ─── CPU State ───

    property int cpuPercent: 0
    property int cpuTemp: 0
    property bool kernelMetricsStale: true

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

    // ─── RAM State ───

    property int ramPercent: 0
    property real ramUsedGb: 0
    property real ramTotalGb: 0

    property FileView _ramInfoFile: FileView {
        path: "/proc/meminfo"
        watchChanges: false
        preload: false
        blockLoading: true
    }

    // ─── GPU State (NVIDIA) ───

    property int gpuPercent: 0
    property int gpuTemp: 0
    property real gpuVramUsedGb: 0
    property real gpuVramTotalGb: 0
    property int gpuVramPercent: 0
    property bool gpuMetricsStale: true

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
                    root.gpuMetricsStale = false
                }
            }
        }
        onExited: (code, status) => {
            if (code !== 0) root.gpuMetricsStale = true
        }
    }

    // ─── Extra Temperatures ───

    property int ramTemp: 0
    property int nvmeTemp: 0

    property string _ramTempPath1: ""
    property string _ramTempPath2: ""
    property string _nvmeTempPath: ""

    property FileView _ramTempFile1: FileView { path: root._ramTempPath1; watchChanges: false; preload: false; blockLoading: true }
    property FileView _ramTempFile2: FileView { path: root._ramTempPath2; watchChanges: false; preload: false; blockLoading: true }
    property FileView _nvmeTempFile: FileView { path: root._nvmeTempPath; watchChanges: false; preload: false; blockLoading: true }

    // Hardware topology changes rarely; discover paths once and read them directly thereafter.
    property Process _sensorDiscoveryProc: Process {
        running: true
        command: ["bash", "-c", "for d in /sys/class/hwmon/hwmon*; do read -r n < \"$d/name\" || continue; case \"$n\" in spd5118) printf 'RAM:%s\\n' \"$d/temp1_input\" ;; nvme) printf 'NVME:%s\\n' \"$d/temp1_input\" ;; esac; done"]

        stdout: SplitParser {
            onRead: data => {
                if (data.startsWith("RAM:")) {
                    var path = data.substring(4).trim()
                    if (!root._ramTempPath1) root._ramTempPath1 = path
                    else if (!root._ramTempPath2) root._ramTempPath2 = path
                } else if (data.startsWith("NVME:")) {
                    root._nvmeTempPath = data.substring(5).trim()
                }
            }
        }
        onExited: root.updateKernelMetrics()
    }

    function readTemperature(file) {
        if (!file.path) return null
        file.reload()
        var value = parseInt(file.text().trim())
        return isNaN(value) ? null : Math.round(value / 1000)
    }

    function scheduleSensorDiscovery() {
        if (!root._sensorRetry.running) root._sensorRetry.start()
    }

    function discoverSensors() {
        if (root._sensorDiscoveryProc.running) return
        root._ramTempPath1 = ""
        root._ramTempPath2 = ""
        root._nvmeTempPath = ""
        root._sensorDiscoveryProc.running = true
    }

    function updateKernelMetrics() {
        root._cpuStatFile.reload()
        var cpuLine = root._cpuStatFile.text().split("\n")[0]
        var parts = cpuLine.trim().split(/\s+/)
        var cpuValid = parts.length >= 8 && parts[0] === "cpu"
        if (cpuValid) {
            var idle = (parseInt(parts[4]) || 0) + (parseInt(parts[5]) || 0)
            var active = (parseInt(parts[1]) || 0) + (parseInt(parts[2]) || 0)
                + (parseInt(parts[3]) || 0) + (parseInt(parts[6]) || 0)
                + (parseInt(parts[7]) || 0)
            var total = idle + active
            if (root._prevCpuTimes) {
                var dTotal = total - root._prevCpuTimes.total
                var dIdle = idle - root._prevCpuTimes.idle
                if (dTotal > 0) root.cpuPercent = Math.round((dTotal - dIdle) / dTotal * 100)
            }
            root._prevCpuTimes = { total: total, idle: idle }
        }

        root._ramInfoFile.reload()
        var mem = root._ramInfoFile.text()
        var totalMatch = mem.match(/^MemTotal:\s+(\d+)/m)
        var availableMatch = mem.match(/^MemAvailable:\s+(\d+)/m)
        var memoryValid = totalMatch && availableMatch
        if (memoryValid) {
            var totalKb = parseInt(totalMatch[1])
            var availableKb = parseInt(availableMatch[1])
            var usedKb = totalKb - availableKb
            root.ramPercent = Math.round(usedKb / totalKb * 100)
            root.ramUsedGb = Math.round(usedKb / 1048576 * 10) / 10
            root.ramTotalGb = Math.round(totalKb / 1048576 * 10) / 10
        }
        root.kernelMetricsStale = !(cpuValid && memoryValid)

        var cpuTemperature = root.readTemperature(root._cpuTempFile)
        if (cpuTemperature !== null) root.cpuTemp = cpuTemperature
        var ram1 = root.readTemperature(root._ramTempFile1)
        var ram2 = root.readTemperature(root._ramTempFile2)
        if (ram1 !== null || ram2 !== null) {
            if (ram1 !== null && ram2 !== null) root.ramTemp = Math.round((ram1 + ram2) / 2)
            else root.ramTemp = ram1 !== null ? ram1 : ram2
        }
        var nvmeTemperature = root.readTemperature(root._nvmeTempFile)
        if (nvmeTemperature !== null) root.nvmeTemp = nvmeTemperature

        if ((root._ramTempPath1 && ram1 === null)
                || (root._ramTempPath2 && ram2 === null)
                || (root._nvmeTempPath && nvmeTemperature === null)) {
            root.scheduleSensorDiscovery()
        }
    }

    property Timer _sensorRetry: Timer {
        interval: 60000
        onTriggered: root.discoverSensors()
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
            root.updateKernelMetrics()
        }
    }

    property Timer _gpuTimer: Timer {
        interval: root.popupVisible ? 2000 : 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root._gpuProc.running = true
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
