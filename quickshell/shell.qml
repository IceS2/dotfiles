import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    // ─── Global Shortcuts (zero-latency, no subprocess) ───
    GlobalShortcut { name: "launcher_toggle"; onPressed: Launcher.toggle() }
    GlobalShortcut { name: "notifications_toggle"; onPressed: Notifications.toggleCenter() }
    GlobalShortcut { name: "clipboard_toggle"; onPressed: Clipboard.toggle() }
    GlobalShortcut { name: "wallpaper_toggle"; onPressed: Wallpaper.togglePopup() }
    GlobalShortcut { name: "theme_toggle"; onPressed: { switchThemeProcess.command = [Wallpaper.themeDir + "/switch-theme.sh", "toggle"]; switchThemeProcess.running = true } }
    GlobalShortcut { name: "power_toggle"; onPressed: PowerMenu.togglePopup() }
    GlobalShortcut { name: "overview_toggle"; onPressed: Overview.togglePopup() }
    GlobalShortcut { name: "osd_volume_up"; onPressed: Audio.adjustVolume(0.05) }
    GlobalShortcut { name: "osd_volume_down"; onPressed: Audio.adjustVolume(-0.05) }
    GlobalShortcut { name: "osd_toggle_mute"; onPressed: Audio.toggleMute() }
    GlobalShortcut { name: "media_toggle_play"; onPressed: Media.togglePlay() }
    GlobalShortcut { name: "media_next"; onPressed: Media.next() }
    GlobalShortcut { name: "media_previous"; onPressed: Media.smartPrevious() }

    // Sentinel overlay — prevents Hyprland's "solitary client" optimization
    // from blocking layer surface creation during fullscreen (hyprwm/Hyprland#11575).
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: true
            color: "transparent"
            anchors.top: true
            anchors.left: true
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-sentinel"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            mask: Region {}
            Rectangle { width: 1; height: 1; color: "transparent" }
        }
    }

    // Border frame - decorative screen border on all monitors
    Variants {
        model: Quickshell.screens

        BorderFrame {
            required property var modelData
            screenObj: modelData
        }
    }

    // Status bars - dynamically created per screen, survives DPMS/hotplug
    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            property var monitor: Hyprland.monitorFor(modelData)
            property bool isPrimary: monitor?.name !== "DP-1"

            screenObj: modelData

            // ─── Start (default slot) ───
            BarPill {
                WorkspacesWidget {
                    workspaceIds: Workspaces.workspaceIdsForMonitor(monitor?.name)
                }
            }

            // Alert pill: only visible when a component breaches thresholds
            BarPill {
                visible: isPrimary && perfWidget.hasAlerts
                active: Performance.popupVisible
                activeColor: perfWidget._maxSeverity >= 2 ? Theme.error : Theme.caution
                PerformanceWidget { id: perfWidget }
            }

            // ─── Center ───
            centerContent: [
                BarPill {
                    visible: isPrimary && Media.hasPlayer
                    active: Media.popupVisible
                    activeColor: Theme.tertiary
                    MediaWidget {}
                }
            ]

            // ─── End ───
            endContent: [
                // System pill: Volume + Network + VPN + Bluetooth
                BarPill {
                    visible: isPrimary
                    active: Audio.popupVisible || Network.popupVisible || Bluetooth.popupVisible
                    activeColor: Audio.popupVisible ? Theme.primary
                        : Network.popupVisible ? Theme.teal
                        : Bluetooth.popupVisible ? Theme.sapphire
                        : Theme.primary
                    VolumeWidget {}
                    BarSeparator {}
                    NetworkWidget {}
                    BarSeparator { visible: Network.vpnConnected }
                    VpnWidget {}
                    BarSeparator { visible: btWidget.visible }
                    BluetoothWidget { id: btWidget }
                },

                // Clock pill
                BarPill {
                    active: Calendar.popupVisible
                    activeColor: Theme.blue
                    ClockWidget {
                        format: "dddd, MMM dd  •  hh:mm:ss"
                    }
                },

                // Tray pill: inline app icons + overflow
                BarPill {
                    visible: isPrimary && trayInline.hasItems
                    active: Tray.popupVisible || Tray.menuVisible
                    activeColor: Theme.on.surface
                    TrayInline { id: trayInline }
                },

                // Session pill: updates (ghost) + notifications + power
                BarPill {
                    visible: isPrimary
                    active: Notifications.centerVisible || Updates.popupVisible || PowerMenu.popupVisible
                    activeColor: PowerMenu.popupVisible ? Theme.error
                        : Updates.popupVisible
                            ? (Updates.hasCritical ? Theme.error : Theme.yellow)
                            : Theme.flamingo
                    UpdatesWidget { id: updatesWidget }
                    BarSeparator { visible: updatesWidget.hasUpdates }
                    SessionWidget {}
                    BarSeparator {}
                    PowerWidget {}
                }
            ]
        }
    }

    // Wallpaper ↔ Theme integration (signals emitted by Wallpaper service)
    Connections {
        target: Wallpaper
        function onOpened() { Theme.saveState() }
        function onConfirmed() { Theme.commitPreview() }
        function onCancelled() { Theme.cancelPreview() }
        function onPreviewColorsReady(colors) { Theme.setPreviewColors(colors) }
    }

    // Launcher - Backdrop (dimming) on all monitors + Box (focused input)
    Variants {
        model: Quickshell.screens

        Backdrop {
            required property var modelData
            screenObj: modelData
            showing: Launcher.visible
            layerNamespace: "quickshell-launcher-backdrop"
            onCloseRequested: Launcher.hide()
        }
    }
    LauncherBox {}

    // Clipboard - Backdrop on all monitors + Box (focused input)
    Variants {
        model: Quickshell.screens

        Backdrop {
            required property var modelData
            screenObj: modelData
            showing: Clipboard.visible
            layerNamespace: "quickshell-clipboard-backdrop"
            onCloseRequested: Clipboard.hide()
        }
    }
    ClipboardBox {}

    // Wallpaper picker - horizontal thumbnail strip
    LazyLoader { loading: true; WallpaperPicker {} }

    IpcHandler {
        target: "wallpaper"
        enabled: true

        function toggle(): void {
            Wallpaper.togglePopup()
        }

        function show(): void {
            Wallpaper.showPopup()
        }

        function hide(): void {
            Wallpaper.hidePopup()
        }

        function random(mode: string): void {
            Wallpaper.applyRandom(mode)
        }
    }

    // Workspace overview - Mission Control-style grid on all monitors
    LazyLoader { loading: true; OverviewPanel {} }

    IpcHandler {
        target: "overview"
        enabled: true

        function toggle(): void {
            Overview.togglePopup()
        }

        function show(): void {
            Overview.showPopup()
        }

        function hide(): void {
            Overview.hidePopup()
        }
    }

    IpcHandler {
        target: "launcher"
        enabled: true

        function toggle(): void {
            Launcher.toggle()
        }

        function show(): void {
            Launcher.show()
        }

        function hide(): void {
            Launcher.hide()
        }
    }

    IpcHandler {
        target: "clipboard"
        enabled: true

        function toggle(): void {
            Clipboard.toggle()
        }

        function show(): void {
            Clipboard.show()
        }

        function hide(): void {
            Clipboard.hide()
        }

        function wipe(): void {
            Clipboard.clearAll()
        }
    }

    // Calendar popup - click clock to view monthly calendar
    LazyLoader { loading: true; CalendarPopup {} }

    IpcHandler {
        target: "calendar"
        enabled: true

        function toggle(): void {
            Calendar.togglePopup()
        }

        function show(): void {
            Calendar.showPopup()
        }

        function hide(): void {
            Calendar.hidePopup()
        }

        function showWeather(): void {
            Calendar.showWeatherTab()
        }
    }

    // System tray - popup grid + context menu
    LazyLoader { loading: true; TrayPopup {} }
    LazyLoader { loading: true; TrayMenu {} }

    IpcHandler {
        target: "tray"
        enabled: true

        function toggle(): void {
            Tray.togglePopup()
        }
    }

    // Media player popup - album art, controls, seek bar
    LazyLoader { loading: true; MediaPopup {} }

    IpcHandler {
        target: "media"
        enabled: true

        function toggle(): void {
            Media.togglePopup()
        }

        function togglePlay(): void {
            Media.togglePlay()
        }

        function next(): void {
            Media.next()
        }

        function previous(): void {
            Media.smartPrevious()
        }

        function toggleShuffle(): void {
            Media.toggleShuffle()
        }

        function cycleLoop(): void {
            Media.cycleLoop()
        }
    }

    // Power menu - fullscreen overlay
    LazyLoader { loading: true; PowerMenuPanel {} }

    IpcHandler {
        target: "power"
        enabled: true

        function toggle(): void {
            PowerMenu.togglePopup()
        }

        function show(): void {
            PowerMenu.showPopup()
        }

        function hide(): void {
            PowerMenu.hidePopup()
        }

        function lock(): void {
            PowerMenu.lockScreen()
        }

        function suspend(): void {
            PowerMenu.suspend()
        }

        function reboot(): void {
            PowerMenu.reboot()
        }

        function shutdown(): void {
            PowerMenu.shutdown()
        }
    }

    // ─── New Popups ───

    // Audio popup - device selector, per-app volume
    LazyLoader { loading: true; AudioPopup {} }

    IpcHandler {
        target: "audio"
        enabled: true

        function toggle(): void {
            Audio.togglePopup()
        }
    }

    // Network popup - WiFi scanning, connection management
    LazyLoader { loading: true; NetworkPopup {} }

    IpcHandler {
        target: "netmenu"
        enabled: true

        function toggle(): void {
            Network.togglePopup()
        }
    }

    // Bluetooth popup - device management
    LazyLoader { loading: true; BluetoothPopup {} }

    IpcHandler {
        target: "bt"
        enabled: true

        function toggle(): void {
            Bluetooth.togglePopup()
        }
    }

    // Performance popup - system monitoring
    LazyLoader { loading: true; PerformancePopup {} }

    IpcHandler {
        target: "perf"
        enabled: true

        function toggle(): void {
            Performance.togglePopup()
        }
    }

    // Updates → Toast bridge (singletons can't reference siblings)
    Connections {
        target: Updates
        function onUpdatesDetected(icon, message) { Toast.show(icon, message) }
    }

    // Updates popup - package update checker
    LazyLoader { loading: true; UpdatesPopup {} }

    IpcHandler {
        target: "updates"
        enabled: true

        function toggle(): void {
            Updates.togglePopup()
        }

        function check(): void {
            Updates.refresh()
        }
    }

    IpcHandler {
        target: "weather"
        enabled: true

        function refresh(): void {
            Weather.refreshAll()
        }
    }

    // Toast popup - system feedback (DND, volume, brightness)
    ToastPopup {}

    // Notification popups - follows focused monitor
    NotificationPopup {
        screenObj: Notifications.activePopupScreen
    }

    // Notification center - single window, follows focused monitor
    NotificationCenter {}

    IpcHandler {
        target: "notifications"
        enabled: true

        function toggle(): void {
            Notifications.toggleCenter()
        }

        function show(): void {
            Notifications.showCenter()
        }

        function hide(): void {
            Notifications.hideCenter()
        }

        function toggleDnd(): void {
            Notifications.toggleDnd()
        }

        function clear(): void {
            Notifications.clearAll()
        }

        function toggleSound(): void {
            Notifications.soundEnabled = !Notifications.soundEnabled
            Notifications.saveTimer.restart()
        }

        function setSoundVolume(vol: string): void {
            Notifications.soundVolume = Math.max(0, Math.min(1, parseFloat(vol)))
            Notifications.saveTimer.restart()
        }

        function muteApp(app: string): void {
            Notifications.setRule(app, "mutePopup", true)
        }

        function unmuteApp(app: string): void {
            Notifications.setRule(app, "mutePopup", false)
        }

        function blockApp(app: string): void {
            Notifications.setRule(app, "blocked", true)
        }

        function unblockApp(app: string): void {
            Notifications.setRule(app, "blocked", false)
        }
    }

    IpcHandler {
        target: "toast"
        enabled: true

        function display(icon: string, text: string): void {
            Toast.show(icon, text)
        }
    }

    // Theme mode switching (static Catppuccin / dynamic wallpaper)
    Process {
        id: switchThemeProcess
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                Theme.reloadColors()
                var mode = Wallpaper.isDynamic ? "dynamic" : "static"
                Toast.show("󰏘", "Theme: " + mode)
            } else {
                Toast.show("󰏘", "Theme switch failed")
            }
        }
    }

    IpcHandler {
        target: "theme"
        enabled: true

        function toggleMode(): void {
            switchThemeProcess.command = [
                Wallpaper.themeDir + "/switch-theme.sh", "toggle"
            ]
            switchThemeProcess.running = true
        }

        function setStatic(): void {
            switchThemeProcess.command = [
                Wallpaper.themeDir + "/switch-theme.sh", "static"
            ]
            switchThemeProcess.running = true
        }

        function setDynamic(): void {
            switchThemeProcess.command = [
                Wallpaper.themeDir + "/switch-theme.sh", "dynamic"
            ]
            switchThemeProcess.running = true
        }

        function reloadColors(): void {
            Theme.reloadColors()
        }
    }

    // Shell management - non-destructive reload (preserves D-Bus, IPC, notification server)
    IpcHandler {
        target: "shell"
        enabled: true

        function reload(): void {
            Quickshell.reload(true)
        }
    }

    IpcHandler {
        target: "osd"
        enabled: true

        function volumeUp(): void {
            Audio.adjustVolume(0.05)
        }

        function volumeDown(): void {
            Audio.adjustVolume(-0.05)
        }

        function toggleMute(): void {
            Audio.toggleMute()
        }
    }

    Connections {
        target: Audio

        function onVolumePercentChanged() {
            Qt.callLater(() => Toast.showProgress(Audio.volumeIcon, Audio.volumePercent / 100, Audio.muted))
        }

        function onMutedChanged() {
            Qt.callLater(() => Toast.showProgress(Audio.volumeIcon, Audio.volumePercent / 100, Audio.muted))
        }
    }
}
