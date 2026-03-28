import QtQuick
import QtQuick.Layouts
import ".." as Root

Item {
    id: pill

    // Children declared inside BarPill go into the inner RowLayout
    default property alias content: innerLayout.data

    // Active state — set to true when a child widget's popup is open
    property bool active: false

    // Active border color — set to the widget's category color in shell.qml
    property color activeColor: Root.Theme.primary

    // Allow per-pill padding overrides (e.g. workspace pill with paddingV: 0)
    property int paddingH: Root.Theme.pillPaddingH
    property int paddingV: Root.Theme.pillPaddingV

    implicitWidth: innerLayout.implicitWidth + paddingH * 2
    implicitHeight: Root.Theme.pillHeight

    // ─── Hover Detection ───
    HoverHandler {
        id: pillHover
    }

    // Track which child widget contains the cursor
    property real _hoverX: pillHover.hovered ? pillHover.point.position.x : -1

    property int _hoveredChildIndex: {
        if (_hoverX < 0) return -1
        var localX = _hoverX - innerLayout.x
        var halfSpacing = innerLayout.spacing / 2
        for (var i = 0; i < innerLayout.children.length; i++) {
            var child = innerLayout.children[i]
            if (!child.visible || child.width <= 2) continue
            if (localX >= child.x - halfSpacing && localX <= child.x + child.width + halfSpacing)
                return i
        }
        return -1
    }

    // Read tintColor from the hovered child widget
    property color _hoverTint: {
        if (_hoveredChildIndex < 0) return Qt.rgba(0, 0, 0, 0)
        var child = innerLayout.children[_hoveredChildIndex]
        return (child && child.tintColor) ? child.tintColor : Qt.rgba(0, 0, 0, 0)
    }

    // ─── Glassmorphic Background ───
    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Root.Theme.pillRadius
        color: Root.Theme.pillBackground
        border.width: pill.active ? 1.5 : 1
        border.color: pill.active
            ? Qt.rgba(pill.activeColor.r, pill.activeColor.g, pill.activeColor.b, 0.35)
            : Root.Theme.pillBorder

        Behavior on color { Root.CAnim {} }
        Behavior on border.color { Root.CAnim {} }
        Behavior on border.width {
            NumberAnimation { duration: Root.Theme.durationFast; easing.type: Easing.OutCubic }
        }
    }

    // ─── Hover Tint Overlay (widget category color bleeds into pill) ───
    Rectangle {
        anchors.fill: parent
        radius: Root.Theme.pillRadius
        color: pill._hoverTint
        opacity: pillHover.hovered && pill._hoveredChildIndex >= 0 ? 0.02 : 0.0

        Behavior on color {
            ColorAnimation { duration: Root.Theme.durationNormal; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            OpacityAnimator { duration: Root.Theme.durationNormal; easing.type: Easing.OutCubic }
        }
    }

    // ─── Content Layout ───
    RowLayout {
        id: innerLayout
        anchors.centerIn: parent
        spacing: Root.Theme.spacingSmall
    }
}
