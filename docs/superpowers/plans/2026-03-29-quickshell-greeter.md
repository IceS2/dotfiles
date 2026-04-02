# QuickShell Greeter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace ReGreet with a QuickShell-based greetd greeter that runs qylock SDDM themes unmodified via a compatibility shim.

**Architecture:** A `GreetdShim.qml` fakes the SDDM API surface (`sddm`, `userModel`, `sessionModel`, `config`) backed by `Quickshell.Services.Greetd`. A `greeter_shell.qml` entry point loads any qylock theme's `Main.qml` via a `Loader`, and Qt5-to-Qt6 import shims (from qylock) transparently redirect old imports. A launcher script reads `greeter.conf` and sets env vars before starting QuickShell.

**Tech Stack:** QuickShell (QML), Quickshell.Services.Greetd, greetd, Hyprland (greeter compositor), qylock themes (forked)

**Spec:** `docs/superpowers/specs/2026-03-29-quickshell-greeter-design.md`

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `system/greeter/config.toml` | Create | greetd daemon config |
| `system/greeter/hyprland.conf` | Create | Greeter Hyprland compositor config |
| `system/greeter/greeter.conf` | Create | Theme, default user, session dirs |
| `system/greeter/launch.sh` | Create | Sets env vars, launches QuickShell |
| `system/greeter/greeter_shell.qml` | Create | QuickShell entry point |
| `system/greeter/shim/GreetdShim.qml` | Create | SDDM API compat layer (Greetd backend) |
| `system/greeter/imports/QtGraphicalEffects/qmldir` | Create | Module registration (25 effects) |
| `system/greeter/imports/QtGraphicalEffects/*.qml` | Create | 25 Qt5→Qt6 effect redirects |
| `system/greeter/imports/QtMultimedia/qmldir` | Create | Module registration |
| `system/greeter/imports/QtMultimedia/Video.qml` | Create | Qt5 Video→Qt6 MediaPlayer+VideoOutput proxy |
| `system/greeter/imports/QtMultimedia/MediaPlayer.qml` | Create | Enum shim for MediaPlayer.Infinite |
| `system/greeter/imports/QtMultimedia/VideoOutput.qml` | Create | Enum shim for FillMode constants |
| `system/greeter/imports/SddmComponents/qmldir` | Create | Module registration |
| `system/greeter/imports/SddmComponents/TextConstants.qml` | Create | Static SDDM text strings |
| `system/greeter/imports/SddmComponents/LayoutMirroring.qml` | Create | No-op stub |
| `system/greeter/install.sh` | Create | Install greeter + clone themes |
| `system/install.sh` | Edit | Add greeter block alongside regreet block |

---

### Task 1: Create directory structure and static config files

**Files:**
- Create: `system/greeter/config.toml`
- Create: `system/greeter/hyprland.conf`
- Create: `system/greeter/greeter.conf`
- Create: `system/greeter/launch.sh`

- [ ] **Step 1: Create `system/greeter/config.toml`**

This is the greetd daemon config. Identical to the current regreet version — greetd launches Hyprland with the greeter config.

```toml
# greetd main configuration
# Copied to: /etc/greetd/config.toml (cannot be symlinked for security)

[terminal]
vt = 1

[default_session]
command = "env GTK_USE_PORTAL=0 GDK_DEBUG=no-portals start-hyprland -- --config /etc/greetd/hyprland.conf"
user = "greeter"
```

- [ ] **Step 2: Create `system/greeter/hyprland.conf`**

Based on `system/regreet/hyprland.conf`. Changes: removed regreet window rule, exec-once launches our greeter script instead of regreet.

```
# Hyprland Config for QuickShell Greeter
# Copied to: /etc/greetd/hyprland.conf

# === Performance ===
env = GTK_USE_PORTAL,0
env = GDK_DEBUG,no-portals

# === Rendering Quality ===
env = GDK_SCALE,1
env = GDK_DPI_SCALE,1
env = XCURSOR_SIZE,24

# === NVIDIA Settings ===
env = LIBVA_DRIVER_NAME,nvidia
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = __GL_GSYNC_ALLOWED,1
env = __GL_VRR_ALLOWED,0

# === Monitor Configuration - BOTH ENABLED ===
monitor = DP-2,2560x1440@165,0x0,1
monitor = DP-1,2560x1440@165,-1440x-560,1,transform,1

# === Cursor (NVIDIA) ===
cursor {
    no_hardware_cursors = true
}

# === Appearance ===
general {
    gaps_in = 0
    gaps_out = 0
    border_size = 0
}

decoration {
    rounding = 0
}

animations {
    enabled = false
}

misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
    force_default_wallpaper = 0
}

workspace = 1, monitor:DP-2, default:true
workspace = 2, monitor:DP-2

# === Launch QuickShell Greeter ===
exec-once = /etc/greetd/launch.sh; hyprctl dispatch exit
```

