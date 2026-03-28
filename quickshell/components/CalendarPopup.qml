import QtQuick
import QtQuick.Layouts
import ".." as Root

Root.ServicePopup {
    id: calendarWindow

    service: Root.Calendar
    layerNamespace: "quickshell-calendar"
    panelWidth: 380

    onPanelWheel: event => {
        if (Root.Calendar.activeTab === 0) {
            if (event.angleDelta.y > 0)
                Root.Calendar.prevMonth()
            else
                Root.Calendar.nextMonth()
        }
    }

    // Fetch non-primary weather data when switching to weather tab
    Connections {
        target: Root.Calendar
        function onActiveTabChanged() {
            if (Root.Calendar.activeTab === 1)
                Root.Weather.fetchNonPrimaryIfNeeded()
        }
    }

    // ─── Calendar-specific keyboard shortcuts ───
    Shortcut {
        enabled: Root.Calendar.activeTab === 0
        sequence: "T"
        onActivated: Root.Calendar.goToToday()
    }

    Shortcut {
        enabled: Root.Calendar.activeTab === 0
        sequence: "Left"
        onActivated: Root.Calendar.prevMonth()
    }

    Shortcut {
        enabled: Root.Calendar.activeTab === 0
        sequence: "Right"
        onActivated: Root.Calendar.nextMonth()
    }

    // ─── Content ───
    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Root.Theme.spacingSmall

        // ─── Tab Bar ───
        RowLayout {
            Layout.fillWidth: true
            spacing: 2

            Repeater {
                model: ["Calendar", "Weather"]

                Rectangle {
                    required property string modelData
                    required property int index
                    Layout.fillWidth: true
                    height: 28
                    radius: Root.Theme.borderRadiusSmall
                    color: Root.Calendar.activeTab === index
                        ? Root.Theme.primary
                        : tabMouse.containsMouse ? Root.Theme.surfaceContainer : "transparent"
                    Behavior on color { Root.CAnim {} }

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: Root.Theme.fontSizeSmall
                        font.family: Root.Theme.fontFamily
                        font.weight: Font.DemiBold
                        color: Root.Calendar.activeTab === index
                            ? Root.Theme.on.primary : Root.Theme.on.surfaceVariant
                    }

                    MouseArea {
                        id: tabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Root.Calendar.activeTab = index
                    }
                }
            }
        }

        // ═══════════════════════════════════════
        // ─── Calendar Tab ───
        // ═══════════════════════════════════════
        ColumnLayout {
            Layout.fillWidth: true
            visible: Root.Calendar.activeTab === 0
            spacing: Root.Theme.spacingSmall

            // ─── Header: Month/Year + navigation ───
            RowLayout {
                Layout.fillWidth: true
                spacing: Root.Theme.spacingSmall

                Root.IconButton {
                    icon: "󰃭"
                    iconColor: Root.Theme.primary
                    opacity: Root.Calendar.isCurrentMonth() ? 0.3 : 1.0
                    onClicked: Root.Calendar.goToToday()
                }

                Text {
                    text: Root.Calendar.monthName(Root.Calendar.displayMonth) + " " + Root.Calendar.displayYear
                    font.pixelSize: Root.Theme.fontSizeNormal
                    font.family: Root.Theme.fontFamily
                    font.weight: Font.Bold
                    color: Root.Theme.on.surface
                    Layout.fillWidth: true
                }

                Root.IconButton {
                    icon: "󰅁"
                    onClicked: Root.Calendar.prevMonth()
                }

                Root.IconButton {
                    icon: "󰅂"
                    onClicked: Root.Calendar.nextMonth()
                }
            }

            // ─── Separator ───
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Root.Theme.surfaceContainerHigh
                opacity: 0.5
            }

            // ─── Day-of-week headers ───
            Grid {
                columns: 7
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter

                Repeater {
                    model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

                    Item {
                        width: Root.Theme.calendarCellSize; height: Root.Theme.calendarHeaderHeight

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: Root.Theme.fontSizeSmall
                            font.family: Root.Theme.fontFamily
                            font.weight: Font.DemiBold
                            color: Root.Theme.outline
                        }
                    }
                }
            }

            // ─── Day grid (6 rows x 7 columns = 42 cells) ───
            Grid {
                id: dayGrid
                columns: 7
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter

                // Recalculate when month changes
                readonly property int daysInMonth: Root.Calendar.getDaysInMonth(Root.Calendar.displayYear, Root.Calendar.displayMonth)
                readonly property int firstDay: Root.Calendar.getFirstDayOfWeek(Root.Calendar.displayYear, Root.Calendar.displayMonth)

                Repeater {
                    model: 42

                    Item {
                        id: dayCell
                        width: Root.Theme.calendarCellSize; height: Root.Theme.calendarCellSize

                        property int dayNumber: index - dayGrid.firstDay + 1
                        property bool isValid: dayNumber >= 1 && dayNumber <= dayGrid.daysInMonth
                        property bool isToday: isValid && Root.Calendar.isToday(Root.Calendar.displayYear, Root.Calendar.displayMonth, dayNumber)

                        visible: isValid

                        // Hover background
                        Rectangle {
                            anchors.centerIn: parent
                            width: 34; height: 34
                            radius: Root.Theme.borderRadiusSmall
                            color: dayMouseArea.containsMouse && !dayCell.isToday ? Root.Theme.surfaceContainer : "transparent"
                        }

                        // Today ring
                        Rectangle {
                            anchors.centerIn: parent
                            width: 34; height: 34
                            radius: Root.Theme.borderRadiusSmall
                            color: "transparent"
                            border.color: Root.Theme.primary
                            border.width: 2
                            visible: dayCell.isToday
                        }

                        Text {
                            anchors.centerIn: parent
                            text: dayCell.dayNumber
                            font.pixelSize: Root.Theme.fontSizeSmall
                            font.family: Root.Theme.fontFamily
                            font.weight: dayCell.isToday ? Font.Bold : Root.Theme.fontWeight
                            color: dayCell.isToday ? Root.Theme.primary : Root.Theme.on.surface
                        }

                        MouseArea {
                            id: dayMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════
        // ─── Weather Tab ───
        // ═══════════════════════════════════════
        ColumnLayout {
            Layout.fillWidth: true
            visible: Root.Calendar.activeTab === 1
            spacing: Root.Theme.spacingMedium

            // ─── Primary Header ───
            RowLayout {
                Layout.fillWidth: true
                spacing: Root.Theme.spacingSmall

                Text {
                    text: "\u2605"
                    font.pixelSize: Root.Theme.fontSizeNormal
                    color: Root.Theme.sapphire
                }

                Text {
                    text: Root.Weather.primaryName || "No location"
                    font.pixelSize: Root.Theme.fontSizeNormal
                    font.family: Root.Theme.fontFamily
                    font.weight: Font.Bold
                    color: Root.Theme.on.surface
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    visible: Root.Weather.lastUpdatedText !== ""
                    text: Root.Weather.lastUpdatedText
                    font.pixelSize: Root.Theme.fontSizeTiny
                    font.family: Root.Theme.fontFamily
                    color: Root.Theme.outline
                }
            }

            // ─── Current Conditions ───
            Item {
                Layout.fillWidth: true
                visible: Root.Weather._primary && Root.Weather._primary.current
                implicitHeight: conditionRow.implicitHeight

                RowLayout {
                    id: conditionRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Root.Theme.spacingMedium

                    // Large weather icon
                    Text {
                        text: Root.Weather.primaryIcon
                        font.pixelSize: 48
                        font.family: Root.Theme.fontFamily
                        color: Root.Theme.sapphire
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: Root.Weather._primary && Root.Weather._primary.current
                                ? Root.Weather._primary.current.temp + "\u00B0C" : ""
                            font.pixelSize: Root.Theme.fontSizeTitle
                            font.family: Root.Theme.fontFamily
                            font.weight: Font.Bold
                            color: Root.Theme.on.surface
                        }

                        Text {
                            text: Root.Weather.primaryCondition
                            font.pixelSize: Root.Theme.fontSizeSmall
                            font.family: Root.Theme.fontFamily
                            color: Root.Theme.on.surfaceVariant
                        }
                    }
                }
            }

            // ─── Detail Row ───
            RowLayout {
                Layout.fillWidth: true
                visible: Root.Weather._primary && Root.Weather._primary.current
                spacing: Root.Theme.spacingMedium

                Text {
                    text: "Feels " + Root.Weather.primaryFeelsLike
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    color: Root.Theme.on.surfaceVariant
                }

                Text {
                    text: "\u00B7"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    color: Root.Theme.outline
                }

                Text {
                    text: "\u{F0781} " + Root.Weather.primaryHumidity
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    color: Root.Theme.on.surfaceVariant
                }

                Text {
                    text: "\u00B7"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    color: Root.Theme.outline
                }

                Text {
                    text: "\u{F015E} " + Root.Weather.primaryWind
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    color: Root.Theme.on.surfaceVariant
                }

                Text {
                    text: "\u00B7"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    color: Root.Theme.outline
                }

                Text {
                    text: "UV " + Root.Weather.primaryUv
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    color: Root.Theme.on.surfaceVariant
                }
            }

            // ─── 3-Day Forecast ───
            RowLayout {
                Layout.fillWidth: true
                visible: Root.Weather.primaryForecast.length > 0
                spacing: Root.Theme.spacingSmall

                Repeater {
                    model: Root.Weather.primaryForecast

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: forecastCol.implicitHeight + Root.Theme.paddingMedium * 2
                        radius: Root.Theme.borderRadiusMedium
                        color: Root.Theme.surfaceContainer

                        ColumnLayout {
                            id: forecastCol
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: modelData.day
                                font.pixelSize: Root.Theme.fontSizeSmall
                                font.family: Root.Theme.fontFamily
                                font.weight: Font.DemiBold
                                color: Root.Theme.on.surface
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: modelData.icon
                                font.pixelSize: Root.Theme.fontSizeLarge
                                font.family: Root.Theme.fontFamily
                                color: Root.Theme.sapphire
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: modelData.maxTemp + "\u00B0"
                                font.pixelSize: Root.Theme.fontSizeSmall
                                font.family: Root.Theme.fontFamily
                                font.weight: Font.Bold
                                color: Root.Theme.on.surface
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: modelData.minTemp + "\u00B0"
                                font.pixelSize: Root.Theme.fontSizeTiny
                                font.family: Root.Theme.fontFamily
                                color: Root.Theme.outline
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }
            }

            // ─── Divider ───
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: Root.Theme.spacingSmall
                Layout.bottomMargin: Root.Theme.spacingSmall
                height: 1
                color: Root.Theme.outlineVariant
                opacity: 0.5
            }

            // ─── Locations Header ───
            Text {
                text: "Locations"
                font.pixelSize: Root.Theme.fontSizeSmall
                font.family: Root.Theme.fontFamily
                font.weight: Font.DemiBold
                color: Root.Theme.outline
            }

            // ─── Locations List ───
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                visible: Root.Weather.locations.length > 0

                Repeater {
                    model: Root.Weather.locations

                    Rectangle {
                        id: locationDelegate
                        Layout.fillWidth: true
                        height: Root.Theme.itemHeightSmall
                        radius: Root.Theme.borderRadiusSmall
                        color: locationMouse.containsMouse ? Root.Theme.surfaceContainer : "transparent"

                        required property var modelData
                        required property int index

                        Behavior on color { Root.CAnim {} }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Root.Theme.paddingSmall
                            anchors.rightMargin: Root.Theme.paddingSmall
                            spacing: Root.Theme.spacingSmall

                            // Star icon — click to set primary
                            Text {
                                text: locationDelegate.index === Root.Weather.primaryIndex ? "\u2605" : "\u2606"
                                font.pixelSize: Root.Theme.fontSizeNormal
                                color: locationDelegate.index === Root.Weather.primaryIndex
                                    ? Root.Theme.sapphire : Root.Theme.outline

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Root.Weather.setPrimary(locationDelegate.index)
                                }
                            }

                            // Location name
                            Text {
                                text: locationDelegate.modelData.name
                                font.pixelSize: Root.Theme.fontSizeSmall
                                font.family: Root.Theme.fontFamily
                                font.weight: Root.Theme.fontWeight
                                color: Root.Theme.on.surface
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            // Weather icon + temp
                            Text {
                                visible: !!locationDelegate.modelData.current
                                text: locationDelegate.modelData.current
                                    ? Root.Weather._weatherIcon(locationDelegate.modelData.current.weatherCode)
                                    : ""
                                font.pixelSize: Root.Theme.fontSizeSmall
                                font.family: Root.Theme.fontFamily
                                color: Root.Theme.sapphire
                            }

                            Text {
                                visible: !!locationDelegate.modelData.current
                                text: locationDelegate.modelData.current
                                    ? locationDelegate.modelData.current.temp + "\u00B0C"
                                    : ""
                                font.pixelSize: Root.Theme.fontSizeSmall
                                font.family: Root.Theme.fontFamily
                                color: Root.Theme.on.surfaceVariant
                            }

                            // Loading indicator
                            Text {
                                visible: !locationDelegate.modelData.current
                                text: "..."
                                font.pixelSize: Root.Theme.fontSizeSmall
                                font.family: Root.Theme.fontFamily
                                color: Root.Theme.outline
                            }
                        }

                        MouseArea {
                            id: locationMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.RightButton
                            onClicked: {
                                if (Root.Weather.locations.length > 1)
                                    Root.Weather.removeLocation(locationDelegate.index)
                            }
                        }
                    }
                }
            }

            // ─── Search Field ───
            Rectangle {
                Layout.fillWidth: true
                height: Root.Theme.itemHeightSmall
                radius: Root.Theme.borderRadiusSmall
                color: Root.Theme.surfaceContainer

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Root.Theme.paddingSmall
                    anchors.rightMargin: Root.Theme.paddingSmall
                    spacing: Root.Theme.spacingSmall

                    Text {
                        text: "\u{F0349}"
                        font.pixelSize: Root.Theme.fontSizeNormal
                        font.family: Root.Theme.fontFamily
                        color: Root.Theme.outline
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        font.pixelSize: Root.Theme.fontSizeSmall
                        font.family: Root.Theme.fontFamily
                        color: Root.Theme.on.surface
                        clip: true
                        activeFocusOnTab: true

                        Text {
                            anchors.fill: parent
                            text: "Add location..."
                            font.pixelSize: Root.Theme.fontSizeSmall
                            font.family: Root.Theme.fontFamily
                            color: Root.Theme.outline
                            visible: !searchInput.text && !searchInput.activeFocus
                            verticalAlignment: Text.AlignVCenter
                        }

                        Keys.onReturnPressed: {
                            if (searchInput.text.trim() !== "") {
                                Root.Weather.addLocation(searchInput.text)
                                searchInput.text = ""
                            }
                        }

                        Keys.onEnterPressed: {
                            if (searchInput.text.trim() !== "") {
                                Root.Weather.addLocation(searchInput.text)
                                searchInput.text = ""
                            }
                        }
                    }

                    // Loading spinner
                    Text {
                        visible: Root.Weather.searchLoading
                        text: "\u{F0772}"
                        font.pixelSize: Root.Theme.fontSizeNormal
                        font.family: Root.Theme.fontFamily
                        color: Root.Theme.sapphire

                        RotationAnimation on rotation {
                            from: 0; to: 360
                            duration: 1000
                            loops: Animation.Infinite
                            running: Root.Weather.searchLoading
                        }
                    }
                }
            }

            // ─── Error Text ───
            Text {
                visible: Root.Weather.searchError !== ""
                text: Root.Weather.searchError
                font.pixelSize: Root.Theme.fontSizeTiny
                font.family: Root.Theme.fontFamily
                color: Root.Theme.error
            }
        }
    }
}
