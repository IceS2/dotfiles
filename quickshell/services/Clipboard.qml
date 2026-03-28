pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "utils.js" as Utils
import "modals.js" as Modals

QtObject {
    id: root

    property string searchQuery: ""
    property int currentIndex: 0
    property bool visible: false
    property var activeScreen: null

    // XDG-compliant temp path for image previews
    readonly property string _previewTmpPath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/quickshell-clipboard-preview.png"

    // Clipboard entries: [{raw: "123\ttext", preview: "some text", isImage: false, imageInfo: ""}, ...]
    property var entries: []
    readonly property var filteredEntries: filterEntries(searchQuery, entries)

    // Preview for selected entry
    property string previewContent: ""
    property string previewImagePath: ""
    property bool previewIsImage: false
    property int _previewIndex: -1
    property var _previewBuffer: []

    // Monitor tracking
    property var _focusedMonitor: Hyprland.focusedMonitor
    on_FocusedMonitorChanged: {
        if (visible) activeScreen = findFocusedScreen()
    }

    // Temp buffer for collecting lines from listProcess
    property var _listBuffer: []

    // Process for listing clipboard entries
    property Process listProcess: Process {
        command: ["cliphist", "list"]

        stdout: SplitParser {
            onRead: data => {
                if (!data || data.trim() === "") return
                root._listBuffer.push(data)
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root._listBuffer = []
                return
            }
            var parsed = []
            for (var i = 0; i < root._listBuffer.length; i++) {
                var line = root._listBuffer[i]
                var tabIdx = line.indexOf("\t")
                if (tabIdx === -1) continue
                var preview = line.substring(tabIdx + 1)
                var isImage = /^\[\[.*binary data.*\]\]$/.test(preview)
                var imageInfo = ""
                if (isImage) {
                    var match = preview.match(/binary data (\d+\s*\w+)\s+(\w+)\s+(\d+x\d+)/)
                    if (match) imageInfo = match[2].toUpperCase() + " " + match[3] + " (" + match[1] + ")"
                    else imageInfo = "Image"
                }
                parsed.push({ raw: line, preview: preview, isImage: isImage, imageInfo: imageInfo })
            }
            root.entries = parsed
            root._listBuffer = []

            // Clamp currentIndex after list changes (e.g. after delete)
            if (root.currentIndex >= root.filteredEntries.length) {
                root.currentIndex = Math.max(0, root.filteredEntries.length - 1)
            }
            // Re-trigger preview for current index
            root.updatePreview(root.currentIndex)
        }
    }

    // Process for decoding text preview
    property Process previewTextProcess: Process {
        command: ["sh", "-c", ""]

        stdout: SplitParser {
            onRead: data => {
                root._previewBuffer.push(data)
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.previewContent = root._previewBuffer.join("\n")
            }
            root._previewBuffer = []
        }
    }

    // Process for decoding image preview to temp file
    property Process previewImageProcess: Process {
        command: ["sh", "-c", ""]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.previewImagePath = ""
                root.previewImagePath = "file://" + root._previewTmpPath
            }
        }
    }

    function _restartProcess(proc) {
        proc.running = false
        proc.running = true
    }

    function updatePreview(index) {
        if (index === _previewIndex) return
        _previewIndex = index
        previewContent = ""
        previewImagePath = ""
        previewIsImage = false
        if (index < 0 || index >= filteredEntries.length) return

        var entry = filteredEntries[index]
        previewIsImage = entry.isImage

        if (entry.isImage) {
            previewImageProcess.command = ["sh", "-c", "printf '%s' \"$1\" | cliphist decode > " + root._previewTmpPath, "sh", entry.raw]
            _restartProcess(previewImageProcess)
        } else {
            _previewBuffer = []
            previewTextProcess.command = ["sh", "-c", "printf '%s' \"$1\" | cliphist decode", "sh", entry.raw]
            _restartProcess(previewTextProcess)
        }
    }

    // Process for selecting (decoding + copying) an entry
    property Process selectProcess: Process {
        command: ["sh", "-c", ""]
        onExited: (exitCode, exitStatus) => {
            root.hide()
        }
    }

    // Process for deleting an entry
    property Process deleteProcess: Process {
        command: ["sh", "-c", ""]
        onExited: (exitCode, exitStatus) => {
            // Invalidate preview cache so it re-triggers after refresh
            root._previewIndex = -1
            root.refresh()
        }
    }

    // Process for wiping all entries
    property Process wipeProcess: Process {
        command: ["cliphist", "wipe"]
        onExited: (exitCode, exitStatus) => {
            root.entries = []
            root.currentIndex = 0
            root._previewIndex = -1
            root.previewContent = ""
            root.previewImagePath = ""
            root.previewIsImage = false
        }
    }

    function filterEntries(query, items) {
        if (query === "") return items

        var lowerQuery = query.toLowerCase()
        var results = []
        for (var i = 0; i < items.length; i++) {
            var entry = items[i]
            if (entry.preview.toLowerCase().includes(lowerQuery)) {
                results.push(entry)
            }
        }
        return results
    }

    function refresh() {
        _listBuffer = []
        _restartProcess(listProcess)
    }

    function selectEntry(index) {
        if (index < 0 || index >= filteredEntries.length) return
        var entry = filteredEntries[index]
        selectProcess.command = ["sh", "-c", "printf '%s' \"$1\" | cliphist decode | wl-copy", "sh", entry.raw]
        _restartProcess(selectProcess)
    }

    function deleteEntry(index) {
        if (index < 0 || index >= filteredEntries.length) return
        var entry = filteredEntries[index]
        deleteProcess.command = ["sh", "-c", "printf '%s' \"$1\" | cliphist delete", "sh", entry.raw]
        _restartProcess(deleteProcess)
    }

    function clearAll() {
        _restartProcess(wipeProcess)
    }

    function navigateDown() {
        var idx = Utils.listNext(currentIndex, filteredEntries.length)
        if (idx >= 0) { currentIndex = idx; return true }
        return false
    }

    function navigateUp() {
        var idx = Utils.listPrev(currentIndex)
        if (idx >= 0) { currentIndex = idx; return true }
        return false
    }

    function pageDown() {
        var idx = Utils.listPageDown(currentIndex, filteredEntries.length)
        if (idx >= 0) { currentIndex = idx; return true }
        return false
    }

    function pageUp() {
        var idx = Utils.listPageUp(currentIndex)
        if (idx >= 0) { currentIndex = idx; return true }
        return false
    }

    function resetSearch() {
        searchQuery = ""
        currentIndex = 0
    }

    function findFocusedScreen() {
        return Utils.findFocusedScreen(Hyprland, Quickshell, activeScreen)
    }

    function show() {
        activeScreen = findFocusedScreen()
        Modals.closeOthers("clipboard")
        refresh()
        visible = true
    }

    function hide() {
        visible = false
    }

    function toggle() {
        if (visible) hide()
        else show()
    }

    onCurrentIndexChanged: {
        updatePreview(currentIndex)
    }

    onSearchQueryChanged: {
        currentIndex = 0
    }

    onVisibleChanged: {
        if (!visible) {
            resetSearch()
            previewContent = ""
            previewImagePath = ""
            previewIsImage = false
            _previewIndex = -1
        }
    }

    Component.onCompleted: {
        var self = root
        Modals.register("clipboard", function() { return self.visible }, function() { self.hide() })
    }
}