- [ ] **Step 3: Create `system/greeter/greeter.conf`**

```ini
# QuickShell Greeter Configuration
# Copied to: /etc/greetd/greeter.conf

[greeter]
theme = pixel-rainyroom
default_user = ice
session_dirs = /usr/share/wayland-sessions:/usr/share/xsessions
```

- [ ] **Step 4: Create `system/greeter/launch.sh`**

Reads `greeter.conf`, sets env vars (`QS_THEME` for Video.qml path resolution, `QML2_IMPORT_PATH` for import shims), launches QuickShell.

```bash
#!/usr/bin/env bash
# QuickShell Greeter Launcher
# Reads greeter.conf and launches QuickShell with correct env vars.
# Called from hyprland.conf exec-once.

CONF="/etc/greetd/greeter.conf"

# Parse theme from greeter.conf
THEME=$(sed -n 's/^theme *= *//p' "$CONF" 2>/dev/null)
export QS_THEME="${THEME:-pixel-rainyroom}"

# Import shims path (Qt5→Qt6 bridges for SDDM themes)
export QML2_IMPORT_PATH="/etc/greetd/imports"

exec quickshell -p /etc/greetd/greeter_shell.qml
```

- [ ] **Step 5: Verify directory structure**

Run: `find system/greeter -type f | sort`

Expected:
```
system/greeter/config.toml
system/greeter/greeter.conf
system/greeter/hyprland.conf
system/greeter/launch.sh
```

- [ ] **Step 6: Commit**

```bash
git add system/greeter/config.toml system/greeter/hyprland.conf system/greeter/greeter.conf system/greeter/launch.sh
git commit -m "feat(greeter): add config files and launcher script"
```

---

### Task 2: Create QtGraphicalEffects import shims

**Files:**
- Create: `system/greeter/imports/QtGraphicalEffects/qmldir`
- Create: 25 QML shim files in `system/greeter/imports/QtGraphicalEffects/`

Every shim follows the same two-line pattern — redirect `import QtGraphicalEffects 1.x` to `Qt5Compat.GraphicalEffects`.

- [ ] **Step 1: Create `imports/QtGraphicalEffects/qmldir`**

Module registration file. Registers each effect at both version 1.0 and 1.15 (themes use either).

```
module QtGraphicalEffects
Blend 1.15 Blend.qml
BrightnessContrast 1.15 BrightnessContrast.qml
ColorOverlay 1.15 ColorOverlay.qml
Colorize 1.15 Colorize.qml
ConicalGradient 1.15 ConicalGradient.qml
Desaturate 1.15 Desaturate.qml
DirectionalBlur 1.15 DirectionalBlur.qml
Displace 1.15 Displace.qml
DropShadow 1.15 DropShadow.qml
FastBlur 1.15 FastBlur.qml
GammaAdjust 1.15 GammaAdjust.qml
GaussianBlur 1.15 GaussianBlur.qml
Glow 1.15 Glow.qml
HueSaturation 1.15 HueSaturation.qml
InnerShadow 1.15 InnerShadow.qml
LevelAdjust 1.15 LevelAdjust.qml
LinearGradient 1.15 LinearGradient.qml
MaskedBlur 1.15 MaskedBlur.qml
OpacityMask 1.15 OpacityMask.qml
RadialBlur 1.15 RadialBlur.qml
RadialGradient 1.15 RadialGradient.qml
RectangularGlow 1.15 RectangularGlow.qml
RecursiveBlur 1.15 RecursiveBlur.qml
ThresholdMask 1.15 ThresholdMask.qml
ZoomBlur 1.15 ZoomBlur.qml
Blend 1.0 Blend.qml
BrightnessContrast 1.0 BrightnessContrast.qml
ColorOverlay 1.0 ColorOverlay.qml
Colorize 1.0 Colorize.qml
ConicalGradient 1.0 ConicalGradient.qml
Desaturate 1.0 Desaturate.qml
DirectionalBlur 1.0 DirectionalBlur.qml
Displace 1.0 Displace.qml
DropShadow 1.0 DropShadow.qml
FastBlur 1.0 FastBlur.qml
GammaAdjust 1.0 GammaAdjust.qml
GaussianBlur 1.0 GaussianBlur.qml
Glow 1.0 Glow.qml
HueSaturation 1.0 HueSaturation.qml
InnerShadow 1.0 InnerShadow.qml
LevelAdjust 1.0 LevelAdjust.qml
LinearGradient 1.0 LinearGradient.qml
MaskedBlur 1.0 MaskedBlur.qml
OpacityMask 1.0 OpacityMask.qml
RadialBlur 1.0 RadialBlur.qml
RadialGradient 1.0 RadialGradient.qml
RectangularGlow 1.0 RectangularGlow.qml
RecursiveBlur 1.0 RecursiveBlur.qml
ThresholdMask 1.0 ThresholdMask.qml
ZoomBlur 1.0 ZoomBlur.qml
```

