pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "modals.js" as Modals

QtObject {
    id: root

    property bool popupVisible: false
    property int currentIndex: 0
    property var entries: []

    // Mode: "span", "dp1", "dp2"
    property string mode: "span"
    readonly property var modes: ["span", "dp1", "dp2"]
    readonly property var modeLabels: ({
        "span": "Span",
        "dp1": "Left (DP-1)",
        "dp2": "Right (DP-2)"
    })

    readonly property string _configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
    readonly property string wallpaperDir: _configHome + "/wallpaper/images"
    readonly property string scriptPath: _configHome + "/hypr/scripts/wallpaper.sh"
    readonly property string themeDir: _configHome + "/theme"
    readonly property string modeFile: themeDir + "/.mode"

    // Delete confirmation
    property bool deleteConfirmPending: false

    function requestDelete() {
        if (!popupVisible || entries.length === 0) return;
        deleteConfirmPending = true;
    }

    function cancelDelete() {
        deleteConfirmPending = false;
    }

    function confirmDelete() {
        if (!deleteConfirmPending || entries.length === 0) return;
        deleteConfirmPending = false;

        var idx = currentIndex;
        var path = entries[idx].path;

        // Optimistic local removal — ScriptModel diffs and emits rowsRemoved
        var newEntries = entries.slice();
        newEntries.splice(idx, 1);

        // Adjust index if we were at the end
        if (idx >= newEntries.length && newEntries.length > 0) {
            currentIndex = newEntries.length - 1;
        }

        entries = newEntries;

        // Preview the new item at this position
        if (newEntries.length > 0) {
            _triggerPreview();
        }

        // Trash the file in background
        _deleteProcess.command = ["gio", "trash", path];
        _deleteProcess.running = true;
    }

    property Process _deleteProcess: Process {
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn("Wallpaper: failed to trash file, exit code", exitCode);
                root.refresh(); // re-sync on failure
            }
        }
    }

    // Saved state for revert on cancel
    property var _savedState: null
    property string _savedColorsJson: ""

    // Read theme mode (static/dynamic)
    property string _modeText: ""
    property FileView _modeFile: FileView {
        path: Qt.resolvedUrl("file://" + root.modeFile)
        watchChanges: true
        onTextChanged: {
            root._modeText = _modeFile.text() || "";
        }
    }
    readonly property bool isDynamic: _modeText.trim() === "dynamic"

    // Signals for Theme integration (singletons can't reference siblings)
    signal opened()
    signal confirmed()
    signal cancelled()
    signal previewColorsReady(var colors)

    function showPopup() {
        Modals.closeOthers("wallpaper")
        currentIndex = 0;
        deleteConfirmPending = false;
        _saveCurrentState();
        _saveCurrentColors();
        opened();
        refresh();
        popupVisible = true;
    }

    function hidePopup() {
        popupVisible = false;
    }

    function togglePopup() {
        if (popupVisible) cancel();
        else showPopup();
    }

    // Confirm: keep current wallpaper + colors, distribute theme, close
    function confirm() {
        _savedState = null;
        _savedColorsJson = "";
        confirmed();
        // Distribute colors to non-QML consumers (kitty, hyprland, neovim, etc.)
        applyThemeProcess.running = true;
        hidePopup();
    }

    // Cancel: revert wallpaper and colors, close
    function cancel() {
        if (_savedState !== null) {
            restoreProcess.command = [scriptPath].concat(_savedState);
            restoreProcess.running = true;
            _savedState = null;
        }
        cancelled();
        // Restore colors.json on disk for non-QML consumers
        if (_savedColorsJson.length > 0) {
            _restoreColorsFile.setText(_savedColorsJson);
            _savedColorsJson = "";
            // Revert kitty after the file write flushes
            _cancelKittyTimer.start();
        }
        hidePopup();
    }

    // Save current colors.json content for disk revert on cancel
    function _saveCurrentColors() {
        _savedColorsJson = "";
        _saveColorsProcess.running = true;
    }

    property var _saveColorLines: []
    property Process _saveColorsProcess: Process {
        command: ["cat", root.themeDir + "/colors.json"]
        stdout: SplitParser {
            onRead: data => { root._saveColorLines.push(data); }
        }
        onRunningChanged: {
            if (running) root._saveColorLines = [];
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && root._saveColorLines.length > 0) {
                root._savedColorsJson = root._saveColorLines.join("\n");
            }
        }
    }

    property FileView _restoreColorsFile: FileView {
        path: Qt.resolvedUrl("file://" + root.themeDir + "/colors.json")
    }

    // Matugen preview — generates colors from wallpaper image
    property Process matugenPreviewProcess: Process {
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                // Read generated colors.json and set as preview
                root._readColorsProcess.running = true;
            } else {
                console.warn("Wallpaper: matugen preview failed with code", exitCode);
            }
        }
    }

    // Read colors.json after matugen generates it → set as preview in Theme + kitty
    property var _previewColorLines: []
    property Process _readColorsProcess: Process {
        command: ["cat", root.themeDir + "/colors.json"]
        stdout: SplitParser {
            onRead: data => { root._previewColorLines.push(data); }
        }
        onRunningChanged: {
            if (running) root._previewColorLines = [];
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && root._previewColorLines.length > 0) {
                try {
                    var json = root._previewColorLines.join("\n");
                    var colors = JSON.parse(json);
                    root.previewColorsReady(colors);
                } catch (e) {
                    console.warn("Wallpaper: failed to parse preview colors:", e);
                }
                // Also apply to kitty for live terminal preview
                root._previewKittyProcess.running = true;
            }
        }
    }

    // Live kitty preview — apply-theme.sh --kitty-only reads current colors.json
    property Process _previewKittyProcess: Process {
        command: [root.themeDir + "/apply-theme.sh", "--kitty-only"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                console.warn("Wallpaper: kitty preview failed with code", exitCode);
        }
    }

    // Revert kitty after cancel — needs a short delay for _restoreColorsFile.setText to flush
    property Timer _cancelKittyTimer: Timer {
        interval: 150
        repeat: false
        onTriggered: root._previewKittyProcess.running = true
    }

    // Extract vibrant color then run matugen with it as source
    property string _extractedColor: ""
    property string _pendingPreviewImage: ""
    property Process _extractColorProcess: Process {
        stdout: SplitParser {
            onRead: data => {
                var trimmed = data.trim();
                if (trimmed.length === 6) root._extractedColor = trimmed;
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && root._extractedColor !== "") {
                // Use extracted vibrant color as source
                root.matugenPreviewProcess.command = [
                    "matugen", "color", "hex", root._extractedColor,
                    "--mode", "dark", "-t", "scheme-vibrant",
                    "--config", root.themeDir + "/matugen/config.toml"
                ];
            } else {
                // Fallback: let matugen extract from image with nearest filter
                root.matugenPreviewProcess.command = [
                    "matugen", "image", root._pendingPreviewImage,
                    "--mode", "dark", "-t", "scheme-vibrant",
                    "-r", "nearest",
                    "--config", root.themeDir + "/matugen/config.toml"
                ];
            }
            root.matugenPreviewProcess.running = true;
        }
    }

    function _triggerMatugenPreview(imagePath) {
        _extractedColor = "";
        _pendingPreviewImage = imagePath;
        _extractColorProcess.command = [themeDir + "/extract-color.sh", imagePath];
        _extractColorProcess.running = true;
    }

    // Apply theme to non-QML consumers (kitty, hyprland, neovim, etc.)
    property Process applyThemeProcess: Process {
        command: [root.themeDir + "/apply-theme.sh"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                console.warn("Wallpaper: apply-theme.sh failed with code", exitCode);
        }
    }

    function cycleMode() {
        var idx = modes.indexOf(mode);
        mode = modes[(idx + 1) % modes.length];
        _triggerPreview();
    }

    function preview() {
        if (!popupVisible || entries.length === 0) return;
        var path = entries[currentIndex].path;
        _applyWithMode(mode, path);
        _triggerMatugenPreview(path);
    }

    function applyRandom(modeArg) {
        _runCommand("random", modeArg || "fit");
    }

    // Internal: apply wallpaper with given mode
    function _applyWithMode(m, path) {
        switch (m) {
            case "span": _runCommand("span", path); break;
            case "dp1":  _runCommandArgs(["set-monitor", "DP-1", path]); break;
            case "dp2":  _runCommandArgs(["set-monitor", "DP-2", path]); break;
        }
    }

    function _runCommand(subcommand, arg) {
        // WALLPAPER_PREVIEW=1 tells wallpaper.sh to skip matugen + apply-theme.sh
        // (WallpaperPicker has its own preview pipeline via matugenPreviewProcess)
        applyProcess.command = ["env", "WALLPAPER_PREVIEW=1", scriptPath, subcommand, arg];
        applyProcess.running = true;
    }

    function _runCommandArgs(args) {
        applyProcess.command = ["env", "WALLPAPER_PREVIEW=1", scriptPath].concat(args);
        applyProcess.running = true;
    }

    // Debounced preview trigger
    function _triggerPreview() {
        previewTimer.restart();
    }

    onCurrentIndexChanged: {
        if (popupVisible) _triggerPreview();
    }

    property Timer previewTimer: Timer {
        interval: 400
        repeat: false
        onTriggered: root.preview()
    }

    // Save current wallpaper state for revert
    function _saveCurrentState() {
        stateReadProcess.running = true;
    }

    property Process stateReadProcess: Process {
        command: ["cat", (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/wallpaper/state"]
        stdout: SplitParser {
            onRead: data => {
                if (!root._stateLines) root._stateLines = [];
                root._stateLines.push(data.trim());
            }
        }
        onRunningChanged: {
            if (running) root._stateLines = [];
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && root._stateLines.length > 0) {
                root._savedState = root._stateLines;
            }
        }
    }

    property var _stateLines: []

    // Restore previous wallpaper
    property Process restoreProcess: Process {
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                console.warn("Wallpaper: restore failed with code", exitCode);
        }
    }

    // List images in wallpaper directory
    property Process listProcess: Process {
        command: ["find", root.wallpaperDir, "-maxdepth", "1", "-type", "f",
                  "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg",
                  "-o", "-iname", "*.png", "-o", "-iname", "*.webp", ")",
                  "-printf", "%f\\n"]
        stdout: SplitParser {
            onRead: data => {
                root._pendingEntries.push(data.trim());
            }
        }
        onRunningChanged: {
            if (running) {
                root._pendingEntries = [];
            }
        }
        onExited: (exitCode, exitStatus) => {
            root._pendingEntries.sort();
            let result = [];
            for (let i = 0; i < root._pendingEntries.length; i++) {
                const name = root._pendingEntries[i];
                if (name.length > 0) {
                    result.push({
                        name: name,
                        path: root.wallpaperDir + "/" + name
                    });
                }
            }
            root.entries = result;
            if (root.currentIndex >= result.length) {
                root.currentIndex = Math.max(0, result.length - 1);
            }
            // Preview the initial wallpaper after list loads
            if (root.popupVisible && result.length > 0) {
                root._triggerPreview();
            }
        }
    }

    property var _pendingEntries: []

    // Apply wallpaper (used by preview and direct calls)
    property Process applyProcess: Process {
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn("Wallpaper: wallpaper.sh exited with code", exitCode);
            }
        }
    }

    function refresh() {
        listProcess.running = true;
    }

    Component.onCompleted: {
        var self = root
        Modals.register("wallpaper", function() { return self.popupVisible }, function() { self.hidePopup() })
    }
}
