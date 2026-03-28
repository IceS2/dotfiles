import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import ".." as Root

Root.SearchModal {
    id: clipboardModal
    showing: Root.Clipboard.visible
    screen: Root.Clipboard.activeScreen
    layerNamespace: "quickshell-clipboard-box"
    boxWidth: Root.Theme.clipboardWidth
    boxHeight: Root.Theme.clipboardHeight
    rightPanelWidth: Root.Theme.clipboardPreviewWidth
    searchPlaceholder: "  Search clipboard..."
    searchQuery: Root.Clipboard.searchQuery
    listModel: filteredModel
    listCurrentIndex: Root.Clipboard.currentIndex
    emptyMessage: "Clipboard is empty"
    emptyIcon: "󰅇"
    showEmpty: true
    statusText: {
        var total = Root.Clipboard.entries.length
        var filtered = Root.Clipboard.filteredEntries.length
        if (total === 0) return ""
        if (filtered === total) return total + " entries"
        return filtered + " / " + total
    }

    onCloseRequested: Root.Clipboard.hide()
    onSearchChanged: (text) => { Root.Clipboard.searchQuery = text }
    onNavigateUp: {
        if (Root.Clipboard.navigateUp())
            listView.positionViewAtIndex(Root.Clipboard.currentIndex, ListView.Contain)
    }
    onNavigateDown: {
        if (Root.Clipboard.navigateDown())
            listView.positionViewAtIndex(Root.Clipboard.currentIndex, ListView.Contain)
    }
    onPageUp: {
        if (Root.Clipboard.pageUp())
            listView.positionViewAtIndex(Root.Clipboard.currentIndex, ListView.Contain)
    }
    onPageDown: {
        if (Root.Clipboard.pageDown())
            listView.positionViewAtIndex(Root.Clipboard.currentIndex, ListView.Contain)
    }
    onAccepted: {
        Root.Clipboard.selectEntry(Root.Clipboard.currentIndex)
    }

    delegate: Root.ClipboardItem {
        onHovered: Root.Clipboard.currentIndex = index
        onClicked: Root.Clipboard.selectEntry(index)
        onDeleteRequested: Root.Clipboard.deleteEntry(index)
    }

    rightPanel: [
        // Preview pane — text viewer or image preview
        Rectangle {
            anchors.fill: parent
            radius: Root.Theme.borderRadiusSmall
            color: Root.Theme.surfaceDimGlass

            // Image preview
            Image {
                id: imagePreview
                anchors.fill: parent
                anchors.margins: Root.Theme.paddingSmall
                visible: Root.Clipboard.previewIsImage && Root.Clipboard.previewImagePath !== ""
                source: Root.Clipboard.previewImagePath
                fillMode: Image.PreserveAspectFit
                cache: false
                asynchronous: true
            }

            // Text preview with line numbers
            Flickable {
                id: previewFlickable
                anchors.fill: parent
                anchors.margins: Root.Theme.paddingSmall
                visible: !Root.Clipboard.previewIsImage && Root.Clipboard.previewContent !== ""
                clip: true
                contentWidth: width
                contentHeight: previewColumn.height
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: Root.StyledScrollBar {
                    target: previewFlickable
                }

                property var lines: Root.Clipboard.previewContent ? Root.Clipboard.previewContent.split("\n") : []
                property int gutterWidth: lines.length >= 1000 ? 36 : (lines.length >= 100 ? 28 : 20)

                Column {
                    id: previewColumn
                    width: previewFlickable.width - 12

                    Repeater {
                        model: previewFlickable.lines

                        Row {
                            width: previewColumn.width
                            spacing: Root.Theme.spacingSmall

                            // Line number
                            Text {
                                text: index + 1
                                width: previewFlickable.gutterWidth
                                font.pixelSize: Root.Theme.fontSizeSmall
                                font.family: Root.Theme.fontFamilyMono
                                color: Root.Theme.outline
                                horizontalAlignment: Text.AlignRight
                                lineHeight: 1.4
                            }

                            // Separator
                            Rectangle {
                                width: 1
                                height: lineContent.height
                                color: Root.Theme.surfaceContainerHigh
                                opacity: 0.5
                            }

                            // Line content
                            Text {
                                id: lineContent
                                width: previewColumn.width - previewFlickable.gutterWidth - Root.Theme.spacingSmall * 2 - 1
                                text: modelData
                                font.pixelSize: Root.Theme.fontSizeSmall
                                font.family: Root.Theme.fontFamilyMono
                                color: Root.Theme.on.surface
                                wrapMode: Text.WrapAnywhere
                                lineHeight: 1.4
                            }
                        }
                    }
                }
            }

            // Empty state when no entry selected or loading
            Text {
                anchors.centerIn: parent
                visible: Root.Clipboard.previewContent === "" && Root.Clipboard.previewImagePath === ""
                text: "Select an entry\nto preview"
                font.pixelSize: Root.Theme.fontSizeNormal
                font.family: Root.Theme.fontFamily
                color: Root.Theme.outline
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 1.4
            }
        }
    ]

    ScriptModel {
        id: filteredModel
        values: Root.Clipboard.filteredEntries
    }
}
