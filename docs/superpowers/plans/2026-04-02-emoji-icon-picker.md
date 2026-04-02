# Emoji & Icon Picker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a unified emoji and Nerd Font icon picker as a SearchModal-based component with hybrid grid/list display.

**Architecture:** Static JSON datasets loaded at startup, singleton service for state/filtering, SearchModal extended with grid mode, copy-and-close via wl-copy. Follows existing Launcher/Clipboard patterns exactly.

**Tech Stack:** QML/QuickShell, Python (one-time data generation), wl-copy (clipboard)

**Spec:** `docs/superpowers/specs/2026-04-02-emoji-icon-picker-design.md`

---

### Task 1: Generate Emoji Dataset

**Files:**
- Create: `scripts/generate-emoji-data.py`
- Create: `quickshell/data/emoji-data.json`

- [ ] **Step 1: Create the data directory**

```bash
mkdir -p /home/ice/.dotfiles/quickshell/data
```

- [ ] **Step 2: Write the emoji data generator**

Create `scripts/generate-emoji-data.py`:

```python
#!/usr/bin/env python3
"""Generate emoji-data.json from Unicode emoji-test.txt."""

import json
import sys
import urllib.request

URL = "https://unicode.org/Public/emoji/16.0/emoji-test.txt"

# Map Unicode group names to short category names
GROUP_MAP = {
    "Smileys & Emotion": "Smileys",
    "People & Body": "People",
    "Animals & Nature": "Animals",
    "Food & Drink": "Food",
    "Travel & Places": "Travel",
    "Activities": "Activities",
    "Objects": "Objects",
    "Symbols": "Symbols",
    "Flags": "Flags",
    "Component": None,  # skip skin tones, hair components
}


def parse_emoji_test(text):
    entries = []
    current_group = None

    for line in text.splitlines():
        line = line.strip()

        if line.startswith("# group:"):
            current_group = line.split(":", 1)[1].strip()
            continue

        if not line or line.startswith("#"):
            continue

        # Format: codepoints ; status # emoji name
        if ";" not in line:
            continue

        parts = line.split(";", 1)
        rest = parts[1].strip()

        # Only include fully-qualified emoji
        if not rest.startswith("fully-qualified"):
            continue

        # Extract emoji character and name from comment
        comment_idx = rest.find("#")
        if comment_idx == -1:
            continue

        comment = rest[comment_idx + 1:].strip()
        # Comment format: "emoji E14.0 name"
        # Split on first space after version
        emoji_char = comment.split(" ")[0]
        version_and_name = comment[len(emoji_char):].strip()
        # Skip version (E14.0, E15.1, etc.)
        name_parts = version_and_name.split(" ", 1)
        if len(name_parts) < 2:
            continue
        name = name_parts[1].strip()

        category = GROUP_MAP.get(current_group)
        if category is None:
            continue

        # Generate keywords from name (split on spaces, colons)
        keywords = [w.lower() for w in name.replace(":", " ").split() if len(w) > 1]

        entries.append({
            "char": emoji_char,
            "name": name.lower(),
            "keywords": keywords,
            "category": category,
            "type": "emoji",
        })

    return entries


def main():
    print("Downloading emoji-test.txt...", file=sys.stderr)
    with urllib.request.urlopen(URL) as resp:
        text = resp.read().decode("utf-8")

    entries = parse_emoji_test(text)
    print(f"Parsed {len(entries)} emoji entries", file=sys.stderr)

    outpath = "quickshell/data/emoji-data.json"
    with open(outpath, "w") as f:
        json.dump(entries, f, ensure_ascii=False, separators=(",", ":"))
    print(f"Wrote {outpath}", file=sys.stderr)


if __name__ == "__main__":
    main()
```

- [ ] **Step 3: Run the generator**

```bash
cd /home/ice/.dotfiles
python3 scripts/generate-emoji-data.py
```

Expected: `quickshell/data/emoji-data.json` created with ~3500 entries.

- [ ] **Step 4: Verify the data**

```bash
python3 -c "import json; d=json.load(open('quickshell/data/emoji-data.json')); print(f'{len(d)} entries'); print(json.dumps(d[0], ensure_ascii=False)); print(set(e['category'] for e in d))"
```

