pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Io
import "utils.js" as Utils
import "modals.js" as Modals

QtObject {
    id: root

    // ─── State ───
    property var list: []
    property bool dnd: false
    property bool centerVisible: false
    property var activeScreen: null

    // ─── Per-app rules ───
    // { "appName": { mutePopup: bool, muteSound: bool, blocked: bool } }
    property var appRules: ({})

    function getRule(appName) {
        return root.appRules[appName] ?? { mutePopup: false, muteSound: false, blocked: false }
    }

    function setRule(appName, key, value) {
        var rules = Object.assign({}, root.appRules)
        if (!rules[appName]) rules[appName] = { mutePopup: false, muteSound: false, blocked: false }
        rules[appName][key] = value
        // Remove rule entry if all values are false (cleanup)
        if (!rules[appName].mutePopup && !rules[appName].muteSound && !rules[appName].blocked)
            delete rules[appName]
        root.appRules = rules
        saveTimer.restart()
    }

    function toggleAppMutePopup(appName) {
        var rule = getRule(appName)
        setRule(appName, "mutePopup", !rule.mutePopup)
    }

    function toggleAppMuteSound(appName) {
        var rule = getRule(appName)
        setRule(appName, "muteSound", !rule.muteSound)
    }

    function toggleAppBlocked(appName) {
        var rule = getRule(appName)
        setRule(appName, "blocked", !rule.blocked)
    }

    // ─── Sound ───
    property bool soundEnabled: true
    property real soundVolume: 0.7  // 0.0–1.0
    readonly property string _soundNormal: "/usr/share/sounds/freedesktop/stereo/message-new-instant.oga"
    readonly property string _soundCritical: "/usr/share/sounds/freedesktop/stereo/dialog-warning.oga"

    property Process _soundProc: Process { running: false; command: [] }

    function _playSound(urgency) {
        if (!soundEnabled || dnd || urgency === 0) return
        var file = urgency === 2 ? _soundCritical : _soundNormal
        // paplay volume: 0–65536 (100%)
        var vol = Math.round(soundVolume * 65536)
        _soundProc.command = ["paplay", "--volume=" + vol, file]
        _soundProc.running = true
    }

    // ─── Timestamp reactivity ───
    property int _tick: 0
    property Timer _tickTimer: Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root._tick++
    }

    function relativeTime(then) {
        void(_tick)  // Ensure reactivity on each tick
        var diff = new Date().getTime() - then.getTime()
        var m = Math.floor(diff / 60000)
        if (m < 1) return "now"
        var h = Math.floor(m / 60)
        var d = Math.floor(h / 24)
        if (d > 0) return d + "d"
        if (h > 0) return h + "h"
        return m + "m"
    }

    // ─── Computed ───
    readonly property var active: list.filter(function(n) { return !n.closed })
    property var popups: []  // Explicitly managed — avoids Repeater delegate recreation
    readonly property int count: active.length
    readonly property int criticalCount: active.filter(function(n) { return n.urgency === 2 }).length

    // ─── Grouping by app ───
    readonly property var grouped: {
        void(_tick)  // Re-evaluate on tick for time updates
        var groups = {}
        var order = []
        for (var i = 0; i < active.length; i++) {
            var n = active[i]
            var key = n.appName || "Unknown"
            if (!groups[key]) {
                groups[key] = { appName: key, appIcon: n.appIcon, items: [] }
                order.push(key)
            }
            groups[key].items.push(n)
        }
        return order.map(function(k) { return groups[k] })
    }

    property var _collapsedGroups: ({})

    function toggleGroup(appName) {
        var c = Object.assign({}, root._collapsedGroups)
        c[appName] = !c[appName]
        root._collapsedGroups = c
    }

    function isGroupCollapsed(appName) {
        return root._collapsedGroups[appName] ?? false
    }

    function clearApp(appName) {
        // Batch untrack matching notifications
        for (var i = 0; i < list.length; i++) {
            if ((list[i].appName || "Unknown") === appName && list[i].notification)
                list[i].notification.tracked = false
        }
        // Single atomic filter — one grouped recomputation
        list = list.filter(function(n) {
            return (n.appName || "Unknown") !== appName
        })
        saveTimer.restart()
    }

    // ─── Limits ───
    readonly property int maxNotifications: 100
    readonly property int normalExpiryMs: 24 * 60 * 60 * 1000  // 24 hours

    function _trimList() {
        if (root.list.length <= root.maxNotifications) return
        // Drop oldest non-critical notifications first
        var keep = []
        var dropped = false
        for (var i = 0; i < root.list.length; i++) {
            if (keep.length >= root.maxNotifications) {
                root.list[i].close()
                dropped = true
            } else {
                keep.push(root.list[i])
            }
        }
        if (dropped) root.list = keep
    }

    property Timer _expiryTimer: Timer {
        interval: 60000  // Check every 60s
        repeat: true
        running: true
        onTriggered: {
            var now = Date.now()
            // Collect first, then close — avoids mutating root.active mid-iteration
            var toClose = []
            var snapshot = root.active
            for (var i = 0; i < snapshot.length; i++) {
                var n = snapshot[i]
                if (n.urgency < 2 && now - n.time.getTime() > root.normalExpiryMs)
                    toClose.push(n)
            }
            for (var i = 0; i < toClose.length; i++)
                toClose[i].close()
            if (toClose.length > 0) root.saveTimer.restart()
        }
    }

    // ─── Follow focused monitor ───
    property var activePopupScreen: findFocusedScreen() ?? Quickshell.screens[0]
    property var _focusedMonitor: Hyprland.focusedMonitor
    on_FocusedMonitorChanged: {
        activePopupScreen = findFocusedScreen() ?? Quickshell.screens[0]
        if (centerVisible) activeScreen = findFocusedScreen()
    }

    function findFocusedScreen() {
        return Utils.findFocusedScreen(Hyprland, Quickshell, activeScreen)
    }

    // ─── Notification Server ───
    property var server: NotificationServer {
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true
        keepOnReload: true

        onNotification: notif => {
            var urg = notif.urgency ?? 1
            var appName = notif.appName ?? ""
            var rule = root.getRule(appName)

            // Blocked apps: drop entirely
            if (rule.blocked) {
                notif.tracked = false
                return
            }

            // Replacement: if notification with same ID already exists,
            // update the existing wrapper in-place instead of creating a duplicate
            var replaceIdx = root.list.findIndex(function(n) {
                return n.notification && notif.hasOwnProperty("id") &&
                    n.notification.id === notif.id
            })
            if (replaceIdx >= 0) {
                var existing = root.list[replaceIdx]
                existing.notification = notif
                existing._summary = notif.summary ?? ""
                existing._body = notif.body ?? ""
                existing._appName = notif.appName ?? ""
                existing._appIcon = notif.appIcon ?? ""
                existing._urgency = urg
                existing._image = notif.image ?? ""
                existing.time = new Date()
                if (!rule.muteSound) root._playSound(urg)
                root.saveTimer.restart()
                // Force list reassignment to trigger UI updates
                root.list = root.list.slice()
                return
            }

            // Transient notifications: popup only, never persist
            var isTransient = notif.hints && notif.hints["transient"] === true
            var isLow = urg === 0
            var shouldPersist = !isLow && !isTransient

            // Fullscreen inhibition: suppress popups when workspace has a fullscreen client
            var isFullscreen = Hyprland.focusedWorkspace?.hasFullscreen ?? false
            var isPopup = !root.dnd && !root.centerVisible && !rule.mutePopup && !isFullscreen

            if (!rule.muteSound) root._playSound(urg)
            notif.tracked = shouldPersist
            var wrapper = notifComponent.createObject(root, {
                notification: notif,
                popup: isPopup,
                time: new Date(),
                _summary: notif.summary ?? "",
                _body: notif.body ?? "",
                _appName: notif.appName ?? "",
                _appIcon: notif.appIcon ?? "",
                _urgency: urg,
                _image: notif.image ?? "",
                popupExpiry: isPopup ? Date.now() + root._expiryForUrgency(urg) : 0
            })

            // Persist to list (skip low urgency and transient)
            if (shouldPersist) {
                root.list = [wrapper].concat(root.list)
                root._trimList()
                saveTimer.restart()
            }

            if (isPopup) {
                // Enforce popup cap: dismiss oldest visible to make room
                var activePopups = root.popups.filter(function(p) { return !p.popupDismissed })
                var excess = activePopups.length - 4  // 4 + new one = 5
                for (var i = 0; i < excess; i++) activePopups[i].popupDismissed = true
                root.popups = root.popups.concat([wrapper])
            }
        }
    }

    // ─── Notif Wrapper Component ───
    property var notifComponent: Component {
        QtObject {
            id: notifObj

            property var notification: null
            property bool popup: false
            property date time: new Date()
            property bool closed: false
            property real popupExpiry: 0       // Timestamp when popup should auto-dismiss
            property bool popupAnimated: false  // Whether slide-in animation has played
            property bool popupDismissed: false // Whether exit animation is playing

            // Stored values (populated on creation, used for persistence)
            property string _summary: ""
            property string _body: ""
            property string _appName: ""
            property string _appIcon: ""
            property int _urgency: 1
            property string _image: ""

            // Public accessors (live notification takes priority)
            readonly property string summary: notification?.summary ?? _summary
            readonly property string body: notification?.body ?? _body
            readonly property string appName: notification?.appName ?? _appName
            readonly property string appIcon: notification?.appIcon ?? _appIcon
            readonly property int urgency: notification?.urgency ?? _urgency
            readonly property string image: notification?.image ?? _image
            readonly property real progress: {
                if (!notification || !notification.hints) return -1
                var v = notification.hints["value"]
                if (v !== undefined && v !== null) return Math.max(0, Math.min(1, v / 100))
                return -1  // -1 = no progress
            }

            // Lock system for safe animation destruction
            property var locks: new Set()

            function lock(item) { locks.add(item) }
            function unlock(item) {
                locks.delete(item)
                if (closed && locks.size === 0) remove()
            }

            function close() {
                closed = true
                popupDismissed = true  // Triggers exit animation; delegate calls removePopup after
                if (notification) notification.tracked = false
                if (locks.size === 0) remove()
                saveTimer.restart()
            }

            function remove() {
                root.list = root.list.filter(function(n) { return n !== notifObj })
                notifObj.destroy()
            }

            // Relative timestamp (binds to root._tick for reactivity)
            readonly property string timeStr: root.relativeTime(time)
        }
    }

    // ─── Persistence (FileView) ───
    property string savePath: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/quickshell/notifications.json"

    // Ensure cache directory exists on startup
    property Process _mkdirProc: Process {
        running: true
        command: ["mkdir", "-p", (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/quickshell"]
    }

    property FileView saveFile: FileView {
        path: root.savePath
        blockLoading: false
        watchChanges: false
        preload: false
    }

    property Timer saveTimer: Timer {
        interval: 1000
        onTriggered: {
            var payload = {
                dnd: root.dnd,
                soundEnabled: root.soundEnabled,
                soundVolume: root.soundVolume,
                appRules: root.appRules,
                notifications: root.active.filter(function(n) { return n.urgency >= 1 }).slice(0, root.maxNotifications).map(function(n) {
                    // Only persist file:// images — qsimage:// handles are transient in-memory data
                    var img = n.image || "";
                    if (img.indexOf("image://qsimage/") === 0) img = "";
                    return {
                        time: n.time.getTime(),
                        summary: n.summary,
                        body: n.body,
                        appName: n.appName,
                        appIcon: n.appIcon,
                        urgency: n.urgency,
                        image: img
                    }
                })
            }
            root.saveFile.setText(JSON.stringify(payload))
        }
    }

    // Load saved notifications + DND state on startup
    property Process loadProc: Process {
        running: true
        command: ["cat", root.savePath]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    var parsed = JSON.parse(data)

                    // Support both old format (array) and new format (object)
                    var items = Array.isArray(parsed) ? parsed : (parsed.notifications ?? [])
                    if (!Array.isArray(parsed)) {
                        if (parsed.dnd !== undefined) root.dnd = parsed.dnd
                        if (parsed.soundEnabled !== undefined) root.soundEnabled = parsed.soundEnabled
                        if (parsed.soundVolume !== undefined) root.soundVolume = parsed.soundVolume
                        if (parsed.appRules !== undefined) root.appRules = parsed.appRules
                    }

                    var now = Date.now()
                    var restored = []
                    for (var i = 0; i < items.length; i++) {
                        var n = items[i]
                        // Skip expired normal notifications on restore
                        if ((n.urgency ?? 1) < 2 && now - n.time > root.normalExpiryMs)
                            continue
                        // Enforce max limit on restore
                        if (restored.length >= root.maxNotifications) break
                        var wrapper = notifComponent.createObject(root, {
                            popup: false,
                            time: new Date(n.time),
                            _summary: n.summary ?? "",
                            _body: n.body ?? "",
                            _appName: n.appName ?? "",
                            _appIcon: n.appIcon ?? "",
                            _urgency: n.urgency ?? 1,
                            _image: n.image ?? ""
                        })
                        restored.push(wrapper)
                    }
                    root.list = restored.concat(root.list)
                } catch (e) {
                    console.log("Notifications: no saved history or parse error")
                }
            }
        }
    }

    // ─── Actions ───
    // Batch popup removals to avoid recreating Repeater delegates mid-animation.
    // Multiple exit timers firing close together get coalesced into a single array mutation.
    property var _popupRemovalQueue: []
    property Timer _popupRemovalTimer: Timer {
        interval: 100
        onTriggered: {
            if (root._popupRemovalQueue.length === 0) return
            var toRemove = root._popupRemovalQueue
            root._popupRemovalQueue = []
            root.popups = root.popups.filter(function(n) { return !toRemove.includes(n) })
        }
    }

    function removePopup(wrapper) {
        wrapper.popup = false
        if (popups.includes(wrapper)) {
            _popupRemovalQueue = _popupRemovalQueue.concat([wrapper])
            _popupRemovalTimer.restart()
        }
    }

    function dismiss(notif) {
        notif.close()
    }

    function clearAll() {
        // Batch untrack without triggering per-item reactive updates
        for (var i = 0; i < list.length; i++) {
            if (list[i].notification) list[i].notification.tracked = false
        }
        // Single atomic update — one grouped recomputation instead of O(n²)
        list = []
        popups = []
        saveTimer.restart()
    }

    function invokeAction(wrapper, actionIndex) {
        if (wrapper.notification && wrapper.notification.actions[actionIndex])
            wrapper.notification.actions[actionIndex].invoke()
    }

    function toggleDnd() {
        dnd = !dnd
        saveTimer.restart()
    }

    function toggleCenter() {
        if (centerVisible) {
            hideCenter()
        } else {
            showCenter()
        }
    }

    function showCenter() {
        Modals.closeOthers("notifications")
        activeScreen = findFocusedScreen()
        centerVisible = true
    }

    function hideCenter() {
        centerVisible = false
    }

    // ─── Urgency-based popup duration (ms) ───
    function _expiryForUrgency(urgency) {
        switch (urgency) {
            case 0: return 3000   // Low — brief
            case 2: return 10000  // Critical — lingers
            default: return 5000  // Normal
        }
    }

    Component.onCompleted: {
        var self = root
        Modals.register("notifications", function() { return self.centerVisible }, function() { self.hideCenter() })
    }
}
