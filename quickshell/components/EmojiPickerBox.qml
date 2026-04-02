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
    showEmpty: Root.EmojiPicker.isSearching && itemsModel.values.length === 0 && !Root.EmojiPicker._searchTimer.running
    statusText: Root.EmojiPicker.isSearching
        ? (Root.EmojiPicker._searchTimer.running ? "Searching..." : itemsModel.values.length + " results")
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