Expected: entry count ~3500, first entry is a smiley, categories include Smileys/People/Animals/etc.

- [ ] **Step 5: Commit**

```bash
git add scripts/generate-emoji-data.py quickshell/data/emoji-data.json
git commit -m "feat(emoji-picker): generate emoji dataset from Unicode emoji-test.txt"
```

---

### Task 2: Generate Nerd Fonts Dataset

**Files:**
- Create: `scripts/generate-nerdfonts-data.py`
- Create: `quickshell/data/nerdfonts-data.json`

- [ ] **Step 1: Write the Nerd Fonts data generator**

Create `scripts/generate-nerdfonts-data.py`:

```python
#!/usr/bin/env python3
"""Generate nerdfonts-data.json from Nerd Fonts glyphnames.json."""

import json
import sys
import urllib.request

URL = "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/glyphnames.json"

# Map nerd font prefix to readable category
PREFIX_MAP = {
    "nf-md-": "Material Design",
    "nf-fa-": "Font Awesome",
    "nf-dev-": "Devicons",
    "nf-cod-": "Codicons",
    "nf-weather-": "Weather",
    "nf-oct-": "Octicons",
    "nf-pom-": "Pomicons",
    "nf-pl-": "Powerline",
    "nf-ple-": "Powerline Extra",
    "nf-seti-": "Seti",
    "nf-custom-": "Custom",
    "nf-iec-": "IEC Power",
    "nf-linux-": "Linux",
    "nf-fae-": "Font Awesome Ext",
    "nf-indent-": "Indentation",
}


def get_category(name):
    for prefix, category in PREFIX_MAP.items():
        if name.startswith(prefix):
            return category, name[len(prefix):]
    return "Other", name


def main():
    print("Downloading glyphnames.json...", file=sys.stderr)
    with urllib.request.urlopen(URL) as resp:
        data = json.loads(resp.read().decode("utf-8"))

    entries = []
    for name, info in data.items():
        if name in ("METADATA",):
            continue

        code = info.get("code")
        if not code:
            continue

        try:
            char = chr(int(code, 16))
        except (ValueError, OverflowError):
            continue

        category, short_name = get_category(name)
        # Convert dashes/underscores to spaces for search
        readable = short_name.replace("-", " ").replace("_", " ")
        keywords = [w.lower() for w in readable.split() if len(w) > 1]

        entries.append({
            "char": char,
            "name": readable.lower(),
            "keywords": keywords,
            "category": category,
            "type": "icon",
        })

    # Sort by category then name
    entries.sort(key=lambda e: (e["category"], e["name"]))
    print(f"Parsed {len(entries)} icon entries", file=sys.stderr)

    outpath = "quickshell/data/nerdfonts-data.json"
    with open(outpath, "w") as f:
        json.dump(entries, f, ensure_ascii=False, separators=(",", ":"))
    print(f"Wrote {outpath}", file=sys.stderr)


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Run the generator**

```bash
cd /home/ice/.dotfiles
python3 scripts/generate-nerdfonts-data.py
```

Expected: `quickshell/data/nerdfonts-data.json` created with ~5000-9000 entries.

- [ ] **Step 3: Verify the data**

```bash
python3 -c "import json; d=json.load(open('quickshell/data/nerdfonts-data.json')); print(f'{len(d)} entries'); print(json.dumps(d[0], ensure_ascii=False)); print(set(e['category'] for e in d))"
```

Expected: entries count, first entry has a char/name/category, categories include Material Design/Font Awesome/etc.

- [ ] **Step 4: Commit**

```bash
git add scripts/generate-nerdfonts-data.py quickshell/data/nerdfonts-data.json
git commit -m "feat(emoji-picker): generate Nerd Fonts dataset from glyphnames.json"
```

---

### Task 3: Extend SearchModal with Grid Mode

**Files:**
- Modify: `quickshell/components/SearchModal.qml`

- [ ] **Step 1: Add grid mode properties**

In `SearchModal.qml`, after line 34 (`property int rightPanelWidth: 0`), add:

```qml
    // Grid mode — shows GridView instead of ListView
    property bool gridMode: false
    property int gridCellWidth: 44
    property int gridCellHeight: 44
    property alias gridDelegate: gridView.delegate
    readonly property alias gridView: gridView
