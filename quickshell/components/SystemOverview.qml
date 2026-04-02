import QtQuick
import QtQuick.Layouts
import ".." as Root

Rectangle {
    id: sysOverview

    property bool expanded: false

    implicitHeight: sysColumn.implicitHeight + Root.Theme.paddingSmall * 2
    radius: Root.Theme.borderRadiusMedium
    color: sysOverviewMouse.containsMouse ? Root.Theme.surfaceContainerHigh : Root.Theme.surfaceContainer
    Behavior on color { Root.CAnim {} }

    // ─── Computed Properties ───

    readonly property int _rootDiskPercent: {
        var disks = Root.Performance.disks
        for (var i = 0; i < disks.length; i++) {
            if (disks[i].mount === "/") return disks[i].percent
        }
        return disks.length > 0 ? disks[0].percent : 0
    }

    // ─── Stable column widths ───

    TextMetrics {
        id: sysPctMetrics
        font.pixelSize: Root.Theme.fontSizeSmall
        font.family: Root.Theme.fontFamilyMono
        font.weight: Font.Bold
        text: "100%"
    }

    TextMetrics {
        id: sysTempMetrics
        font.pixelSize: Root.Theme.fontSizeCaption
        font.family: Root.Theme.fontFamily
        text: "100°C"
    }

    TextMetrics {
        id: sysMemMetrics
        font.pixelSize: Root.Theme.fontSizeCaption
        font.family: Root.Theme.fontFamilyMono
        text: "999.9 / 999.9 GB"
    }

    // ─── Content ───

    ColumnLayout {
        id: sysColumn
        anchors.fill: parent
        anchors.margins: Root.Theme.paddingSmall
        spacing: Root.Theme.spacingSmall

        // ─── Header Row ───
        RowLayout {
            Layout.fillWidth: true
            spacing: Root.Theme.spacingSmall

            Text {
                text: "System"
                font.pixelSize: Root.Theme.fontSizeSmall
                font.family: Root.Theme.fontFamily
                font.weight: Font.Bold
                color: Root.Theme.on.surface
            }
            Item { Layout.fillWidth: true }
            Text {
                text: sysOverview.expanded ? "󰅀" : "󰅂"
                font.pixelSize: 12
                font.family: Root.Theme.fontFamily
                color: Root.Theme.outline
            }
        }

        // ─── CPU Row ───
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: Root.Theme.spacingSmall

                Text {
                    text: "󰍛"
                    font.pixelSize: 14
                    font.family: Root.Theme.fontFamily
                    color: Root.Theme.primary
                }
                Text {
                    text: "CPU"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    font.weight: Font.Bold
                    color: Root.Theme.on.surfaceVariant
                }
                Text {
                    text: Root.Performance.cpuTemp + "°C"
                    font.pixelSize: Root.Theme.fontSizeCaption
                    font.family: Root.Theme.fontFamily
                    color: Root.Performance.tempColor(Root.Performance.cpuTemp)
                    visible: Root.Performance.cpuTemp > 0
                    Layout.minimumWidth: visible ? sysTempMetrics.width : 0
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: Root.Performance.cpuPercent + "%"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamilyMono
                    font.weight: Font.Bold
                    color: Root.Theme.on.surface
                    Layout.minimumWidth: sysPctMetrics.width
                    horizontalAlignment: Text.AlignRight
                }
            }
            Root.ProgressBar {
                Layout.fillWidth: true
                trackHeight: 3
                value: Root.Performance.cpuPercent / 100
                fillColor: Root.Performance.cpuPercent >= 90 ? Root.Theme.error
                    : Root.Performance.cpuPercent >= 75 ? Root.Theme.caution
                    : Root.Theme.primary
            }
        }

        // ─── RAM Row ───
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: Root.Theme.spacingSmall

                Text {
                    text: "󰘚"
                    font.pixelSize: 14
                    font.family: Root.Theme.fontFamily
                    color: Root.Theme.secondary
                }
                Text {
                    text: "RAM"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    font.weight: Font.Bold
                    color: Root.Theme.on.surfaceVariant
                }
                Text {
                    text: Root.Performance.ramTemp + "°C"
                    font.pixelSize: Root.Theme.fontSizeCaption
                    font.family: Root.Theme.fontFamily
                    color: Root.Performance.tempColor(Root.Performance.ramTemp)
                    visible: Root.Performance.ramTemp > 0
                    Layout.minimumWidth: visible ? sysTempMetrics.width : 0
                }
                Text {
                    text: Root.Performance.ramUsedGb.toFixed(1) + " / " + Root.Performance.ramTotalGb.toFixed(1) + " GB"
                    font.pixelSize: Root.Theme.fontSizeCaption
                    font.family: Root.Theme.fontFamilyMono
                    color: Root.Theme.outline
                    visible: sysOverview.expanded
                    Layout.minimumWidth: visible ? sysMemMetrics.width : 0
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: Root.Performance.ramPercent + "%"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamilyMono
                    font.weight: Font.Bold
                    color: Root.Theme.on.surface
                    Layout.minimumWidth: sysPctMetrics.width
                    horizontalAlignment: Text.AlignRight
                }
            }
            Root.ProgressBar {
                Layout.fillWidth: true
                trackHeight: 3
                value: Root.Performance.ramPercent / 100
                fillColor: Root.Performance.ramPercent >= 92 ? Root.Theme.error
                    : Root.Performance.ramPercent >= 80 ? Root.Theme.caution
                    : Root.Theme.secondary
            }
        }

        // ─── GPU Row ───
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: Root.Theme.spacingSmall

                Text {
                    text: "󰢮"
                    font.pixelSize: 14
                    font.family: Root.Theme.fontFamily
                    color: Root.Theme.tertiary
                }
                Text {
                    text: "GPU"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    font.weight: Font.Bold
                    color: Root.Theme.on.surfaceVariant
                }
                Text {
                    text: Root.Performance.gpuTemp + "°C"
                    font.pixelSize: Root.Theme.fontSizeCaption
                    font.family: Root.Theme.fontFamily
                    color: Root.Performance.tempColor(Root.Performance.gpuTemp)
                    visible: Root.Performance.gpuTemp > 0
                    Layout.minimumWidth: visible ? sysTempMetrics.width : 0
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: Root.Performance.gpuPercent + "%"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamilyMono
                    font.weight: Font.Bold
                    color: Root.Theme.on.surface
                    Layout.minimumWidth: sysPctMetrics.width
                    horizontalAlignment: Text.AlignRight
                }
            }
            Root.ProgressBar {
                Layout.fillWidth: true
                trackHeight: 3
                value: Root.Performance.gpuPercent / 100
                fillColor: Root.Performance.gpuPercent >= 95 ? Root.Theme.error
                    : Root.Performance.gpuPercent >= 85 ? Root.Theme.caution
                    : Root.Theme.tertiary
            }
        }

        // ─── VRAM Section (expanded only) ───
        Item {
            Layout.fillWidth: true
            implicitHeight: sysOverview.expanded ? vramColumn.implicitHeight : 0
            clip: true
            visible: implicitHeight > 0
            opacity: sysOverview.expanded ? 1.0 : 0.0

            Behavior on implicitHeight {
                NumberAnimation { duration: Root.Theme.durationSlow; easing.type: Easing.OutCubic }
            }
            Behavior on opacity {
                OpacityAnimator { duration: Root.Theme.durationNormal; easing.type: Easing.OutCubic }
            }

            ColumnLayout {
                id: vramColumn
                width: parent.width
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Root.Theme.spacingSmall

                    Item { implicitWidth: 14 + Root.Theme.spacingSmall }
                    Text {
                        text: "VRAM"
                        font.pixelSize: Root.Theme.fontSizeSmall
                        font.family: Root.Theme.fontFamily
                        color: Root.Theme.on.surfaceVariant
                    }
                    Text {
                        text: Root.Performance.gpuVramUsedGb.toFixed(1) + " / " + Root.Performance.gpuVramTotalGb.toFixed(1) + " GB"
                        font.pixelSize: Root.Theme.fontSizeCaption
                        font.family: Root.Theme.fontFamilyMono
                        color: Root.Theme.outline
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: Root.Performance.gpuVramPercent + "%"
                        font.pixelSize: Root.Theme.fontSizeSmall
                        font.family: Root.Theme.fontFamilyMono
                        font.weight: Font.Bold
                        color: Root.Theme.on.surface
                        Layout.minimumWidth: sysPctMetrics.width
                        horizontalAlignment: Text.AlignRight
                    }
                }
                Root.ProgressBar {
                    Layout.fillWidth: true
                    Layout.leftMargin: 14 + Root.Theme.spacingSmall
                    trackHeight: 3
                    value: Root.Performance.gpuVramPercent / 100
                    fillColor: Root.Performance.gpuVramPercent >= 80 ? Root.Theme.error
                        : Qt.lighter(Root.Theme.tertiary, 1.3)
                }
            }
        }

        // ─── Disk Compact Row (compact only) ───
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            visible: !sysOverview.expanded

            RowLayout {
                Layout.fillWidth: true
                spacing: Root.Theme.spacingSmall

                Text {
                    text: "󰋊"
                    font.pixelSize: 14
                    font.family: Root.Theme.fontFamily
                    color: Root.Theme.success
                }
                Text {
                    text: "Disk"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    font.weight: Font.Bold
                    color: Root.Theme.on.surfaceVariant
                }
                Text {
                    text: Root.Performance.nvmeTemp + "°C"
                    font.pixelSize: Root.Theme.fontSizeCaption
                    font.family: Root.Theme.fontFamily
                    color: Root.Performance.tempColor(Root.Performance.nvmeTemp)
                    visible: Root.Performance.nvmeTemp > 0
                    Layout.minimumWidth: visible ? sysTempMetrics.width : 0
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: sysOverview._rootDiskPercent + "%"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamilyMono
                    font.weight: Font.Bold
                    color: Root.Theme.on.surface
                    Layout.minimumWidth: sysPctMetrics.width
                    horizontalAlignment: Text.AlignRight
                }
            }
            Root.ProgressBar {
                Layout.fillWidth: true
                trackHeight: 3
                value: sysOverview._rootDiskPercent / 100
                fillColor: sysOverview._rootDiskPercent >= 90 ? Root.Theme.error
                    : sysOverview._rootDiskPercent >= 75 ? Root.Theme.caution
                    : Root.Theme.success
            }
        }

        // ─── Disk Expanded Section (expanded only) ───
        Item {
            Layout.fillWidth: true
            implicitHeight: sysOverview.expanded ? diskExpandedColumn.implicitHeight : 0
            clip: true
            visible: implicitHeight > 0
            opacity: sysOverview.expanded ? 1.0 : 0.0

            Behavior on implicitHeight {
                NumberAnimation { duration: Root.Theme.durationSlow; easing.type: Easing.OutCubic }
            }
            Behavior on opacity {
                OpacityAnimator { duration: Root.Theme.durationNormal; easing.type: Easing.OutCubic }
            }

            ColumnLayout {
                id: diskExpandedColumn
                width: parent.width
                spacing: Root.Theme.spacingSmall

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Root.Theme.outlineVariant
                    opacity: 0.5
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Root.Theme.spacingSmall

                    Text {
                        text: "󰋊"
                        font.pixelSize: 14
                        font.family: Root.Theme.fontFamily
                        color: Root.Theme.success
                    }
                    Text {
                        text: "Disk"
                        font.pixelSize: Root.Theme.fontSizeSmall
                        font.family: Root.Theme.fontFamily
                        font.weight: Font.Bold
                        color: Root.Theme.on.surfaceVariant
                    }
                    Text {
                        text: Root.Performance.nvmeTemp + "°C"
                        font.pixelSize: Root.Theme.fontSizeCaption
                        font.family: Root.Theme.fontFamily
                        color: Root.Performance.tempColor(Root.Performance.nvmeTemp)
                        visible: Root.Performance.nvmeTemp > 0
                    }
                }

                Repeater {
                    model: Root.Performance.disks

                    ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Root.Theme.spacingSmall

                            Item { implicitWidth: 14 + Root.Theme.spacingSmall }
                            Text {
                                text: modelData.mount
                                font.pixelSize: Root.Theme.fontSizeSmall
                                font.family: Root.Theme.fontFamilyMono
                                color: Root.Theme.on.surfaceVariant
                            }
                            Text {
                                text: modelData.usedGb.toFixed(1) + " / " + modelData.totalGb.toFixed(1) + " GB"
                                font.pixelSize: Root.Theme.fontSizeCaption
                                font.family: Root.Theme.fontFamilyMono
                                color: Root.Theme.outline
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: modelData.percent + "%"
                                font.pixelSize: Root.Theme.fontSizeSmall
                                font.family: Root.Theme.fontFamilyMono
                                font.weight: Font.Bold
                                color: Root.Theme.on.surface
                                Layout.minimumWidth: sysPctMetrics.width
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                        Root.ProgressBar {
                            Layout.fillWidth: true
                            Layout.leftMargin: 14 + Root.Theme.spacingSmall
                            trackHeight: 3
                            value: modelData.percent / 100
                            fillColor: modelData.percent >= 90 ? Root.Theme.error
                                : modelData.percent >= 75 ? Root.Theme.caution
                                : Root.Theme.success
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        id: sysOverviewMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: sysOverview.expanded = !sysOverview.expanded
    }
}
