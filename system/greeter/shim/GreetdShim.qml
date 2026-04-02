import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd

Item {
    id: shim

    // ── Inputs (set by greeter_shell.qml) ──
    property string themePath: ""
    property string defaultUser: ""
    property string sessionDirs: ""

    // ── State ──
    property int selectedSessionIndex: 0
    property string _pendingPassword: ""
    property string _pendingUser: ""

    // ── SDDM API: sddm object ──
    // Themes call sddm.login(), sddm.reboot(), sddm.powerOff()
    property var sddm: QtObject {
        signal loginFailed()
        signal loginSucceeded()

        function login(user, password, sessionIndex) {
            shim.selectedSessionIndex = sessionIndex;
            shim._pendingPassword = password;
            shim._pendingUser = user;
            Greetd.createSession(user);
        }

        function reboot() {
            Quickshell.execDetached(["systemctl", "reboot"]);
        }

        function powerOff() {
            Quickshell.execDetached(["systemctl", "poweroff"]);
        }
    }

    // ── SDDM API: userModel ──
    // Single-user model. Pre-filled from last-user cache or defaultUser.
    property var userModel: ListModel {
        id: _userModel
        property string lastUser: ""
        property int lastIndex: 0

        function index(row, col) {
            return row;
        }

        function data(row, role) {
            var item = get(row);
            if (!item) return "";
            if (role === (Qt.UserRole + 1)) return item.name;
            if (role === (Qt.UserRole + 2)) return item.realName;
            return item.name;
        }
    }

    // ── SDDM API: sessionModel ──
    // Populated by scanning .desktop files from session_dirs.
    property var sessionModel: ListModel {
        id: _sessionModel
        property int lastIndex: 0
    }

    // ── SDDM API: config ──
    // Parsed from theme's theme.conf (INI key-value pairs).
    property var config: ({})

    // ── Greetd auth flow ──
    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired && shim._pendingPassword !== "") {
                Greetd.respond(shim._pendingPassword);
                shim._pendingPassword = "";
            }
        }

        function onReadyToLaunch() {
            _persistLastUser();
            shim.sddm.loginSucceeded();
        }

        function onAuthFailure(message) {
            shim._pendingPassword = "";
            shim.sddm.loginFailed();
        }
    }

    // ── Initialization ──
    Component.onCompleted: {
        _loadLastUser();
        _scanSessions();
        // theme.conf loaded reactively via FileView when themePath changes
    }

    // ── Load last-user from cache, fallback to defaultUser ──
    Process {
        id: _lastUserProc
        command: ["cat", "/var/lib/greeter/last-user"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                var user = data.trim();
                if (user !== "") {
                    _populateUserModel(user);
                }
            }
        }
        onRunningChanged: {
            if (!running && _userModel.count === 0) {
                // cat failed or file empty — use default
                _populateUserModel(shim.defaultUser || "user");
            }
        }
    }

    function _loadLastUser() {
        _lastUserProc.running = true;
    }

    function _populateUserModel(user) {
        _userModel.clear();
        _userModel.lastUser = user;
        _userModel.append({
            name: user,
            realName: user,
            icon: "",
            homeDir: "/home/" + user
        });
    }

    // ── Persist last-user on successful login ──
    Process {
        id: _persistProc
        running: false
    }

    function _persistLastUser() {
        _persistProc.command = ["bash", "-c",
            "printf '%s\\n' \"$1\" > /var/lib/greeter/last-user", "_", shim._pendingUser];
        _persistProc.running = true;
    }

    // ── Scan session .desktop files ──
    Process {
        id: _sessionScanProc
        running: false
        stdout: SplitParser {
            onRead: data => {
                // Each line: "Name|Exec|File"
                var parts = data.split("|");
                if (parts.length === 3) {
                    _sessionModel.append({
                        name: parts[0],
                        exec: parts[1],
                        file: parts[2]
                    });
                    // Default to Hyprland if found
                    if (parts[0].toLowerCase().indexOf("hyprland") !== -1) {
                        _sessionModel.lastIndex = _sessionModel.count - 1;
                        shim.selectedSessionIndex = _sessionModel.count - 1;
                    }
                }
            }
        }
        onRunningChanged: {
            // Fallback after scan completes: if no sessions found, add Hyprland
            if (!running && _sessionModel.count === 0) {
                _sessionModel.append({
                    name: "Hyprland",
                    exec: "start-hyprland",
                    file: "hyprland.desktop"
                });
            }
        }
    }

    function _scanSessions() {
        // Scan all .desktop files in session_dirs, extract Name and Exec
        // Skip entries with TryExec pointing to a missing binary
        var dirs = shim.sessionDirs.split(":");
        var script = "";
        for (var i = 0; i < dirs.length; i++) {
            var dir = dirs[i].trim();
            if (dir === "") continue;
            // For each .desktop file, extract Name=, Exec=, and TryExec= fields
            script += "for f in " + dir + "/*.desktop; do " +
                "[ -f \"$f\" ] || continue; " +
                "name=$(sed -n 's/^Name=//p' \"$f\" | head -1); " +
                "execl=$(sed -n 's/^Exec=//p' \"$f\" | head -1); " +
                "tryexec=$(sed -n 's/^TryExec=//p' \"$f\" | head -1); " +
                "[ -n \"$tryexec\" ] && ! command -v \"$tryexec\" >/dev/null 2>&1 && continue; " +
                "file=$(basename \"$f\"); " +
                "[ -n \"$name\" ] && [ -n \"$execl\" ] && echo \"${name}|${execl}|${file}\"; " +
                "done; ";
        }
        if (script !== "") {
            _sessionScanProc.command = ["bash", "-c", script];
            _sessionScanProc.running = true;
        }
    }

    // ── Load theme.conf (INI format) via FileView ──
    property FileView _themeConfFile: FileView {
        path: shim.themePath ? Qt.resolvedUrl("file://" + shim.themePath + "/theme.conf") : ""
        onTextChanged: {
            var t = _themeConfFile.text();
            if (!t || t.length === 0) return;
            var lines = t.split("\n");
            var newConfig = {};
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim();
                if (line.startsWith("[") || line === "" || line.startsWith("#")) continue;
                var eqIdx = line.indexOf("=");
                if (eqIdx > 0) {
                    newConfig[line.substring(0, eqIdx).trim()] = line.substring(eqIdx + 1).trim();
                }
            }
            shim.config = newConfig;
        }
    }
}