```

- [ ] **Step 2: Add GridView alongside ListView**

In `SearchModal.qml`, inside the list area `Item` (the one containing `ListView`), after the `ListView` closing brace (after line 232) and before the `EmptyState` (line 234), add:

```qml
                    GridView {
                        id: gridView
                        anchors.fill: parent
                        clip: true
                        visible: modal.gridMode && count > 0

                        model: modal.listModel
                        cellWidth: modal.gridCellWidth
                        cellHeight: modal.gridCellHeight

                        onCurrentIndexChanged: {
                            if (currentIndex === -1 && count > 0)
                                currentIndex = modal.listCurrentIndex
                        }

                        Connections {
                            target: modal
                            function onListCurrentIndexChanged() {
                                if (modal.gridMode)
                                    gridView.currentIndex = modal.listCurrentIndex
                            }
                        }
                        Component.onCompleted: currentIndex = modal.listCurrentIndex

                        ScrollBar.vertical: Root.StyledScrollBar {
                            target: gridView
                        }
                    }
```

- [ ] **Step 3: Hide ListView when in grid mode**

Change the ListView `visible` property (line 210) from:

```qml
                        visible: count > 0
```

to:

```qml
                        visible: !modal.gridMode && count > 0
```

- [ ] **Step 4: Update EmptyState to check both views**

Change the EmptyState `visible` (line 235) from:

```qml
                    Root.EmptyState {
                        visible: listView.count === 0 && modal.showEmpty
```

to:

```qml
                    Root.EmptyState {
                        visible: (modal.gridMode ? gridView.count === 0 : listView.count === 0) && modal.showEmpty
```

- [ ] **Step 5: Update keyboard nav to route to GridView when in grid mode**

In the `handleKeyPress` function (line 65), update the Down/Up/PageDown/PageUp handlers to emit the same signals. The signals themselves don't change — the caller (EmojiPickerBox) will route them to the correct view. No change needed here since the signals are generic.

However, update the `navigateDown`/`navigateUp` signal handlers to work with GridView in callers. SearchModal itself just emits signals — this is correct already.

- [ ] **Step 6: Commit**

```bash
git add quickshell/components/SearchModal.qml
git commit -m "feat(search-modal): add grid mode with GridView support"
```

---

### Task 4: Create EmojiPicker Service

**Files:**
- Create: `quickshell/services/EmojiPicker.qml`

- [ ] **Step 1: Create the service**

Create `quickshell/services/EmojiPicker.qml`:

```qml
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
            // Also check keywords
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
        // Recents first, then sample from each category
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
        // Remove if already exists
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
```

- [ ] **Step 2: Register in qmldir**

Add to `quickshell/qmldir` in the singletons section:

```
singleton EmojiPicker 1.0 services/EmojiPicker.qml
```

- [ ] **Step 3: Commit**

```bash
git add quickshell/services/EmojiPicker.qml quickshell/qmldir
git commit -m "feat(emoji-picker): add EmojiPicker singleton service"
```

---

### Task 5: Create EmojiPickerBox UI Component

**Files:**
- Create: `quickshell/components/EmojiPickerBox.qml`

- [ ] **Step 1: Create the box component**

Create `quickshell/components/EmojiPickerBox.qml`:

```qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import ".." as Root

Root.SearchModal {
    id: emojiBox

    showing: Root.EmojiPicker.visible
    layerNamespace: "quickshell-emoji"
    boxWidth: 700
    boxHeight: 500
    searchPlaceholder: "Search emoji & icons..."
    searchQuery: Root.EmojiPicker.searchQuery
    listModel: itemsModel
    listCurrentIndex: Root.EmojiPicker.currentIndex
    emptyMessage: "No matches"
    emptyIcon: "󰱨"
    showEmpty: Root.EmojiPicker.isSearching
    statusText: Root.EmojiPicker.isSearching
        ? (itemsModel.values.length + " results")
        : (Root.EmojiPicker.hoveredName || Root.EmojiPicker.activeCategory || "Browse")

    // Hybrid mode: grid for browse, list for search
    gridMode: !Root.EmojiPicker.isSearching
    gridCellWidth: 44
    gridCellHeight: 44

    // ─── Hover lock (prevent mouse from changing selection on open/search) ───
    property bool _hoverLock: false
    property Timer _hoverLockTimer: Timer {
        interval: 150
        onTriggered: emojiBox._hoverLock = false
    }

    onShowingChanged: {
        if (showing) {
            _hoverLock = true
            _hoverLockTimer.restart()
        }
    }

    // ─── Signal Handlers ───
    onCloseRequested: Root.EmojiPicker.hide()

    onSearchChanged: (text) => {
        Root.EmojiPicker.searchQuery = text
        _hoverLock = true
        _hoverLockTimer.restart()
    }

    onNavigateUp: {
        Root.EmojiPicker.navigateUp()
        if (Root.EmojiPicker.isSearching)
            listView.positionViewAtIndex(Root.EmojiPicker.currentIndex, ListView.Contain)
        else
            gridView.positionViewAtIndex(Root.EmojiPicker.currentIndex, GridView.Contain)
    }

    onNavigateDown: {
        Root.EmojiPicker.navigateDown()
        if (Root.EmojiPicker.isSearching)
            listView.positionViewAtIndex(Root.EmojiPicker.currentIndex, ListView.Contain)
        else
            gridView.positionViewAtIndex(Root.EmojiPicker.currentIndex, GridView.Contain)
    }

    onAccepted: Root.EmojiPicker.selectItem(Root.EmojiPicker.currentIndex)

    // ─── Grid Delegate (browse mode) ───
    gridDelegate: Item {
        required property var modelData
        required property int index

        width: emojiBox.gridCellWidth
        height: emojiBox.gridCellHeight

        property bool isSelected: GridView.isCurrentItem

        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: Root.Theme.borderRadiusSmall
            color: isSelected ? Root.Theme.surfaceContainerHigh
                : cellMouse.containsMouse ? Root.Theme.surfaceContainer
                : "transparent"

            Behavior on color { Root.CAnim {} }

            Text {
                anchors.centerIn: parent
                text: modelData.char
                font.pixelSize: modelData.type === "emoji" ? 22 : 20
                font.family: modelData.type === "icon" ? Root.Theme.fontFamily : undefined
                color: modelData.type === "icon" ? Root.Theme.on.surface : undefined
            }

            MouseArea {
                id: cellMouse
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    if (!emojiBox._hoverLock) {
                        Root.EmojiPicker.currentIndex = index
                        Root.EmojiPicker.hoveredName = modelData.name
                            + (modelData.type === "icon" ? "  (Nerd Font)" : "  (Emoji)")
                    }
                }
                onExited: Root.EmojiPicker.hoveredName = ""
                onClicked: Root.EmojiPicker.selectItem(index)
            }
        }
    }

    // ─── List Delegate (search mode) ───
    delegate: Root.ListItem {
        required property var modelData
        required property int index

        onHovered: if (!emojiBox._hoverLock) Root.EmojiPicker.currentIndex = index
        onClicked: Root.EmojiPicker.selectItem(index)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Root.Theme.paddingMedium
            anchors.rightMargin: Root.Theme.paddingMedium
            spacing: Root.Theme.spacingMedium

            Text {
                text: modelData.char
                font.pixelSize: modelData.type === "emoji" ? 22 : 20
                font.family: modelData.type === "icon" ? Root.Theme.fontFamily : undefined
                color: modelData.type === "icon" ? Root.Theme.on.surface : undefined
                Layout.preferredWidth: 32
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                text: modelData.name
                font.pixelSize: Root.Theme.fontSizeNormal
                font.family: Root.Theme.fontFamily
                color: Root.Theme.on.surface
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: modelData.type === "icon" ? "Nerd Font" : "Emoji"
                font.pixelSize: Root.Theme.fontSizeSmall
                font.family: Root.Theme.fontFamily
                color: Root.Theme.on.surfaceVariant
            }
        }
    }

    // ─── Model ───
    ScriptModel {
        id: itemsModel
        values: Root.EmojiPicker.filteredItems
    }
}
```

- [ ] **Step 2: Register in qmldir**

Add to `quickshell/qmldir` in the components section:

```
EmojiPickerBox 1.0 components/EmojiPickerBox.qml
```

- [ ] **Step 3: Commit**

```bash
git add quickshell/components/EmojiPickerBox.qml quickshell/qmldir
git commit -m "feat(emoji-picker): add EmojiPickerBox component with hybrid grid/list"
```

---

### Task 6: Integrate into Shell

**Files:**
- Modify: `quickshell/shell.qml`
- Modify: `hypr/configs/keybinds.conf`
- Modify: `hypr/configs/windowrules.conf`

- [ ] **Step 1: Add GlobalShortcut**

In `shell.qml`, after the existing GlobalShortcut entries (around line 22), add:

```qml
    GlobalShortcut { name: "emoji_toggle"; onPressed: EmojiPicker.toggle() }
