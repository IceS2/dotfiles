pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell.Services.Mpris

PopupServiceBase {
    id: root
    _modalKey: "media"

    // ─── Player Management ───

    property var players: Mpris.players.values ?? []
    property var activePlayer: null
    property bool _manualSelection: false

    onPlayersChanged: _refreshActivePlayer()

    function _refreshActivePlayer() {
        var ps = root.players
        if (!ps || ps.length === 0) {
            root.activePlayer = null
            root._manualSelection = false
            return
        }
        // If manually selected and still valid, keep it
        if (root._manualSelection && root.activePlayer) {
            for (var i = 0; i < ps.length; i++) {
                if (ps[i] === root.activePlayer) return
            }
        }
        // Auto-select: prefer a playing player
        for (var i = 0; i < ps.length; i++) {
            if (ps[i].isPlaying) {
                root.activePlayer = ps[i]
                root._manualSelection = false
                return
            }
        }
        // If current player is still valid (just not playing), keep it
        if (root.activePlayer && !root._manualSelection) {
            for (var i = 0; i < ps.length; i++) {
                if (ps[i] === root.activePlayer) return
            }
        }
        // Fallback to first player
        root.activePlayer = ps[0]
        root._manualSelection = false
    }

    // Auto-switch to a playing player when current is paused (no manual override)
    property Timer _autoSwitchTimer: Timer {
        interval: 1000
        repeat: true
        running: root.players.length > 1 && !root._manualSelection && !root.isPlaying
        onTriggered: {
            for (var i = 0; i < root.players.length; i++) {
                if (root.players[i].isPlaying) {
                    root.activePlayer = root.players[i]
                    return
                }
            }
        }
    }

    function setPlayer(player) {
        root.activePlayer = player
        root._manualSelection = true
    }

    function cyclePlayer() {
        var ps = root.players
        if (ps.length < 2) return
        var idx = -1
        for (var i = 0; i < ps.length; i++) {
            if (ps[i] === root.activePlayer) { idx = i; break }
        }
        setPlayer(ps[(idx + 1) % ps.length])
    }

    // ─── Convenience Properties ───

    readonly property bool hasPlayer: activePlayer !== null
    readonly property bool isPlaying: activePlayer ? activePlayer.isPlaying : false
    readonly property string title: activePlayer ? activePlayer.trackTitle : ""
    readonly property string artist: activePlayer ? activePlayer.trackArtist : ""
    readonly property string album: activePlayer ? activePlayer.trackAlbum : ""
    readonly property string artUrl: activePlayer ? activePlayer.trackArtUrl : ""
    readonly property real length: activePlayer ? activePlayer.length : 0
    readonly property string playIcon: isPlaying ? "󰏤" : "󰐊"
    readonly property string playerName: activePlayer ? activePlayer.identity : ""

    // Shuffle & loop
    readonly property bool shuffleSupported: activePlayer ? activePlayer.shuffleSupported : false
    readonly property bool shuffle: activePlayer ? activePlayer.shuffle : false
    readonly property bool loopSupported: activePlayer ? activePlayer.loopSupported : false
    readonly property int loopState: activePlayer ? activePlayer.loopState : MprisLoopState.None
    readonly property string loopIcon: {
        if (loopState === MprisLoopState.Track) return "󰑘"
        if (loopState === MprisLoopState.Playlist) return "󰑖"
        return "󰑗"
    }
    readonly property bool loopActive: loopState !== MprisLoopState.None
    readonly property string shuffleIcon: "󰒝"

    // Position (polled — MPRIS doesn't push position updates)
    property real position: 0
    readonly property real progress: length > 0 ? Math.min(position / length, 1.0) : 0

    // ─── Position Polling ───

    property Timer _posTimer: Timer {
        interval: 1000
        repeat: true
        running: root.isPlaying
        onTriggered: root._pollPosition()
    }

    function _pollPosition() {
        if (root.activePlayer)
            root.position = root.activePlayer.position
    }

    onActivePlayerChanged: _pollPosition()
    onIsPlayingChanged: _pollPosition()
    onTitleChanged: _pollPosition()

    // ─── Transport Controls ───

    function togglePlay() {
        if (activePlayer && activePlayer.canTogglePlaying)
            activePlayer.togglePlaying()
    }

    function next() {
        if (activePlayer && activePlayer.canGoNext)
            activePlayer.next()
    }

    function previous() {
        if (activePlayer && activePlayer.canGoPrevious)
            activePlayer.previous()
    }

    function smartPrevious() {
        if (!activePlayer) return
        if (position > 5 && activePlayer.canSeek) {
            seek(0)
        } else if (activePlayer.canGoPrevious) {
            activePlayer.previous()
        }
    }

    function toggleShuffle() {
        if (activePlayer && activePlayer.canControl && activePlayer.shuffleSupported)
            activePlayer.shuffle = !activePlayer.shuffle
    }

    function cycleLoop() {
        if (!activePlayer || !activePlayer.canControl || !activePlayer.loopSupported) return
        var current = activePlayer.loopState
        if (current === MprisLoopState.None)
            activePlayer.loopState = MprisLoopState.Playlist
        else if (current === MprisLoopState.Playlist)
            activePlayer.loopState = MprisLoopState.Track
        else
            activePlayer.loopState = MprisLoopState.None
    }

    function seek(seconds) {
        if (activePlayer && activePlayer.canSeek) {
            var offset = seconds - activePlayer.position
            activePlayer.seek(offset)
            root.position = seconds
        }
    }

    // ─── Raise Player Window ───

    property Process _raiseProcess: Process {
        onExited: running = false
    }

    function raisePlayer() {
        if (!activePlayer) return
        hidePopup()
        _raiseProcess.command = ["hyprctl", "dispatch", "focuswindow", "class:" + activePlayer.identity.toLowerCase()]
        _raiseProcess.running = true
    }

    // ─── Utility ───

    function formatTime(seconds) {
        if (isNaN(seconds) || seconds < 0) return "0:00"
        var s = Math.floor(seconds)
        var h = Math.floor(s / 3600)
        var m = Math.floor((s % 3600) / 60)
        var sec = s % 60
        if (h > 0)
            return h + ":" + (m < 10 ? "0" : "") + m + ":" + (sec < 10 ? "0" : "") + sec
        return m + ":" + (sec < 10 ? "0" : "") + sec
    }

    Component.onCompleted: _refreshActivePlayer()
}
