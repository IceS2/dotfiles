pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "utils.js" as Utils
import "fuzzy.js" as Fuzzy
import "modals.js" as Modals

QtObject {
    id: root

    property string searchQuery: ""
    property int currentIndex: 0
    property bool visible: false
    property var activeScreen: null

    // Move launcher box to whichever monitor is focused
    property var _focusedMonitor: Hyprland.focusedMonitor
    on_FocusedMonitorChanged: {
        if (visible) activeScreen = findFocusedScreen()
    }

    readonly property var allApps: DesktopEntries.applications.values
    readonly property var filteredApps: filterApplications(searchQuery, allApps)

    // ─── Frecency history ───
    property var _history: ({})
    property string _historyPath: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/quickshell/launcher-history.json"

    property Process _mkdirProc: Process {
        running: true
        command: ["mkdir", "-p", (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/quickshell"]
    }

    property FileView _historyFile: FileView {
        path: root._historyPath
        blockLoading: false
        watchChanges: false
        preload: false
    }

    property Timer _saveTimer: Timer {
        interval: 2000
        onTriggered: {
            root._historyFile.setText(JSON.stringify(root._history))
        }
    }

    property Process _loadProc: Process {
        running: true
        command: ["cat", root._historyPath]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    var parsed = JSON.parse(data)
                    if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
                        root._history = parsed
                    }
                } catch (e) {
                    // No history file yet or corrupt — start fresh
                }
            }
        }
    }

    function _recordLaunch(appId) {
        var h = Object.assign({}, _history)
        var entry = h[appId] || { count: 0, lastLaunched: 0 }
        entry.count = (entry.count || 0) + 1
        entry.lastLaunched = Date.now()
        h[appId] = entry
        _history = h
        _saveTimer.restart()
    }

    function _getFrecency(appId) {
        var entry = _history[appId]
        if (!entry || !entry.count) return 0
        return Fuzzy.frecencyScore(entry.count, entry.lastLaunched)
    }

    // ─── Fuzzy search + scoring ───
    function filterApplications(query, apps) {
        if (!apps || apps.length === 0) return []

        if (query === "") {
            // Empty query: sort by frecency (most-used first), then alphabetical
            var sorted = []
            for (var i = 0; i < apps.length; i++) sorted.push(apps[i])

            sorted.sort(function(a, b) {
                var fa = _getFrecency(a.id)
                var fb = _getFrecency(b.id)
                if (fa !== fb) return fb - fa // higher frecency first
                return (a.name || "").localeCompare(b.name || "")
            })
            return sorted
        }

        var lowerQuery = query.toLowerCase()
        var results = []

        for (var j = 0; j < apps.length; j++) {
            var app = apps[j]

            // Score against name (primary), description, id — take best
            var nameResult = Fuzzy.fuzzyScore(lowerQuery, app.name || "")
            var descResult = Fuzzy.fuzzyScore(lowerQuery, app.description || "")
            var idResult = Fuzzy.fuzzyScore(lowerQuery, app.id || "")

            var bestScore = nameResult.score
            if (descResult.score > bestScore) bestScore = descResult.score
            if (idResult.score > bestScore) bestScore = idResult.score

            if (bestScore <= 0) continue

            // Frecency boost
            var frecency = _getFrecency(app.id)
            var totalScore = bestScore + (frecency > 0 ? Math.log(frecency + 1) * 10 : 0)

            results.push({
                app: app,
                score: totalScore,
                matches: nameResult.matches
            })
        }

        // Sort by score descending
        results.sort(function(a, b) { return b.score - a.score })

        // Return just the app objects
        var out = []
        for (var k = 0; k < results.length; k++) out.push(results[k].app)
        return out
    }

    function launchApp(app) {
        _recordLaunch(app.id)
        if (app.runInTerminal) {
            Quickshell.execDetached(["kitty", "-e"].concat(app.command))
        } else {
            app.execute()
        }
    }

    function navigateDown() {
        var idx = Utils.listNext(currentIndex, filteredApps.length)
        if (idx >= 0) { currentIndex = idx; return true }
        return false
    }

    function navigateUp() {
        var idx = Utils.listPrev(currentIndex)
        if (idx >= 0) { currentIndex = idx; return true }
        return false
    }

    function pageDown() {
        var idx = Utils.listPageDown(currentIndex, filteredApps.length)
        if (idx >= 0) { currentIndex = idx; return true }
        return false
    }

    function pageUp() {
        var idx = Utils.listPageUp(currentIndex)
        if (idx >= 0) { currentIndex = idx; return true }
        return false
    }

    function launchSelected() {
        if (currentIndex >= 0 && currentIndex < filteredApps.length) {
            launchApp(filteredApps[currentIndex])
            return true
        }
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
        Modals.closeOthers("launcher")
        visible = true
    }

    function hide() {
        visible = false
    }

    function toggle() {
        if (visible) hide()
        else show()
    }

    onSearchQueryChanged: {
        currentIndex = 0
    }

    onVisibleChanged: {
        if (!visible) {
            resetSearch()
        }
    }

    Component.onCompleted: {
        var self = root
        Modals.register("launcher", function() { return self.visible }, function() { self.hide() })
    }
}
