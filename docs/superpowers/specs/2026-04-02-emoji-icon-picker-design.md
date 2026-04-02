# Emoji & Icon Picker — Design Spec

**Date:** 2026-04-02
**Status:** Approved

## Overview

A unified emoji and Nerd Font icon picker built on SearchModal. Hybrid display: grid layout for browsing categories, list layout for search results. Copy-and-close on selection via `wl-copy`. Keybind: `Super+E`.

## Data

Two static JSON files in `quickshell/data/`:

### emoji-data.json (~3500 entries)

```json
[
  {"char": "😀", "name": "grinning face", "keywords": ["happy", "smile"], "category": "Smileys", "type": "emoji"}
]
```

Generated from Unicode CLDR `emoji-test.txt`. Categories: Smileys, People, Animals, Food, Travel, Activities, Objects, Symbols, Flags.

### nerdfonts-data.json (~9000 entries)

```json
[
  {"char": "󰉋", "name": "folder", "keywords": ["directory", "dir"], "category": "Material Design", "type": "icon"}
]
```

Generated from the Nerd Fonts cheat sheet CSS/data. Categories map to icon sets: Material Design, Font Awesome, Devicons, Codicons, Weather, Octicons, Pomicons, Powerline, Seti.

### Loading

`FileView` reads both files at startup. Service merges into one `_allItems` array (emojis first, then icons). Category list derived from data.

## Service: EmojiPicker.qml

Singleton following the Launcher pattern.

### State

| Property | Type | Description |
|----------|------|-------------|
| `visible` | bool | Modal visibility |
| `searchQuery` | string | Current search text |
| `currentIndex` | int | Selected item index |
| `activeCategory` | string | Currently browsed category ("" = all) |
| `_emojiData` | var | Raw emoji array from JSON |
| `_iconData` | var | Raw icon array from JSON |
| `_allItems` | var | Merged array (emojis first) |
| `filteredItems` | var | Computed from query/category |
| `categories` | var | Derived `[{name, type, count}]` list |
| `_recents` | var | Last ~30 picked items |

### Browse Mode (empty query)

- Returns items filtered by `activeCategory`
- If no category selected, shows "Recent" pseudo-category (last 30 picks) then a sampled subset per category (first ~20 per category) to avoid dumping 12500 items
- Category can be set via `setCategory(name)` or by typing a category name in search

### Search Mode (has query)

- Fuzzy match across all items on `name` + `keywords` fields
- Results sorted by match score
- `activeCategory` filter ignored during search
- Uses existing `fuzzy.js` scoring

### Recents

- Track last ~30 picked items in `~/.cache/quickshell/emoji-history.json`
- Format: `[{"char": "🔥", "name": "fire", "type": "emoji"}, ...]`
- Updated on each `selectItem()`, deduplicated (most recent first)
- Shown as "Recent" pseudo-category at the top of browse mode

### API

- `toggle()`, `show()`, `hide()` — standard modal lifecycle, registered with `Modals.register()` for mutual exclusivity
- `selectItem(index)` — copies `char` via `wl-copy`, records in recents, hides picker
- `setCategory(name)` — switch browse category, resets currentIndex
- `navigateUp()`, `navigateDown()` — cursor movement

## SearchModal Extension: Grid Mode

New properties added to `components/SearchModal.qml`:

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `gridMode` | bool | false | Switches ListView to GridView |
| `gridCellWidth` | int | 44 | Cell width in grid mode |
| `gridCellHeight` | int | 44 | Cell height in grid mode |
| `gridDelegate` | Component | - | Delegate for grid cells |
| `gridView` | alias | - | Direct access to GridView |

When `gridMode` is true:
- GridView shown, ListView hidden
- Same `listModel` feeds both views
- `listCurrentIndex` syncs to `gridView.currentIndex`
- Keyboard nav (up/down) works on GridView (moves by row/column)
- Enter/accepted() triggers on current grid item
- ScrollBar attached to GridView
- Empty state shown when grid model is empty

When `gridMode` is false, behavior is identical to current SearchModal.

## UI: EmojiPickerBox.qml

SearchModal wrapper. Box size: 700x500. Layer namespace: `quickshell-emoji`.

### Hybrid Display

`gridMode` bound to `EmojiPicker.searchQuery === ""`:

- **Browse (grid):** Each cell is 44x44, character centered, hover highlight with surface color. Status text shows hovered item name + type. Category headers rendered as full-width section labels in the grid model.
- **Search (list):** Standard delegate per row — character (24px, left) + name (fill) + dim type label ("Emoji" / "Nerd Font", right-aligned, `on.surfaceVariant` color).

### Interaction

- Click or Enter: copies character, closes picker
- Escape or click outside: closes without action
- Typing: switches to search/list mode automatically
- Clearing search: returns to grid/browse mode

## Integration (shell.qml)

### Backdrop

```qml
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

### IPC Handler

```qml
IpcHandler {
    target: "emoji"
    enabled: true
    function toggle(): void { EmojiPicker.toggle() }
    function show(): void { EmojiPicker.show() }
    function hide(): void { EmojiPicker.hide() }
}
```

### Keybind

In `shell.qml`:
```qml
GlobalShortcut { name: "emoji_toggle"; onPressed: EmojiPicker.toggle() }
```

In `hypr/configs/keybinds.conf`:
```
bind = $mainMod, E, global, quickshell:emoji_toggle
```

### Layerrule (windowrules.conf)

```
layerrule = blur on, match:namespace quickshell-emoji
layerrule = ignore_alpha 0.05, match:namespace quickshell-emoji
```

## File Summary

| File | Action |
|------|--------|
| `quickshell/data/emoji-data.json` | New — static emoji dataset |
| `quickshell/data/nerdfonts-data.json` | New — static Nerd Font dataset |
| `quickshell/services/EmojiPicker.qml` | New — singleton service |
| `quickshell/components/SearchModal.qml` | Modify — add grid mode |
| `quickshell/components/EmojiPickerBox.qml` | New — SearchModal wrapper |
| `quickshell/components/EmojiGridItem.qml` | New — grid cell delegate |
| `quickshell/components/EmojiListItem.qml` | New — list row delegate |
| `quickshell/shell.qml` | Modify — add backdrop, box, IPC, shortcut |
| `quickshell/qmldir` | Modify — register new components |
| `hypr/configs/keybinds.conf` | Modify — add Super+E bind |
| `hypr/configs/windowrules.conf` | Modify — add blur layerrule |
| `scripts/generate-emoji-data.py` | New — one-time dataset generator (not part of runtime) |

## Data Generation (one-time scripts)

### Emoji

Parse Unicode `emoji-test.txt` (from unicode.org). Extract fully-qualified emoji, name, group (category). Map groups to short category names. Output `emoji-data.json`.

### Nerd Fonts

Parse Nerd Fonts CSS/glyphnames JSON (from nerd-fonts GitHub repo `css/nerd-fonts-generated.css` or `glyphnames.json`). Extract codepoint, name, set (category). Output `nerdfonts-data.json`.

Both scripts are development tools, not runtime dependencies. Committed to repo but not part of install.
