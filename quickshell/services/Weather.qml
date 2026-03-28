pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Weather Service - wttr.in API
 *
 * Fetches weather data for saved locations using wttr.in JSON API.
 * Primary location updates every 30 minutes; others update on popup open.
 * Location list persists across sessions.
 */
QtObject {
    id: root

    function fetchNonPrimaryIfNeeded() {
        _fetchAllNonPrimary()
    }

    // ─── Location State ───

    property var locations: []
    property int primaryIndex: 0
    property bool loading: false
    property bool searchLoading: false
    property string searchError: ""
    property var _lastUpdated: null

    // ─── Primary Computed Properties ───

    readonly property var _primary: locations.length > 0 && primaryIndex >= 0 && primaryIndex < locations.length
        ? locations[primaryIndex] : null

    readonly property string primaryName: _primary ? _primary.name : ""
    readonly property string primaryTemp: _primary && _primary.current
        ? _primary.current.temp + "\u00B0C" : "--"
    readonly property string primaryIcon: _primary && _primary.current
        ? _weatherIcon(_primary.current.weatherCode) : "\u{F0590}"
    readonly property string primaryCondition: _primary && _primary.current
        ? _primary.current.condition : ""
    readonly property string primaryFeelsLike: _primary && _primary.current
        ? _primary.current.feelsLike + "\u00B0" : "--"
    readonly property string primaryHumidity: _primary && _primary.current
        ? _primary.current.humidity + "%" : "--"
    readonly property string primaryWind: _primary && _primary.current
        ? _primary.current.wind + " km/h" : "--"
    readonly property string primaryUv: _primary && _primary.current
        ? _primary.current.uv : "--"
    readonly property var primaryForecast: _primary && _primary.forecast
        ? _primary.forecast : []

    property int _updateTick: 0

    readonly property string lastUpdatedText: {
        // _updateTick forces re-evaluation every minute
        var tick = _updateTick
        if (!_lastUpdated) return ""
        var now = new Date()
        var diff = Math.floor((now.getTime() - _lastUpdated.getTime()) / 60000)
        if (diff < 1) return "just now"
        if (diff < 60) return diff + "m ago"
        return Math.floor(diff / 60) + "h ago"
    }

    // ─── Polling Timer (30 min) ───

    property Timer pollTimer: Timer {
        interval: 1800000
        running: root._initialized
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (root.locations.length > 0)
                root._fetchLocation(root.primaryIndex)
        }
    }

    property bool _initialized: false

    // Refresh "Xm ago" text every minute
    property Timer lastUpdatedTimer: Timer {
        interval: 60000
        running: root._lastUpdated !== null
        repeat: true
        onTriggered: root._updateTick++
    }

    // ─── Weather Code → Nerd Font Icon ───

    function _weatherIcon(code) {
        var c = parseInt(code)
        if (c === 113) return "\u{F0599}" // 󰖙 clear
        if (c === 116) return "\u{F0590}" // 󰖐 partly cloudy
        if (c === 119 || c === 122) return "\u{F0590}" // 󰖐 cloudy
        if (c === 143 || c === 248 || c === 260) return "\u{F0591}" // 󰖑 fog
        if ([176,263,266,293,296,299,302,305,308,353,356,359].indexOf(c) >= 0) return "\u{F0596}" // 󰖖 rain
        if ([179,227,230,323,326,329,332,335,338,368,371].indexOf(c) >= 0) return "\u{F0598}" // 󰖘 snow
        if ([200,386,389,392,395].indexOf(c) >= 0) return "\u{F0593}" // 󰖓 thunder
        if ([182,185,281,284,311,314,317,320,350,362,365].indexOf(c) >= 0) return "\u{F067F}" // 󰙿 sleet
        return "\u{F0590}" // default: partly cloudy
    }

    // ─── Fetch Queue ───

    property var _fetchQueue: []
    property bool _fetching: false

    function _fetchLocation(index) {
        if (index < 0 || index >= locations.length) return
        var loc = locations[index]
        if (!loc || !loc.name) return

        fetchProcess.command = ["curl", "-sf", "--max-time", "10",
            "https://wttr.in/" + encodeURIComponent(loc.name) + "?format=j1&m"]
        root._currentFetchIndex = index
        root.loading = (index === root.primaryIndex)
        fetchProcess.running = true
    }

    property int _currentFetchIndex: -1
    property string _fetchBuffer: ""

    property Process fetchProcess: Process {
        running: false
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => { root._fetchBuffer += data }
        }
        onExited: (code, status) => {
            if (code === 0 && root._fetchBuffer.length > 0)
                root._parseFetchResult(root._currentFetchIndex, root._fetchBuffer)
            else if (code !== 0)
                console.warn("Weather: fetch failed for index", root._currentFetchIndex)
            root._fetchBuffer = ""
            root.loading = false
            root._processQueue()
        }
    }

    function _parseFetchResult(index, data) {
        try {
            var json = JSON.parse(data)
            var cc = json.current_condition[0]
            var current = {
                temp: cc.temp_C,
                feelsLike: cc.FeelsLikeC,
                humidity: cc.humidity,
                wind: cc.windspeedKmph,
                uv: cc.uvIndex,
                condition: cc.weatherDesc[0].value,
                weatherCode: cc.weatherCode
            }

            var forecast = []
            var weather = json.weather || []
            for (var i = 0; i < Math.min(3, weather.length); i++) {
                var day = weather[i]
                var d = new Date(day.date)
                var dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                forecast.push({
                    date: day.date,
                    day: i === 0 ? "Today" : dayNames[d.getDay()],
                    maxTemp: day.maxtempC,
                    minTemp: day.mintempC,
                    icon: root._weatherIcon(day.hourly[4].weatherCode), // midday hour
                    condition: day.hourly[4].weatherDesc[0].value
                })
            }

            var locs = root.locations.slice()
            locs[index] = Object.assign({}, locs[index], { current: current, forecast: forecast })
            root.locations = locs

            if (index === root.primaryIndex) {
                root._lastUpdated = new Date()
            }
        } catch (e) {
            console.warn("Weather: parse error:", e)
        }
    }

    function _fetchAllNonPrimary() {
        root._fetchQueue = []
        for (var i = 0; i < locations.length; i++) {
            if (i !== primaryIndex && (!locations[i].current))
                root._fetchQueue.push(i)
        }
        root._processQueue()
    }

    function _processQueue() {
        if (root._fetchQueue.length === 0) return
        if (fetchProcess.running) return
        var next = root._fetchQueue.shift()
        root._fetchLocation(next)
    }

    // ─── Location Management ───

    function addLocation(name) {
        if (!name || name.trim() === "") return
        var trimmed = name.trim()

        // Check duplicate
        for (var i = 0; i < locations.length; i++) {
            if (locations[i].name.toLowerCase() === trimmed.toLowerCase()) {
                root.searchError = "Location already added"
                return
            }
        }

        root.searchError = ""
        root.searchLoading = true
        searchProcess.command = ["curl", "-sf", "--max-time", "10",
            "https://wttr.in/" + encodeURIComponent(trimmed) + "?format=j1&m"]
        root._pendingLocationName = trimmed
        searchProcess.running = true
    }

    property string _pendingLocationName: ""
    property string _searchBuffer: ""

    property Process searchProcess: Process {
        running: false
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => { root._searchBuffer += data }
        }
        onExited: (code, status) => {
            root.searchLoading = false
            if (code !== 0) {
                root._searchBuffer = ""
                root.searchError = "Location not found"
                return
            }

            try {
                var json = JSON.parse(root._searchBuffer)
                var cc = json.current_condition[0]
                var current = {
                    temp: cc.temp_C,
                    feelsLike: cc.FeelsLikeC,
                    humidity: cc.humidity,
                    wind: cc.windspeedKmph,
                    uv: cc.uvIndex,
                    condition: cc.weatherDesc[0].value,
                    weatherCode: cc.weatherCode
                }

                var forecast = []
                var weather = json.weather || []
                for (var i = 0; i < Math.min(3, weather.length); i++) {
                    var day = weather[i]
                    var d = new Date(day.date)
                    var dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                    forecast.push({
                        date: day.date,
                        day: i === 0 ? "Today" : dayNames[d.getDay()],
                        maxTemp: day.maxtempC,
                        minTemp: day.mintempC,
                        icon: root._weatherIcon(day.hourly[4].weatherCode),
                        condition: day.hourly[4].weatherDesc[0].value
                    })
                }

                // Use nearest area name if available for better display
                var displayName = root._pendingLocationName
                if (json.nearest_area && json.nearest_area[0]) {
                    var area = json.nearest_area[0]
                    if (area.areaName && area.areaName[0] && area.areaName[0].value)
                        displayName = area.areaName[0].value
                }

                var locs = root.locations.slice()
                locs.push({ name: displayName, current: current, forecast: forecast })
                root.locations = locs

                // If this is the first location, set as primary
                if (locs.length === 1) {
                    root.primaryIndex = 0
                    root._lastUpdated = new Date()
                }

                root._save()
            } catch (e) {
                console.warn("Weather: search parse error:", e)
                root.searchError = "Invalid location"
            }
            root._searchBuffer = ""
        }
    }

    function removeLocation(index) {
        if (locations.length <= 1) return
        if (index < 0 || index >= locations.length) return

        var locs = root.locations.slice()
        locs.splice(index, 1)

        if (root.primaryIndex === index) {
            root.primaryIndex = 0
        } else if (root.primaryIndex > index) {
            root.primaryIndex--
        }

        root.locations = locs
        root._save()
    }

    function setPrimary(index) {
        if (index < 0 || index >= locations.length) return
        root.primaryIndex = index
        root._fetchLocation(index)
        root._save()
    }

    function cyclePrimary(delta) {
        if (locations.length <= 1) return
        var next = (primaryIndex + delta + locations.length) % locations.length
        setPrimary(next)
    }

    function refreshAll() {
        for (var i = 0; i < locations.length; i++) {
            root._fetchQueue.push(i)
        }
        if (!fetchProcess.running) root._processQueue()
    }

    // ─── Persistence ───

    property string _cacheDir: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/quickshell"
    property string _cachePath: _cacheDir + "/weather.json"

    property FileView _cacheFile: FileView {
        path: root._cachePath
        watchChanges: false
        blockLoading: true
        preload: false
    }

    property Timer saveTimer: Timer {
        interval: 1000
        repeat: false
        onTriggered: root._doSave()
    }

    function _save() {
        saveTimer.restart()
    }

    function _doSave() {
        var names = []
        for (var i = 0; i < locations.length; i++) {
            names.push({ name: locations[i].name })
        }
        var data = JSON.stringify({ locations: names, primaryIndex: root.primaryIndex }, null, 2)
        _cacheFile.setText(data)
    }

    property Process _loadProcess: Process {
        running: false
        command: ["cat", root._cachePath]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    var saved = JSON.parse(data)
                    if (saved.locations && saved.locations.length > 0) {
                        var locs = []
                        for (var i = 0; i < saved.locations.length; i++) {
                            locs.push({ name: saved.locations[i].name, current: null, forecast: null })
                        }
                        root.locations = locs
                        root.primaryIndex = saved.primaryIndex || 0
                        if (root.primaryIndex >= locs.length) root.primaryIndex = 0
                    }
                } catch (e) {
                    console.warn("Weather: failed to load cache:", e)
                }
            }
        }
        onExited: {
            root._initialized = true
        }
    }

    property Process _mkdirProcess: Process {
        running: false
        command: ["mkdir", "-p", root._cacheDir]
        onExited: {
            root._loadProcess.running = true
        }
    }

    Component.onCompleted: {
        _mkdirProcess.running = true
    }
}
