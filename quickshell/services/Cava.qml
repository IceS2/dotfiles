pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // ─── Public API ───

    property list<real> bars: _emptyBars()
    property list<real> smoothBars: _emptyBars()

    // Set by MediaPopup — true when popup is visible and has a player
    property bool active: false

    // ─── Internal ───

    property list<real> _targetBars: _emptyBars()
    readonly property int _barCount: 32
    readonly property real _smoothFactor: 0.3

    function _emptyBars() {
        var a = []
        for (var i = 0; i < 32; i++) a.push(0.0)
        return a
    }

    // ─── Cava Process ───

    property Process _cavaProcess: Process {
        running: root.active

        command: ["sh", "-c", [
            "cat <<'CAVAEOF' | cava -p /dev/stdin",
            "[general]",
            "bars = 32",
            "framerate = 30",
            "[output]",
            "method = raw",
            "data_format = ascii",
            "bar_delimiter = 59",
            "ascii_max_range = 1000",
            "CAVAEOF"
        ].join("\n")]

        stdout: SplitParser {
            onRead: data => {
                var parts = data.split(";")
                var newBars = []
                for (var i = 0; i < root._barCount; i++) {
                    var val = i < parts.length ? parseInt(parts[i]) / 1000.0 : 0.0
                    if (isNaN(val)) val = 0.0
                    newBars.push(Math.min(1.0, Math.max(0.0, val)))
                }
                root._targetBars = newBars
                root.bars = newBars
            }
        }
    }

    // ─── Smoothing Timer ───

    property Timer _smoothTimer: Timer {
        interval: 33  // ~30fps
        repeat: true
        running: root.active

        onTriggered: {
            var target = root._targetBars
            var current = root.smoothBars
            var result = []
            var factor = root._smoothFactor

            for (var i = 0; i < root._barCount; i++) {
                var t = i < target.length ? target[i] : 0.0
                var c = i < current.length ? current[i] : 0.0
                result.push(c + (t - c) * factor)
            }
            root.smoothBars = result
        }
    }

    // ─── Reset on deactivate ───

    onActiveChanged: {
        if (!active) {
            root._targetBars = _emptyBars()
            root.bars = _emptyBars()
            root.smoothBars = _emptyBars()
        }
    }
}