- [ ] **Step 2: Create all 25 effect shim files**

Every file follows the identical pattern — only the component name differs. Create each file at `system/greeter/imports/QtGraphicalEffects/<Name>.qml`:

**Pattern:**
```qml
import Qt5Compat.GraphicalEffects as T
T.<Name> {}
```

**Complete file list (25 files):**

`Blend.qml`:
```qml
import Qt5Compat.GraphicalEffects as T
T.Blend {}
```

`BrightnessContrast.qml`:
```qml
import Qt5Compat.GraphicalEffects as T
T.BrightnessContrast {}
```

`ColorOverlay.qml`:
```qml
import Qt5Compat.GraphicalEffects as T
T.ColorOverlay {}
```

`Colorize.qml`:
```qml
import Qt5Compat.GraphicalEffects as T
T.Colorize {}
```

`ConicalGradient.qml`:
```qml
import Qt5Compat.GraphicalEffects as T
T.ConicalGradient {}
```

`Desaturate.qml`:
```qml
import Qt5Compat.GraphicalEffects as T
T.Desaturate {}
```

`DirectionalBlur.qml`:
```qml
import Qt5Compat.GraphicalEffects as T
T.DirectionalBlur {}
```

`Displace.qml`:
```qml
import Qt5Compat.GraphicalEffects as T
T.Displace {}
```

`DropShadow.qml`:
```qml
import Qt5Compat.GraphicalEffects as T
T.DropShadow {}
```

`FastBlur.qml`:
```qml
import Qt5Compat.GraphicalEffects as T
T.FastBlur {}
```

`GammaAdjust.qml`:
```qml
import Qt5Compat.GraphicalEffects as T
T.GammaAdjust {}
```

`GaussianBlur.qml`:
```qml
import Qt5Compat.GraphicalEffects as T
T.GaussianBlur {}
```

`Glow.qml`:
```qml
import Qt5Compat.GraphicalEffects as T
T.Glow {}
```

`HueSaturation.qml`:
```qml
import Qt5Compat.GraphicalEffects as T
T.HueSaturation {}
```

`InnerShadow.qml`:
```qml
import Qt5Compat.GraphicalEffects as T
T.InnerShadow {}
```

`LevelAdjust.qml`:
```qml
import Qt5Compat.GraphicalEffects as T
T.LevelAdjust {}
```

`LinearGradient.qml`:
```qml
import Qt5Compat.GraphicalEffects as T
T.LinearGradient {}
```

`MaskedBlur.qml`:
```qml
import Qt5Compat.GraphicalEffects as T
T.MaskedBlur {}
```

`OpacityMask.qml`:
```qml
import Qt5Compat.GraphicalEffects as T
T.OpacityMask {}
```

`RadialBlur.qml`:
```qml
import Qt5Compat.GraphicalEffects as T
T.RadialBlur {}
```

`RadialGradient.qml`:
```qml
import Qt5Compat.GraphicalEffects as T
T.RadialGradient {}
```

`RectangularGlow.qml`:
```qml
import Qt5Compat.GraphicalEffects as T
T.RectangularGlow {}
```

`RecursiveBlur.qml`:
```qml
import Qt5Compat.GraphicalEffects as T
T.RecursiveBlur {}
```

