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

    readonly property var categories: {
        var cats = []
        var seen = {}
        if (_recents.length > 0) cats.push({ name: "Recent", type: "recent", count: _recents.length })
        for (var i = 0; i < _allItems.length; i++) {
            var item = _allItems[i]
            if (!seen[item.category]) {
                seen[item.category] = true
                cats.push({ name: item.category, type: item.type, count: 0 })
            }
            for (var j = 1; j < cats.length; j++) {
                if (cats[j].name === item.category) { cats[j].count++; break }
            }
        }
        return cats
    }

    readonly property var filteredItems: {
        if (isSearching) return _searchItems(searchQuery)
        if (activeCategory === "Recent") return _recents
        if (activeCategory !== "") return _categoryItems(activeCategory)
        return _browseItems()
    }

    // ─── Search ───
    function _searchItems(query) {
        var lq = query.toLowerCase()
        var results = []
        for (var i = 0; i < _allItems.length; i++) {
            var item = _allItems[i]
            var nameResult = Fuzzy.fuzzyScore(lq, item.name)
            var score = nameResult.score
            for (var k = 0; k < item.keywords.length; k++) {
                var kwResult = Fuzzy.fuzzyScore(lq, item.keywords[k])
                if (kwResult.score > score) score = kwResult.score
            }
            if (score > 0) results.push({ item: item, score: score })
        }
        results.sort(function(a, b) { return b.score - a.score })
        return results.map(function(r) { return r.item })
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
            if (cats[item.category] < 40) {
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
