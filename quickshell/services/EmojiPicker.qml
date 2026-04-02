pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "fuzzy.js" as Fuzzy
import "modals.js" as Modals

QtObject {
    id: root

    // ─── Public State ───
    property bool visible: false
    property string searchQuery: ""
    property int currentIndex: 0
    property string activeCategory: ""
    property string hoveredName: ""

    // ─── Data ───
    property var _emojiData: []
    property var _iconData: []
    property var _allItems: []
    property var _recents: []

    readonly property string _cacheDir: Quickshell.env("HOME") + "/.cache/quickshell"
    readonly property string _historyPath: _cacheDir + "/emoji-history.json"
    readonly property string _dataDir: Qt.resolvedUrl(".").toString().replace("file://", "").replace("/services/", "/data/")

    // ─── Computed ───
    readonly property bool isSearching: searchQuery.length > 0

    // Search results are decoupled from binding — populated by debounced timer
    property var _searchResults: []

    readonly property var filteredItems: {
        if (isSearching) return _searchResults
        if (activeCategory === "Recent") return _recents
        if (activeCategory !== "") return _categoryItems(activeCategory)
        return _browseItems()
    }

    // ─── Search (debounced, substring first then fuzzy fallback) ───
    property Timer _searchTimer: Timer {
        interval: 150
        onTriggered: root._runSearch()
    }

    function _runSearch() {
        var query = searchQuery
        if (query.length === 0) { _searchResults = []; return }
        var lq = query.toLowerCase()
        var nameStarts = []
        var nameContains = []
        var kwMatch = []
        var fuzzyPool = []
        var items = _allItems
        var len = items.length
        // Pass 1: fast substring matching
        for (var i = 0; i < len; i++) {
            var item = items[i]
            var name = item.name
            var idx = name.indexOf(lq)
            if (idx === 0) {
                nameStarts.push(item)
            } else if (idx > 0) {
                nameContains.push(item)
            } else {
                var kws = item.keywords
                var kwHit = false
                for (var k = 0, kl = kws.length; k < kl; k++) {
                    if (kws[k].indexOf(lq) >= 0) { kwMatch.push(item); kwHit = true; break }
                }
                if (!kwHit) fuzzyPool.push(item)
            }
        }
        var results = nameStarts.concat(nameContains, kwMatch)
        // Pass 2: fuzzy only if substring gave < 50 results and query is 2+ chars
        if (results.length < 50 && lq.length >= 2) {
            var fuzzyResults = []
            var limit = Math.min(fuzzyPool.length, 3000)
            for (var f = 0; f < limit; f++) {
                var fi = fuzzyPool[f]
                var score = Fuzzy.fuzzyScore(lq, fi.name).score
                if (score > 0) fuzzyResults.push({ item: fi, score: score })
            }
            fuzzyResults.sort(function(a, b) { return b.score - a.score })
            var cap = 200 - results.length
            for (var r = 0; r < fuzzyResults.length && r < cap; r++) {
                results.push(fuzzyResults[r].item)
            }
        }
        if (results.length > 200) results.length = 200
        _searchResults = results
    }

    function _categoryItems(category) {
        return _allItems.filter(function(item) { return item.category === category })
    }

    function _browseItems() {
        var items = _recents.slice()
        var seen = {}
        for (var i = 0; i < _recents.length; i++) seen[_recents[i].char] = true
        var cats = {}
        for (var j = 0; j < _allItems.length; j++) {
            var item = _allItems[j]
            if (seen[item.char]) continue
            if (!cats[item.category]) cats[item.category] = 0
            if (cats[item.category] < 20) {
                items.push(item)
                cats[item.category]++
            }
        }
        return items
    }

    // ─── Actions ───
    function selectItem(index) {
        var items = filteredItems
        if (index < 0 || index >= items.length) return
        var item = items[index]
        _copyProcess.command = ["wl-copy", item.char]
        _copyProcess.running = true
        _addRecent(item)
        hide()
    }

    function setCategory(name) {
        activeCategory = name
        currentIndex = 0
    }

    function navigateUp() {
        if (currentIndex > 0) currentIndex--
        return currentIndex
    }

    function navigateDown() {
        if (currentIndex < filteredItems.length - 1) currentIndex++
        return currentIndex
    }

    function show() {
        Modals.closeOthers("emoji")
        visible = true
    }

    function hide() {
        visible = false
    }

    function toggle() {
        if (visible) hide()
        else show()
    }

    // ─── Reset on hide ───
    onVisibleChanged: {
        if (!visible) {
            searchQuery = ""
            currentIndex = 0
            activeCategory = ""
            hoveredName = ""
        }
    }

    onSearchQueryChanged: {
        currentIndex = 0
        if (searchQuery.length > 0)
            _searchTimer.restart()
        else
            _searchResults = []
    }

    // ─── Recents ───
    function _addRecent(item) {
        var newRecents = _recents.filter(function(r) { return r.char !== item.char })
        newRecents.unshift({ char: item.char, name: item.name, keywords: item.keywords || [], category: item.category, type: item.type })
        if (newRecents.length > 30) newRecents = newRecents.slice(0, 30)
        _recents = newRecents
        _saveTimer.restart()
    }

    // ─── Processes ───
    property Process _copyProcess: Process {}

    property Timer _saveTimer: Timer {
        interval: 2000
        onTriggered: {
            _historyFile.setText(JSON.stringify(root._recents))
        }
    }

    property FileView _historyFile: FileView {
        path: Qt.resolvedUrl("file://" + root._historyPath)
    }

    // ─── Data Loading ───
    property FileView _emojiFile: FileView {
        path: Qt.resolvedUrl("file://" + root._dataDir + "/emoji-data.json")
        onTextChanged: {
            var t = _emojiFile.text()
            if (t && t.length > 0) {
                try {
                    root._emojiData = JSON.parse(t)
                    root._rebuildAll()
                } catch (e) {
                    console.warn("EmojiPicker: failed to parse emoji-data.json:", e)
                }
            }
        }
    }

    property FileView _iconFile: FileView {
        path: Qt.resolvedUrl("file://" + root._dataDir + "/nerdfonts-data.json")
        onTextChanged: {
            var t = _iconFile.text()
            if (t && t.length > 0) {
                try {
                    root._iconData = JSON.parse(t)
                    root._rebuildAll()
                } catch (e) {
                    console.warn("EmojiPicker: failed to parse nerdfonts-data.json:", e)
                }
            }
        }
    }

    function _rebuildAll() {
        _allItems = _emojiData.concat(_iconData)
    }

    // ─── History Loading ───
    property Process _loadHistoryProcess: Process {
        command: ["cat", root._historyPath]
        stdout: SplitParser {
            onRead: data => {
                try {
                    root._recents = JSON.parse(data)
                } catch (e) {
                    root._recents = []
                }
            }
        }
    }

    // ─── Lifecycle ───
    Component.onCompleted: {
        var self = root
        Modals.register("emoji", function() { return self.visible }, function() { self.hide() })
        _loadHistoryProcess.running = true
    }
}