`ThresholdMask.qml`:
```qml
import Qt5Compat.GraphicalEffects as T
T.ThresholdMask {}
```

`ZoomBlur.qml`:
```qml
import Qt5Compat.GraphicalEffects as T
T.ZoomBlur {}
```

- [ ] **Step 3: Verify file count**

Run: `ls system/greeter/imports/QtGraphicalEffects/*.qml | wc -l`

Expected: `25`

- [ ] **Step 4: Commit**

```bash
git add system/greeter/imports/QtGraphicalEffects/
git commit -m "feat(greeter): add QtGraphicalEffects Qt5-to-Qt6 import shims"
```

---

### Task 3: Create QtMultimedia and SddmComponents import shims

**Files:**
- Create: `system/greeter/imports/QtMultimedia/qmldir`
- Create: `system/greeter/imports/QtMultimedia/Video.qml`
- Create: `system/greeter/imports/QtMultimedia/MediaPlayer.qml`
- Create: `system/greeter/imports/QtMultimedia/VideoOutput.qml`
- Create: `system/greeter/imports/SddmComponents/qmldir`
- Create: `system/greeter/imports/SddmComponents/TextConstants.qml`
- Create: `system/greeter/imports/SddmComponents/LayoutMirroring.qml`

- [ ] **Step 1: Create `imports/QtMultimedia/qmldir`**

```
module QtMultimedia
Video 5.15 Video.qml
MediaPlayer 5.15 MediaPlayer.qml
VideoOutput 5.15 VideoOutput.qml
```

- [ ] **Step 2: Create `imports/QtMultimedia/Video.qml`**

Full Qt5 Video → Qt6 MediaPlayer+VideoOutput proxy. Resolves theme-relative asset paths using `QS_THEME` env var (set by `launch.sh`) and `Quickshell.shellDir` + `themes_link/` (symlink created by install script).

```qml
import QtQuick 2.15
import QtMultimedia 6.0 as Native
import Quickshell

Item {
    id: root
    anchors.fill: parent
    implicitWidth: videoOut.implicitWidth
    implicitHeight: videoOut.implicitHeight

    property var source: ""
    property bool autoPlay: false
    property bool muted: false
    property real volume: 1.0
    property int loops: 1
    property int fillMode: 1

    enum FillMode {
        Stretch = 0,
        PreserveAspectFit = 1,
        PreserveAspectCrop = 2
    }

    Native.VideoOutput {
        id: videoOut
        anchors.fill: parent
        fillMode: root.fillMode
    }

    Native.MediaPlayer {
        id: player
        videoOutput: videoOut
        loops: root.loops

        audioOutput: Native.AudioOutput {
            muted: root.muted
            volume: root.volume
        }
    }

    onSourceChanged: {
        var str = source ? source.toString() : "";
        if (!str || str.indexOf("QtMultimedia") !== -1 || str.indexOf("Video") !== -1 || str === "undefined") return;

        if (!str.startsWith("file://") && !str.startsWith("/") && !str.startsWith("http")) {
            // Relative path — resolve against theme directory
            var lastSlash = str.lastIndexOf("/");
            var filename = lastSlash >= 0 ? str.substring(lastSlash + 1) : str;

            var tName = Quickshell.env("QS_THEME") || "pixel-rainyroom";
            var resolvedStr = "file://" + Quickshell.shellDir + "/themes_link/" + tName + "/" + filename;

            if (player.source.toString() !== resolvedStr) {
                player.source = resolvedStr;
            }
        } else {
            player.source = source;
        }

        if (root.autoPlay && player.source.toString() !== "") {
            player.play();
        }
    }

    onAutoPlayChanged: {
        if (autoPlay && player.source.toString() !== "") player.play();
    }

    function play() { player.play(); }
    function pause() { player.pause(); }
    function stop() { player.stop(); }
}
```

**Note:** The path resolution uses `Quickshell.shellDir + "/themes_link/"`. Since `greeter_shell.qml` lives at `/etc/greetd/`, `Quickshell.shellDir` = `/etc/greetd`. The install script creates a symlink `/etc/greetd/themes_link` → `/etc/greetd/themes/themes/` so paths resolve to `/etc/greetd/themes/themes/<theme>/<filename>`.

- [ ] **Step 3: Create `imports/QtMultimedia/MediaPlayer.qml`**

