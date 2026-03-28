pragma Singleton
import QtQuick

PopupServiceBase {
    id: root
    _modalKey: "calendar"

    // Current displayed month/year
    property int displayMonth: new Date().getMonth()   // 0-11
    property int displayYear: new Date().getFullYear()

    // Tab state: 0=Calendar, 1=Weather
    property int activeTab: 0

    function showPopup() {
        // Reset to current month when opening
        var now = new Date()
        root.displayMonth = now.getMonth()
        root.displayYear = now.getFullYear()
        root.activeTab = 0
        root.popupVisible = true
    }

    function showWeatherTab() {
        root.activeTab = 1
        root.popupVisible = true
    }

    // ─── Navigation ───

    function nextMonth() {
        if (root.displayMonth === 11) {
            root.displayMonth = 0
            root.displayYear++
        } else {
            root.displayMonth++
        }
    }

    function prevMonth() {
        if (root.displayMonth === 0) {
            root.displayMonth = 11
            root.displayYear--
        } else {
            root.displayMonth--
        }
    }

    function goToToday() {
        var now = new Date()
        root.displayMonth = now.getMonth()
        root.displayYear = now.getFullYear()
    }

    // ─── Date helpers ───

    function getDaysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate()
    }

    // Returns 0=Sunday, 1=Monday, ... 6=Saturday
    function getFirstDayOfWeek(year, month) {
        return new Date(year, month, 1).getDay()
    }

    function isToday(year, month, day) {
        var now = new Date()
        return day === now.getDate() && month === now.getMonth() && year === now.getFullYear()
    }

    function isCurrentMonth() {
        var now = new Date()
        return root.displayMonth === now.getMonth() && root.displayYear === now.getFullYear()
    }

    // Month name for display
    function monthName(month) {
        var names = ["January", "February", "March", "April", "May", "June",
                     "July", "August", "September", "October", "November", "December"]
        return names[month]
    }
}
