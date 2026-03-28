pragma Singleton
import Quickshell

SystemClock {
    id: root
    precision: SystemClock.Seconds

    function formatTime(format) {
        return Qt.formatDateTime(root.date, format)
    }
}