```qml
import QtQuick 2.15
import QtMultimedia 6.0 as Native

Native.MediaPlayer {
    enum Loops {
        Infinite = -1
    }
}
```

- [ ] **Step 4: Create `imports/QtMultimedia/VideoOutput.qml`**

```qml
import QtQuick 2.15
import QtMultimedia 6.0 as Native

Native.VideoOutput {
    id: videoOut

    enum FillMode {
        Stretch = 0,
        PreserveAspectFit = 1,
        PreserveAspectCrop = 2
    }
}
```

- [ ] **Step 5: Create `imports/SddmComponents/qmldir`**

```
module SddmComponents
TextConstants 2.0 TextConstants.qml
TextConstants 1.0 TextConstants.qml
```

- [ ] **Step 6: Create `imports/SddmComponents/TextConstants.qml`**

```qml
import QtQuick 2.15

QtObject {
    readonly property string welcomeText: "Welcome"
    readonly property string loginFailedText: "Login Failed"
    readonly property string loginSucceeded: "Welcome back!"
    readonly property string loginFailed: "Try again"
}
```

- [ ] **Step 7: Create `imports/SddmComponents/LayoutMirroring.qml`**

```qml
import QtQuick 2.15

Item {
    property bool enabled: false
    property bool childrenInherit: false
}
```

- [ ] **Step 8: Commit**

```bash
git add system/greeter/imports/QtMultimedia/ system/greeter/imports/SddmComponents/
git commit -m "feat(greeter): add QtMultimedia and SddmComponents import shims"
```

---

### Task 4: Create GreetdShim.qml

**Files:**
- Create: `system/greeter/shim/GreetdShim.qml`

This is the core compatibility layer. Exposes SDDM API surface backed by `Quickshell.Services.Greetd`.

- [ ] **Step 1: Create `shim/GreetdShim.qml`**

```qml
import QtQuick
import Quickshell
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
        _loadThemeConfig();
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
            "echo '" + shim._pendingUser + "' > /var/lib/greeter/last-user"];
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
                    exec: "Hyprland",
                    file: "hyprland.desktop"
                });
            }
        }
    }

    function _scanSessions() {
        // Scan all .desktop files in session_dirs, extract Name and Exec
        var dirs = shim.sessionDirs.split(":");
        var script = "";
        for (var i = 0; i < dirs.length; i++) {
            var dir = dirs[i].trim();
            if (dir === "") continue;
            // For each .desktop file, extract Name= and Exec= fields
            script += "for f in " + dir + "/*.desktop; do " +
                "[ -f \"$f\" ] || continue; " +
                "name=$(sed -n 's/^Name=//p' \"$f\" | head -1); " +
                "execl=$(sed -n 's/^Exec=//p' \"$f\" | head -1); " +
                "file=$(basename \"$f\"); " +
                "[ -n \"$name\" ] && [ -n \"$execl\" ] && echo \"${name}|${execl}|${file}\"; " +
                "done; ";
        }
        if (script !== "") {
            _sessionScanProc.command = ["bash", "-c", script];
            _sessionScanProc.running = true;
        }
    }

    // ── Load theme.conf (INI format) via XMLHttpRequest ──
    function _loadThemeConfig() {
        if (!shim.themePath) return;
        var url = "file://" + shim.themePath + "/theme.conf";
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    var lines = xhr.responseText.split("\n");
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
        };
        xhr.open("GET", url, true);
        xhr.send();
    }

    onThemePathChanged: _loadThemeConfig()
}
```

- [ ] **Step 2: Commit**

```bash
git add system/greeter/shim/GreetdShim.qml
git commit -m "feat(greeter): add GreetdShim SDDM compatibility layer"
```

---

### Task 5: Create greeter_shell.qml

**Files:**
- Create: `system/greeter/greeter_shell.qml`

The QuickShell entry point. Reads config, instantiates the shim, loads the theme on the primary monitor.

- [ ] **Step 1: Create `greeter_shell.qml`**

```qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Greetd
import "./shim"

ShellRoot {
    id: shellRoot

    // ── Configuration (populated from greeter.conf) ──
    property string activeTheme: ""
    property string defaultUser: ""
    property string sessionDirs: ""
    property string themePath: "/etc/greetd/themes/themes/" + activeTheme

    // ── SDDM globals (exposed as root properties for themes) ──
    readonly property var sddm: greetdShim.sddm
    readonly property var config: greetdShim.config
    readonly property var userModel: greetdShim.userModel
    readonly property var sessionModel: greetdShim.sessionModel

    // ── Shim instance ──
    GreetdShim {
        id: greetdShim
        themePath: shellRoot.themePath
        defaultUser: shellRoot.defaultUser
        sessionDirs: shellRoot.sessionDirs
    }

    // ── Greetd lifecycle ──
    Connections {
        target: Greetd

        function onReadyToLaunch() {
            var idx = greetdShim.selectedSessionIndex;
            var session = greetdShim.sessionModel.get(idx);
            var cmd = session ? session.exec : "Hyprland";
            Greetd.launch(cmd.split(" "));
        }

        function onLaunched() {
            Qt.quit();
        }

        function onError(error) {
            console.error("Greetd error:", error);
        }
    }

    // ── Theme component (loaded into primary monitor) ──
    Component {
        id: themeComponent
        Loader {
            anchors.fill: parent
            source: shellRoot.activeTheme !== ""
                ? "file://" + shellRoot.themePath + "/Main.qml"
                : ""
            onLoaded: {
                item.forceActiveFocus();
            }
            onStatusChanged: {
                if (status === Loader.Error) {
                    console.error("Failed to load theme:", source);
                }
            }
        }
    }

    // ── Multi-monitor: theme on primary (DP-2), black on secondary ──
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            property bool isPrimary: modelData.name === "DP-2"

            screen: modelData
            visible: true
            color: "black"

            WlrLayer.layer: WlrLayer.Overlay
            WlrLayer.keyboardFocus: isPrimary
                ? WlrKeyboardFocus.Exclusive
                : WlrKeyboardFocus.None

            Loader {
                anchors.fill: parent
                active: isPrimary
                sourceComponent: themeComponent
            }
        }
    }

    // ── Config loader ──
    Component.onCompleted: {
        _loadConfig();
    }

    function _loadConfig() {
        var url = "file:///etc/greetd/greeter.conf";
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    var lines = xhr.responseText.split("\n");
                    for (var i = 0; i < lines.length; i++) {
                        var line = lines[i].trim();
                        if (line.startsWith("[") || line === "" || line.startsWith("#")) continue;
                        var eqIdx = line.indexOf("=");
                        if (eqIdx <= 0) continue;
                        var key = line.substring(0, eqIdx).trim();
                        var val = line.substring(eqIdx + 1).trim();
                        if (key === "theme") shellRoot.activeTheme = val;
                        else if (key === "default_user") shellRoot.defaultUser = val;
                        else if (key === "session_dirs") shellRoot.sessionDirs = val;
                    }
                }
                // Fallbacks
                if (shellRoot.activeTheme === "") shellRoot.activeTheme = "pixel-rainyroom";
                if (shellRoot.defaultUser === "") shellRoot.defaultUser = "user";
                if (shellRoot.sessionDirs === "") shellRoot.sessionDirs = "/usr/share/wayland-sessions:/usr/share/xsessions";
            }
        };
        xhr.open("GET", url, true);
        xhr.send();
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add system/greeter/greeter_shell.qml
git commit -m "feat(greeter): add QuickShell entry point"
```

---

### Task 6: Create install.sh

**Files:**
- Create: `system/greeter/install.sh`

- [ ] **Step 1: Create `system/greeter/install.sh`**