```

- [ ] **Step 2: Add Backdrop + Box**

In `shell.qml`, after the Clipboard Backdrop+Box section (after line 180 `ClipboardBox {}`), add:

```qml
    // Emoji picker - Backdrop on all monitors + Box (focused input)
    Variants {
        model: Quickshell.screens

        Backdrop {
            required property var modelData
            screenObj: modelData
            showing: EmojiPicker.visible
            layerNamespace: "quickshell-emoji-backdrop"
            onCloseRequested: EmojiPicker.hide()
        }
    }
    EmojiPickerBox {}
```

- [ ] **Step 3: Add IPC handler**

In `shell.qml`, after the emoji backdrop/box section, add:

```qml
    IpcHandler {
        target: "emoji"
        enabled: true

        function toggle(): void {
            EmojiPicker.toggle()
        }

        function show(): void {
            EmojiPicker.show()
        }

        function hide(): void {
            EmojiPicker.hide()
        }
    }
```

- [ ] **Step 4: Add Hyprland keybind**

In `hypr/configs/keybinds.conf`, add with the other global shortcuts:

```
bind = $mainMod, E, global, quickshell:emoji_toggle
```

- [ ] **Step 5: Add layerrule**

In `hypr/configs/windowrules.conf`, add with the other QuickShell rules:

```
# QuickShell Emoji Picker
layerrule = blur on, match:namespace quickshell-emoji
layerrule = ignore_alpha 0.05, match:namespace quickshell-emoji
```

- [ ] **Step 6: Commit**

```bash
git add quickshell/shell.qml hypr/configs/keybinds.conf hypr/configs/windowrules.conf
git commit -m "feat(emoji-picker): integrate into shell with keybind, IPC, and blur"
```

---

### Task 7: Test and Polish

- [ ] **Step 1: Reload QuickShell**

```bash
qs ipc call shell reload
```

- [ ] **Step 2: Test keybind**

Press `Super+E`. Expected: emoji picker opens with grid of emoji/icons. Status bar shows "Browse".

- [ ] **Step 3: Test search**

Type "fire". Expected: switches to list mode showing fire-related emoji and icons with type labels.

- [ ] **Step 4: Test selection**

Click or press Enter on an item. Expected: character copied to clipboard, picker closes. Verify with `wl-paste`.

- [ ] **Step 5: Test recents**

Reopen picker (`Super+E`). Expected: recently picked items appear first in browse grid.

- [ ] **Step 6: Test IPC**

```bash
qs ipc call emoji toggle
```

Expected: picker toggles open/closed.

- [ ] **Step 7: Test mutual exclusivity**

Open launcher (`Super+Space`), then press `Super+E`. Expected: launcher closes, emoji picker opens.

- [ ] **Step 8: Fix any issues found during testing**

Address any visual or behavioral issues. Common things to check:
- Grid cell sizing and alignment
- Emoji rendering (font fallback working)
- Icon rendering (Nerd Font glyphs showing correctly)
- Scroll behavior in grid mode
- Keyboard navigation in grid mode (left/right vs up/down)

- [ ] **Step 9: Commit final state**

```bash
git add -A
git commit -m "feat(emoji-picker): polish and fixes after testing"
```

---

### Task 8: Update Documentation

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Update CLAUDE.md**

In the "Someday / Maybe" section, move emoji picker to completed:
- Remove: `Emoji picker (QuickShell SearchModal-based)` from Someday/Maybe
- Add to the completed component migration list:
  `- **Emoji picker → QuickShell SearchModal:** ✅ Unified emoji + Nerd Font icon picker (grid browse, list search, Super+E)`

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: mark emoji/icon picker as complete"
```
