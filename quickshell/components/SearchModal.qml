import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".." as Root

PanelWindow {
    id: modal
    visible: showing

    // === Public API ===
    property bool showing: false
    property string layerNamespace: ""
    property int boxWidth: Root.Theme.launcherWidth
    property int boxHeight: Root.Theme.launcherHeight
    property string searchPlaceholder: "Search..."
    property string searchQuery: ""
    property var listModel: null
    property int listCurrentIndex: 0
    property string emptyMessage: "No results"
    property string emptyIcon: ""
    property bool showEmpty: false
    property string statusText: ""

    // Delegate alias — caller provides list item component
    property alias delegate: listView.delegate

    // Direct access to the ListView for positionViewAtIndex
    readonly property alias listView: listView

    // Optional right panel content beside the list
    property alias rightPanel: rightPanelArea.children
    property int rightPanelWidth: 0

    // Grid mode — shows GridView instead of ListView
    property bool gridMode: false
    property int gridCellWidth: 44
    property int gridCellHeight: 44
    property alias gridDelegate: gridView.delegate
    readonly property alias gridView: gridView

    // Signals
    signal closeRequested()
    signal searchChanged(string text)
    signal navigateUp()
    signal navigateDown()
    signal pageUp()
    signal pageDown()
    signal accepted()

    // === Layer shell ===
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: layerNamespace
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    focusable: true

    color: "transparent"

    onVisibleChanged: {
        if (visible) {
            searchInput.text = modal.searchQuery
            searchInput.forceActiveFocus()
            listView.currentIndex = modal.listCurrentIndex
        }
    }

    function handleKeyPress(event) {
        switch (event.key) {
            case Qt.Key_Escape:
                modal.closeRequested()
                break
            case Qt.Key_Down:
                modal.navigateDown()
                break
            case Qt.Key_Up:
                modal.navigateUp()
                break
            case Qt.Key_PageDown:
                modal.pageDown()
                break
            case Qt.Key_PageUp:
                modal.pageUp()
                break
            case Qt.Key_Return:
            case Qt.Key_Enter:
                modal.accepted()
                break
            default:
                return
        }
        event.accepted = true
    }

    // Click outside the content box to dismiss
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: modal.closeRequested()
    }

    Rectangle {
        id: contentBox
        focus: true
        anchors.centerIn: parent
        width: modal.boxWidth
        height: modal.boxHeight
        radius: Root.Theme.windowRounding
        color: Root.Theme.surfaceGlass
        border.color: Root.Theme.surfaceContainer
        border.width: Root.Theme.borderWidthNormal

        scale: modal.visible ? 1.0 : 0.96
        opacity: modal.visible ? 1.0 : 0.0

        Behavior on scale {
            ScaleAnimator {
                duration: Root.Theme.durationNormal
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            OpacityAnimator {
                duration: Root.Theme.durationInstant
                easing.type: Easing.OutCubic
            }
        }

        Keys.onPressed: (event) => handleKeyPress(event)

        // Absorb clicks on the box so they don't dismiss
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Root.Theme.paddingLarge
            spacing: 0

            TextField {
                id: searchInput
                Layout.fillWidth: true
                Layout.preferredHeight: Root.Theme.inputHeightNormal
                placeholderText: modal.searchPlaceholder
                font.pixelSize: Root.Theme.fontSizeLarge
                font.family: Root.Theme.fontFamily
                font.weight: Root.Theme.fontWeight
                color: Root.Theme.on.surface
                placeholderTextColor: Root.Theme.outline
                leftPadding: Root.Theme.paddingMedium
                rightPadding: Root.Theme.paddingMedium
                topPadding: Root.Theme.paddingSmall
                bottomPadding: Root.Theme.paddingSmall
                text: modal.searchQuery

                background: Rectangle {
                    radius: Root.Theme.windowRounding
                    color: Root.Theme.surfaceDimGlass
                }

                Component.onCompleted: {
                    forceActiveFocus()
                }

                Keys.onPressed: (event) => {
                    var navKeys = [Qt.Key_Down, Qt.Key_Up, Qt.Key_Return, Qt.Key_Enter, Qt.Key_PageUp, Qt.Key_PageDown]
                    if (navKeys.includes(event.key)) event.accepted = false
                }

                onTextChanged: {
                    modal.searchChanged(text)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Root.Theme.spacingLarge
                spacing: Root.Theme.spacingSmall

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Root.Theme.surfaceContainer
                    opacity: 0.5
                }

                Text {
                    visible: modal.statusText !== ""
                    text: modal.statusText
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    color: Root.Theme.outline
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: Root.Theme.spacingSmall
                spacing: 0

                // List area (left)
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ListView {
                        id: listView
                        anchors.fill: parent
                        clip: true
                        visible: !modal.gridMode && count > 0

                        model: modal.listModel

                        // Re-sync currentIndex when model resets invalidate it
                        onCurrentIndexChanged: {
                            if (currentIndex === -1 && count > 0) {
                                currentIndex = modal.listCurrentIndex
                            }
                        }

                        onCountChanged: {
                            if (count > 0)
                                currentIndex = Math.min(modal.listCurrentIndex, count - 1)
                        }

                        Connections {
                            target: modal
                            function onListCurrentIndexChanged() {
                                listView.currentIndex = modal.listCurrentIndex
                            }
                        }
                        Component.onCompleted: currentIndex = modal.listCurrentIndex

                        ScrollBar.vertical: Root.StyledScrollBar {
                            target: listView
                        }
                    }

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

                        onCountChanged: {
                            if (count > 0)
                                currentIndex = Math.min(modal.listCurrentIndex, count - 1)
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

                    Root.EmptyState {
                        visible: (modal.gridMode ? gridView.count === 0 : listView.count === 0) && modal.showEmpty
                        message: modal.emptyMessage
                        icon: modal.emptyIcon
                    }
                }

                // Vertical separator (only when right panel has content)
                Rectangle {
                    Layout.fillHeight: true
                    Layout.leftMargin: Root.Theme.spacingLarge
                    width: 1
                    color: Root.Theme.surfaceContainer
                    opacity: 0.5
                    visible: modal.rightPanelWidth > 0
                }

                // Right panel area
                Item {
                    id: rightPanelArea
                    Layout.fillHeight: true
                    Layout.leftMargin: Root.Theme.spacingLarge
                    Layout.preferredWidth: modal.rightPanelWidth
                    visible: modal.rightPanelWidth > 0
                }
            }
        }
    }
}