```bash
#!/usr/bin/env bash
# QuickShell Greeter installer
# Installs greeter configs to /etc/greetd/ and clones qylock themes.
source "$(dirname "$0")/../../lib/helpers.sh"

log_header "Greeter (QuickShell + qylock)"

GREETD_DIR="/etc/greetd"
GREETER_STATE="/var/lib/greeter"
QYLOCK_REPO="https://github.com/IceS2/qylock.git"

# ── Dependencies check ──
for cmd in quickshell git; do
    if ! command -v "$cmd" &>/dev/null; then
        log_warn "Missing dependency: $cmd"
    fi
done

# Check for qt6-5compat (required for GraphicalEffects shims)
if ! pacman -Qi qt6-5compat &>/dev/null; then
    log_warn "Package qt6-5compat not installed (required for theme effects)"
fi

# Check for qt6-multimedia-ffmpeg (required for video themes)
if ! pacman -Qi qt6-multimedia-ffmpeg &>/dev/null; then
    log_warn "Package qt6-multimedia-ffmpeg not installed (required for video themes)"
fi

# ── Create directories ──
sudo mkdir -p "$GREETD_DIR/shim" "$GREETD_DIR/imports" "$GREETER_STATE"

# ── System configs ──
sudo_copy "system/greeter/config.toml"   "$GREETD_DIR/config.toml"
sudo_copy "system/greeter/hyprland.conf" "$GREETD_DIR/hyprland.conf"
sudo_copy "system/greeter/greeter.conf"  "$GREETD_DIR/greeter.conf"

# ── Launcher script (needs executable bit) ──
sudo_copy "system/greeter/launch.sh" "$GREETD_DIR/launch.sh"
sudo chmod 755 "$GREETD_DIR/launch.sh"

# ── QML files ──
sudo_copy "system/greeter/greeter_shell.qml" "$GREETD_DIR/greeter_shell.qml"
sudo_copy "system/greeter/shim/GreetdShim.qml" "$GREETD_DIR/shim/GreetdShim.qml"

# ── Import shims ──
for dir in QtGraphicalEffects QtMultimedia SddmComponents; do
    sudo mkdir -p "$GREETD_DIR/imports/$dir"
    for f in "$DOTFILES_DIR/system/greeter/imports/$dir"/*; do
        [[ -f "$f" ]] || continue
        sudo_copy "system/greeter/imports/$dir/$(basename "$f")" \
                  "$GREETD_DIR/imports/$dir/$(basename "$f")"
    done
done

# ── Clone/update qylock themes ──
if [[ -d "$GREETD_DIR/themes/.git" ]]; then
    log_info "Updating qylock themes..."
    sudo git -C "$GREETD_DIR/themes" pull --ff-only 2>/dev/null || log_warn "Theme update failed (check network)"
else
    log_info "Cloning qylock themes from fork..."
    sudo git clone --depth 1 "$QYLOCK_REPO" "$GREETD_DIR/themes" 2>/dev/null || log_warn "Theme clone failed (check network)"
fi

# ── Create themes_link symlink (for Video.qml asset path resolution) ──
# Video.qml resolves relative paths via: Quickshell.shellDir + "/themes_link/" + theme_name
# Quickshell.shellDir = /etc/greetd (where greeter_shell.qml lives)
# Themes are at /etc/greetd/themes/themes/<name>/ (inside the cloned repo)
if [[ -d "$GREETD_DIR/themes/themes" ]]; then
    sudo ln -sfn "$GREETD_DIR/themes/themes" "$GREETD_DIR/themes_link"
    log_ok "Created themes_link symlink"
else
    log_warn "themes/themes/ not found — themes_link not created"
fi

# ── Permissions ──
sudo chown -R greeter:greeter "$GREETER_STATE" 2>/dev/null || true
sudo chmod 0755 "$GREETER_STATE" 2>/dev/null || true

log_info "Greeter installed. Fork qylock to IceS2/qylock before first run."
log_info "Test: env QML2_IMPORT_PATH=$GREETD_DIR/imports quickshell -p $GREETD_DIR/greeter_shell.qml"
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x system/greeter/install.sh`

- [ ] **Step 3: Commit**

```bash
git add system/greeter/install.sh
git commit -m "feat(greeter): add install script with theme cloning"
```

---

### Task 7: Update system/install.sh

**Files:**
- Modify: `system/install.sh:15-28`

Add the greeter install block. Keep the regreet block as-is (manual removal later).

- [ ] **Step 1: Add greeter block after the regreet block**

In `system/install.sh`, after the closing `fi` of the regreet block (line 28), add:

```bash

# ── QuickShell Greeter (greetd login screen) ──
if [[ -f "$DOTFILES_DIR/system/greeter/install.sh" ]]; then
    bash "$DOTFILES_DIR/system/greeter/install.sh"
fi
```

- [ ] **Step 2: Commit**

```bash
git add system/install.sh
git commit -m "feat(greeter): register greeter module in system install script"
```

---

### Task 8: Verification

- [ ] **Step 1: Verify complete file tree**

Run: `find system/greeter -type f | sort`

