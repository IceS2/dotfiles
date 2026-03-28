import QtQuick
import Quickshell
import ".." as Root

Root.SearchModal {
    id: launcherBox
    showing: Root.Launcher.visible
    screen: Root.Launcher.activeScreen
    layerNamespace: "quickshell-launcher-box"
    searchPlaceholder: "  Search applications..."
    searchQuery: Root.Launcher.searchQuery
    listModel: filteredAppsModel
    listCurrentIndex: Root.Launcher.currentIndex
    emptyMessage: "No applications found"
    emptyIcon: ""
    showEmpty: Root.Launcher.searchQuery !== ""

    // Hover lock — ignore mouse hover briefly after search text changes or open
    property bool _hoverLock: false
    property Timer _hoverLockTimer: Timer {
        interval: 150
        onTriggered: launcherBox._hoverLock = false
    }

    onShowingChanged: {
        if (showing) {
            _hoverLock = true
            _hoverLockTimer.restart()
        }
    }

    onCloseRequested: Root.Launcher.hide()
    onSearchChanged: (text) => {
        Root.Launcher.searchQuery = text
        _hoverLock = true
        _hoverLockTimer.restart()
    }
    onNavigateUp: {
        if (Root.Launcher.navigateUp())
            listView.positionViewAtIndex(Root.Launcher.currentIndex, ListView.Contain)
    }
    onNavigateDown: {
        if (Root.Launcher.navigateDown())
            listView.positionViewAtIndex(Root.Launcher.currentIndex, ListView.Contain)
    }
    onPageUp: {
        if (Root.Launcher.pageUp())
            listView.positionViewAtIndex(Root.Launcher.currentIndex, ListView.Contain)
    }
    onPageDown: {
        if (Root.Launcher.pageDown())
            listView.positionViewAtIndex(Root.Launcher.currentIndex, ListView.Contain)
    }
    onAccepted: {
        if (Root.Launcher.launchSelected()) Root.Launcher.hide()
    }

    delegate: Root.AppListItem {
        onHovered: if (!launcherBox._hoverLock) Root.Launcher.currentIndex = index
        onClicked: {
            Root.Launcher.launchApp(app)
            Root.Launcher.hide()
        }
    }

    ScriptModel {
        id: filteredAppsModel
        values: Root.Launcher.filteredApps
    }
}
