import QtQuick
import QtQuick.Layouts
import ".." as Root

Root.BarWidget {
    id: perfWidget
    acceptedButtons: Qt.LeftButton
    anchorTarget: Root.Performance

    // Exposed for parent pill visibility binding (don't use `visible` — circular dependency)
    readonly property bool hasAlerts: _alerts.length > 0

    readonly property int cpuPercent: Root.Performance.cpuPercent
    readonly property int cpuTemp: Root.Performance.cpuTemp
    readonly property int ramPercent: Root.Performance.ramPercent
    readonly property int gpuPercent: Root.Performance.gpuPercent
    readonly property int gpuTemp: Root.Performance.gpuTemp
    readonly property int nvmeTemp: Root.Performance.nvmeTemp
    readonly property int diskPercent: {
        var disks = Root.Performance.disks
        for (var i = 0; i < disks.length; i++) {
            if (disks[i].mount === "/") return disks[i].percent
        }
        return disks.length > 0 ? disks[0].percent : -1
    }

    // ─── Per-component thresholds ───
    //                          usage warn/crit    temp warn/crit
    // CPU                      75 / 90            80 / 95
    // RAM                      80 / 92            — / —
    // GPU                      85 / 95            80 / 90
    // Disk                     85 / 95            55 / 70 (NVMe)

    // ─── Hysteresis: keep alerts visible for cooldown period after metric drops ───
    readonly property int _cooldownMs: 10000
    property var _stickyMap: ({})  // key → { alert, clearing, clearAt }

    // ─── Raw alerts: immediate threshold computation ───
    readonly property var _rawAlerts: {
        var alerts = []

        // CPU
        var cpuUsageSev = cpuPercent >= 90 ? 2 : cpuPercent >= 75 ? 1 : 0
        var cpuTempSev = cpuTemp > 0 ? (cpuTemp >= 95 ? 2 : cpuTemp >= 80 ? 1 : 0) : 0
        if (cpuUsageSev > 0 || cpuTempSev > 0) {
            if (cpuTempSev >= cpuUsageSev)
                alerts.push({ key: "cpu", icon: "󰍛", value: cpuTemp + "°C", type: "temp", severity: cpuTempSev })
            else
                alerts.push({ key: "cpu", icon: "󰍛", value: cpuPercent + "%", type: "usage", severity: cpuUsageSev })
        }

        // RAM (usage only)
        var ramUsageSev = ramPercent >= 92 ? 2 : ramPercent >= 80 ? 1 : 0
        if (ramUsageSev > 0)
            alerts.push({ key: "ram", icon: "󰘚", value: ramPercent + "%", type: "usage", severity: ramUsageSev })

        // GPU
        var gpuUsageSev = gpuPercent >= 95 ? 2 : gpuPercent >= 85 ? 1 : 0
        var gpuTempSev = gpuTemp > 0 ? (gpuTemp >= 90 ? 2 : gpuTemp >= 80 ? 1 : 0) : 0
        if (gpuUsageSev > 0 || gpuTempSev > 0) {
            if (gpuTempSev >= gpuUsageSev)
                alerts.push({ key: "gpu", icon: "󰢮", value: gpuTemp + "°C", type: "temp", severity: gpuTempSev })
            else
                alerts.push({ key: "gpu", icon: "󰢮", value: gpuPercent + "%", type: "usage", severity: gpuUsageSev })
        }

        // Disk
        var diskUsageSev = diskPercent >= 95 ? 2 : diskPercent >= 85 ? 1 : 0
        var nvmeTempSev = nvmeTemp > 0 ? (nvmeTemp >= 70 ? 2 : nvmeTemp >= 55 ? 1 : 0) : 0
        if (diskUsageSev > 0 || nvmeTempSev > 0) {
            if (nvmeTempSev >= diskUsageSev)
                alerts.push({ key: "disk", icon: "󰋊", value: nvmeTemp + "°C", type: "temp", severity: nvmeTempSev })
            else
                alerts.push({ key: "disk", icon: "󰋊", value: diskPercent + "%", type: "usage", severity: diskUsageSev })
        }

        return alerts
    }

    on_RawAlertsChanged: _updateAlerts()

    // ─── Sticky alerts with cooldown ───
    property var _alerts: []

    function _updateAlerts() {
        var now = Date.now()
        var raw = _rawAlerts
        var map = _stickyMap

        // Build set of active raw keys
        var rawKeys = {}
        for (var i = 0; i < raw.length; i++) {
            rawKeys[raw[i].key] = raw[i]
        }

        // Upsert raw alerts (active = not clearing)
        for (var key in rawKeys) {
            map[key] = { alert: rawKeys[key], clearing: false, clearAt: 0 }
        }

        // For map entries not in raw: start clearing or remove if expired
        var hasClearing = false
        var keysToRemove = []
        for (var mk in map) {
            if (!rawKeys[mk]) {
                if (!map[mk].clearing) {
                    // Start cooldown
                    map[mk].clearing = true
                    map[mk].clearAt = now + _cooldownMs
                    hasClearing = true
                } else if (now >= map[mk].clearAt) {
                    keysToRemove.push(mk)
                } else {
                    hasClearing = true
                }
            }
        }

        for (var r = 0; r < keysToRemove.length; r++) {
            delete map[keysToRemove[r]]
        }

        // Convert map to array
        var result = []
        for (var ak in map) {
            var entry = map[ak]
            result.push({
                key: entry.alert.key,
                icon: entry.alert.icon,
                value: entry.alert.value,
                type: entry.alert.type,
                severity: entry.alert.severity,
                clearing: entry.clearing
            })
        }

        _stickyMap = map
        _alerts = result
        _sweepTimer.running = hasClearing
    }

    Timer {
        id: _sweepTimer
        interval: 1000
        repeat: true
        running: false
        onTriggered: perfWidget._updateAlerts()
    }

    // Worst severity across all alerts
    readonly property int _maxSeverity: {
        var max = 0
        for (var i = 0; i < _alerts.length; i++)
            if (_alerts[i].severity > max) max = _alerts[i].severity
        return max
    }

    function _sevColor(sev) {
        if (sev >= 2) return Root.Theme.error
        if (sev >= 1) return Root.Theme.caution
        return Root.Theme.on.surfaceVariant
    }

    onClicked: {
        updateAnchor()
        Root.Performance.togglePopup()
    }

    // Alert items
    Repeater {
        model: perfWidget._alerts

        delegate: Item {
            required property var modelData
            implicitWidth: alertRow.implicitWidth
            implicitHeight: alertRow.implicitHeight
            Layout.alignment: Qt.AlignVCenter
            opacity: modelData.clearing ? 0.5 : 1.0

            Behavior on opacity {
                OpacityAnimator { duration: Root.Theme.durationMedium; easing.type: Easing.OutCubic }
            }

            Row {
                id: alertRow
                anchors.centerIn: parent
                spacing: 2

                Text {
                    text: modelData.icon
                    font.pixelSize: Root.Theme.iconFontSize
                    font.family: Root.Theme.fontFamily
                    color: perfWidget._sevColor(modelData.severity)
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: modelData.value
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamilyMono
                    font.weight: Root.Theme.fontWeight
                    color: perfWidget._sevColor(modelData.severity)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