Expected:
```
system/greeter/config.toml
system/greeter/greeter.conf
system/greeter/greeter_shell.qml
system/greeter/hyprland.conf
system/greeter/imports/QtGraphicalEffects/Blend.qml
system/greeter/imports/QtGraphicalEffects/BrightnessContrast.qml
system/greeter/imports/QtGraphicalEffects/ColorOverlay.qml
system/greeter/imports/QtGraphicalEffects/Colorize.qml
system/greeter/imports/QtGraphicalEffects/ConicalGradient.qml
system/greeter/imports/QtGraphicalEffects/Desaturate.qml
system/greeter/imports/QtGraphicalEffects/DirectionalBlur.qml
system/greeter/imports/QtGraphicalEffects/Displace.qml
system/greeter/imports/QtGraphicalEffects/DropShadow.qml
system/greeter/imports/QtGraphicalEffects/FastBlur.qml
system/greeter/imports/QtGraphicalEffects/GammaAdjust.qml
system/greeter/imports/QtGraphicalEffects/GaussianBlur.qml
system/greeter/imports/QtGraphicalEffects/Glow.qml
system/greeter/imports/QtGraphicalEffects/HueSaturation.qml
system/greeter/imports/QtGraphicalEffects/InnerShadow.qml
system/greeter/imports/QtGraphicalEffects/LevelAdjust.qml
system/greeter/imports/QtGraphicalEffects/LinearGradient.qml
system/greeter/imports/QtGraphicalEffects/MaskedBlur.qml
system/greeter/imports/QtGraphicalEffects/OpacityMask.qml
system/greeter/imports/QtGraphicalEffects/RadialBlur.qml
system/greeter/imports/QtGraphicalEffects/RadialGradient.qml
system/greeter/imports/QtGraphicalEffects/RectangularGlow.qml
system/greeter/imports/QtGraphicalEffects/RecursiveBlur.qml
system/greeter/imports/QtGraphicalEffects/ThresholdMask.qml
system/greeter/imports/QtGraphicalEffects/ZoomBlur.qml
system/greeter/imports/QtGraphicalEffects/qmldir
system/greeter/imports/QtMultimedia/MediaPlayer.qml
system/greeter/imports/QtMultimedia/Video.qml
system/greeter/imports/QtMultimedia/VideoOutput.qml
system/greeter/imports/QtMultimedia/qmldir
system/greeter/imports/SddmComponents/LayoutMirroring.qml
system/greeter/imports/SddmComponents/TextConstants.qml
system/greeter/imports/SddmComponents/qmldir
system/greeter/install.sh
system/greeter/launch.sh
system/greeter/shim/GreetdShim.qml
```

Total: 40 files.

- [ ] **Step 2: Pre-flight — fork qylock**

Before testing, fork `Darkkal44/qylock` to `IceS2/qylock` on GitHub. This is a manual step.

- [ ] **Step 3: Run install script**

Run: `./system/greeter/install.sh`

Expected: All files copied to `/etc/greetd/`, themes cloned, `themes_link` symlink created, `/var/lib/greeter/` created with correct permissions.

- [ ] **Step 4: Verify installed layout**

Run: `ls -la /etc/greetd/`

Expected to see: `config.toml`, `hyprland.conf`, `greeter.conf`, `launch.sh`, `greeter_shell.qml`, `shim/`, `imports/`, `themes/`, `themes_link` (symlink → themes/themes/)

- [ ] **Step 5: Smoke test (current session)**

Run: `env QML2_IMPORT_PATH=/etc/greetd/imports QS_THEME=pixel-rainyroom quickshell -p /etc/greetd/greeter_shell.qml`

Expected: Theme loads visually on DP-2. Won't authenticate (no greetd socket in user session), but the UI should appear. Kill with Ctrl+C.

- [ ] **Step 6: Full test (reboot)**

Run: `sudo systemctl restart greetd`

Verify:
1. Theme loads on DP-2 (primary monitor)
2. Secondary monitor (DP-1) shows black
3. Username pre-filled with "ice"
4. Session dropdown populated (Hyprland default-selected)
5. Correct password → launches Hyprland session
6. Wrong password → theme shows login failed message
7. Reboot/power off buttons work
8. Next login → username still pre-filled (last-user persistence)

- [ ] **Step 7: Theme switching test**

Edit `/etc/greetd/greeter.conf`: change `theme = pixel-rainyroom` to `theme = pixel-coffee`.
Reboot. Verify the new theme loads.
