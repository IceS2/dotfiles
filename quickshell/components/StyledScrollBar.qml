import QtQuick
import QtQuick.Controls
import ".." as Root

ScrollBar {
    id: scrollBar

    property Flickable target: null

    policy: {
        if (!target) return ScrollBar.AlwaysOff
        var overflow = orientation === Qt.Vertical
            ? target.contentHeight > target.height
            : target.contentWidth > target.width
        return overflow ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
    }

    contentItem: Rectangle {
        implicitWidth: 4
        radius: 2
        color: Root.Theme.surfaceContainerHighest
        opacity: 0.6
    }

    background: Item {}
}
