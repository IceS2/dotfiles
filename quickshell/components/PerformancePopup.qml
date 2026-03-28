import QtQuick
import QtQuick.Layouts
import ".." as Root

Root.ServicePopup {
    id: perfPopup

    service: Root.Performance
    layerNamespace: "quickshell-performance"

    // Fixed-width metrics for stable layout
    TextMetrics {
        id: pctMetrics
        font.pixelSize: Root.Theme.fontSizeSmall
        font.family: Root.Theme.fontFamily
        font.weight: Font.DemiBold
        text: "100%"
    }

    TextMetrics {
        id: tempMetrics
        font.pixelSize: Root.Theme.fontSizeSmall
        font.family: Root.Theme.fontFamily
        text: "100°C"
    }

    TextMetrics {
        id: memMetrics
        font.pixelSize: Root.Theme.fontSizeSmall
        font.family: Root.Theme.fontFamily
        text: "999.9 / 999.9 GB"
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Root.Theme.spacingMedium

        // ─── CPU Section ───
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Root.Theme.spacingSmall

            RowLayout {
                Layout.fillWidth: true
                spacing: Root.Theme.spacingSmall

                Text {
                    text: "󰍛"
                    font.pixelSize: 18
                    font.family: Root.Theme.fontFamily
                    color: Root.Theme.primary
                }

                Text {
                    text: "CPU"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    font.weight: Font.Bold
                    color: Root.Theme.on.surfaceVariant
                    Layout.fillWidth: true
                }

                TextEdit {
                    text: Root.Performance.cpuTemp + "°C"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    color: Root.Performance.tempColor(Root.Performance.cpuTemp)
                    readOnly: true
                    selectByMouse: true
                    selectedTextColor: Root.Theme.on.primary
                    selectionColor: Root.Theme.primary
                    Layout.minimumWidth: tempMetrics.width
                    horizontalAlignment: Text.AlignRight
                }

                TextEdit {
                    text: Root.Performance.cpuPercent + "%"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    font.weight: Font.DemiBold
                    color: Root.Theme.on.surface
                    readOnly: true
                    selectByMouse: true
                    selectedTextColor: Root.Theme.on.primary
                    selectionColor: Root.Theme.primary
                    Layout.minimumWidth: pctMetrics.width
                    horizontalAlignment: Text.AlignRight
                }
            }

            Root.ProgressBar {
                Layout.fillWidth: true
                value: Root.Performance.cpuPercent / 100
                fillColor: Root.Performance.cpuPercent >= 80 ? Root.Theme.error : Root.Theme.primary
            }
        }

        // ─── RAM Section ───
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Root.Theme.spacingSmall

            RowLayout {
                Layout.fillWidth: true
                spacing: Root.Theme.spacingSmall

                Text {
                    text: "󰘚"
                    font.pixelSize: 18
                    font.family: Root.Theme.fontFamily
                    color: Root.Theme.secondary
                }

                Text {
                    text: "RAM"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    font.weight: Font.Bold
                    color: Root.Theme.on.surfaceVariant
                    Layout.fillWidth: true
                }

                TextEdit {
                    text: Root.Performance.ramTemp + "°C"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    color: Root.Performance.tempColor(Root.Performance.ramTemp)
                    readOnly: true
                    selectByMouse: true
                    selectedTextColor: Root.Theme.on.primary
                    selectionColor: Root.Theme.primary
                    Layout.minimumWidth: tempMetrics.width
                    horizontalAlignment: Text.AlignRight
                    visible: Root.Performance.ramTemp > 0
                }

                TextEdit {
                    text: Root.Performance.ramUsedGb + " / " + Root.Performance.ramTotalGb + " GB"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    color: Root.Theme.on.surfaceVariant
                    readOnly: true
                    selectByMouse: true
                    selectedTextColor: Root.Theme.on.primary
                    selectionColor: Root.Theme.primary
                    Layout.minimumWidth: memMetrics.width
                    horizontalAlignment: Text.AlignRight
                }

                TextEdit {
                    text: Root.Performance.ramPercent + "%"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    font.weight: Font.DemiBold
                    color: Root.Theme.on.surface
                    readOnly: true
                    selectByMouse: true
                    selectedTextColor: Root.Theme.on.primary
                    selectionColor: Root.Theme.primary
                    Layout.minimumWidth: pctMetrics.width
                    horizontalAlignment: Text.AlignRight
                }
            }

            Root.ProgressBar {
                Layout.fillWidth: true
                value: Root.Performance.ramPercent / 100
                fillColor: Root.Performance.ramPercent >= 85 ? Root.Theme.error : Root.Theme.secondary
            }
        }

        // ─── GPU Section ───
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Root.Theme.spacingSmall

            RowLayout {
                Layout.fillWidth: true
                spacing: Root.Theme.spacingSmall

                Text {
                    text: "󰢮"
                    font.pixelSize: 18
                    font.family: Root.Theme.fontFamily
                    color: Root.Theme.tertiary
                }

                Text {
                    text: "GPU"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    font.weight: Font.Bold
                    color: Root.Theme.on.surfaceVariant
                    Layout.fillWidth: true
                }

                TextEdit {
                    text: Root.Performance.gpuTemp + "°C"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    color: Root.Performance.tempColor(Root.Performance.gpuTemp)
                    readOnly: true
                    selectByMouse: true
                    selectedTextColor: Root.Theme.on.primary
                    selectionColor: Root.Theme.primary
                    Layout.minimumWidth: tempMetrics.width
                    horizontalAlignment: Text.AlignRight
                }

                TextEdit {
                    text: Root.Performance.gpuPercent + "%"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    font.weight: Font.DemiBold
                    color: Root.Theme.on.surface
                    readOnly: true
                    selectByMouse: true
                    selectedTextColor: Root.Theme.on.primary
                    selectionColor: Root.Theme.primary
                    Layout.minimumWidth: pctMetrics.width
                    horizontalAlignment: Text.AlignRight
                }
            }

            Root.ProgressBar {
                Layout.fillWidth: true
                value: Root.Performance.gpuPercent / 100
                fillColor: Root.Performance.gpuPercent >= 80 ? Root.Theme.error : Root.Theme.tertiary
            }

            // VRAM
            RowLayout {
                Layout.fillWidth: true
                spacing: Root.Theme.spacingSmall

                Text {
                    text: "VRAM"
                    font.pixelSize: Root.Theme.fontSizeTiny
                    font.family: Root.Theme.fontFamily
                    color: Root.Theme.outline
                    Layout.fillWidth: true
                }

                TextEdit {
                    text: Root.Performance.gpuVramUsedGb + " / " + Root.Performance.gpuVramTotalGb + " GB"
                    font.pixelSize: Root.Theme.fontSizeTiny
                    font.family: Root.Theme.fontFamily
                    color: Root.Theme.outline
                    readOnly: true
                    selectByMouse: true
                    selectedTextColor: Root.Theme.on.primary
                    selectionColor: Root.Theme.primary
                }
            }

            Root.ProgressBar {
                Layout.fillWidth: true
                trackHeight: 3
                value: Root.Performance.gpuVramPercent / 100
                fillColor: Root.Performance.gpuVramPercent >= 80 ? Root.Theme.error
                    : Qt.lighter(Root.Theme.tertiary, 1.3)
            }
        }

        // ─── Divider ───
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Root.Theme.outlineVariant
            opacity: 0.5
            visible: Root.Performance.disks.length > 0
        }

        // ─── Disk Section ───
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Root.Theme.spacingSmall
            visible: Root.Performance.disks.length > 0

            RowLayout {
                Layout.fillWidth: true
                spacing: Root.Theme.spacingSmall

                Text {
                    text: "Disk"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    font.weight: Font.Bold
                    color: Root.Theme.on.surfaceVariant
                    Layout.fillWidth: true
                }

                TextEdit {
                    text: Root.Performance.nvmeTemp + "°C"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    color: Root.Performance.tempColor(Root.Performance.nvmeTemp)
                    readOnly: true
                    selectByMouse: true
                    selectedTextColor: Root.Theme.on.primary
                    selectionColor: Root.Theme.primary
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

                        TextEdit {
                            text: modelData.mount
                            font.pixelSize: Root.Theme.fontSizeTiny
                            font.family: Root.Theme.fontFamily
                            color: Root.Theme.on.surfaceVariant
                            readOnly: true
                            selectByMouse: true
                            selectedTextColor: Root.Theme.on.primary
                            selectionColor: Root.Theme.primary
                            Layout.fillWidth: true
                        }

                        TextEdit {
                            text: modelData.usedGb + " / " + modelData.totalGb + " GB"
                            font.pixelSize: Root.Theme.fontSizeTiny
                            font.family: Root.Theme.fontFamily
                            color: Root.Theme.outline
                            readOnly: true
                            selectByMouse: true
                            selectedTextColor: Root.Theme.on.primary
                            selectionColor: Root.Theme.primary
                        }

                        Text {
                            text: modelData.percent + "%"
                            font.pixelSize: Root.Theme.fontSizeTiny
                            font.family: Root.Theme.fontFamily
                            font.weight: Font.DemiBold
                            color: modelData.percent >= 90 ? Root.Theme.error : Root.Theme.on.surface
                        }
                    }

                    Root.ProgressBar {
                        Layout.fillWidth: true
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
