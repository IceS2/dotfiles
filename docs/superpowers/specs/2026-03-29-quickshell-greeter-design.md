# QuickShell Greeter for greetd — Design Spec

**Date:** 2026-03-29
**Scope:** Replace ReGreet with a QuickShell-based greetd greeter that runs qylock SDDM themes unmodified

---

## Overview

Build a QuickShell greeter that plugs into the existing `greetd → Hyprland (greeter config) → greeter → exit` flow, replacing ReGreet (GTK4). The greeter uses qylock's SDDM theme library (20 pixel-art, game-inspired, and aesthetic themes) by providing a compatibility shim that translates SDDM API calls to QuickShell's `Quickshell.Services.Greetd` backend.

### Architecture

```
greetd
  → Hyprland (greeter config, /etc/greetd/hyprland.conf)
    → QuickShell (greeter_shell.qml)
      → GreetdShim (fakes SDDM globals, backed by Greetd API)
        → Loader loads qylock theme Main.qml unmodified
          → Theme calls sddm.login() → GreetdShim → Greetd.createSession() + respond()
            → On success: Greetd.launch(session) → Qt.quit() → hyprctl dispatch exit
```

The key insight: qylock themes call `sddm.login()`, `userModel`, `sessionModel`, etc. The shim provides these exact interfaces, but the backend is greetd instead of SDDM/PAM. Themes need zero modification.

### Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Theme selection | Configurable via `greeter.conf` | Easy to switch without editing QML |
| User model | Single user, auto-filled | Personal machine, last-user cached |
| Session model | Auto-detect `.desktop` files | Low cost, future-proof |
| Location in dotfiles | `system/greeter/` | System-level config, replaces `system/regreet/` |
| Theme bundling | Install script clones from GitHub fork | Keeps dotfiles lean, video assets don't belong in repo |
| Upstream protection | Fork qylock to user's GitHub | Immune to upstream deletion |
| Multi-monitor | Theme on DP-2, black on secondary | Secondary is rotated portrait, theme would look odd |
| Greeter exit | Immediate `Qt.quit()` on `launched()` | greetd docs: exit ASAP after launch ack |

---

## 1. Directory Structure

### Dotfiles (`system/greeter/`)

```
system/greeter/
├── config.toml              # greetd daemon config
├── hyprland.conf            # Greeter Hyprland compositor config
├── greeter.conf             # Greeter settings (theme, default user, session dirs)
├── greeter_shell.qml        # QuickShell entry point
├── shim/
│   └── GreetdShim.qml       # SDDM API compatibility layer (Greetd backend)
├── imports/                  # Qt5→Qt6 shims (from qylock)
│   ├── QtGraphicalEffects/   # 28 effect redirects (Qt5Compat.GraphicalEffects)
│   ├── QtMultimedia/         # Video/MediaPlayer Qt5→Qt6 proxy (7 files)
│   └── SddmComponents/      # TextConstants + LayoutMirroring stubs (3 files)
└── install.sh               # Installs greeter + clones qylock themes
```

### Installed layout (`/etc/greetd/`)

```
/etc/greetd/
├── config.toml
├── hyprland.conf
├── greeter.conf
├── greeter_shell.qml
├── shim/
│   └── GreetdShim.qml
├── imports/
│   ├── QtGraphicalEffects/
│   ├── QtMultimedia/
│   └── SddmComponents/
└── themes/                   # Cloned from qylock fork (not in dotfiles repo)
    ├── pixel-rainyroom/
    ├── pixel-coffee/
    ├── Genshin/
    └── ... (20 themes)

/var/lib/greeter/
└── last-user                 # Persisted username for auto-fill
```

---

## 2. `greeter_shell.qml` — Entry Point

```qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Greetd
import "./shim"

ShellRoot {
    id: shellRoot

    // ── Configuration ──
    property string activeTheme: ""       // read from greeter.conf
    property string defaultUser: ""       // read from greeter.conf
    property string sessionDirs: ""       // read from greeter.conf
    property string themePath: "/etc/greetd/themes/themes/" + activeTheme

    // ── SDDM globals (exposed to themes) ──
    readonly property var sddm: greetdShim.sddm
    readonly property var config: greetdShim.config
    readonly property var userModel: greetdShim.userModel
    readonly property var sessionModel: greetdShim.sessionModel

    // ── Shim ──
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
            var idx = greetdShim.selectedSessionIndex
            var cmd = greetdShim.sessionModel.get(idx).exec
            Greetd.launch(cmd.split(" "))
        }
        function onLaunched() {
            Qt.quit()
        }
    }

    // ── Theme component ──
    Component {
        id: themeComponent
        Loader {
            anchors.fill: parent
            source: "file://" + shellRoot.themePath + "/Main.qml"
            onLoaded: { item.forceActiveFocus() }
            onStatusChanged: {
                if (status === Loader.Error)
                    console.error("Failed to load theme:", source)
            }
        }
    }

    // ── Multi-monitor: theme on primary, black on secondary ──
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            property bool isPrimary: modelData.name === "DP-2"

            screen: modelData
            visible: true
            WlrLayer.layer: WlrLayer.Overlay
            WlrLayer.keyboardFocus: isPrimary
                ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            color: "black"

            Loader {
                anchors.fill: parent
                active: isPrimary
                sourceComponent: themeComponent
            }
        }
    }

    // ── Config loader ──
    Component.onCompleted: {
        // Parse greeter.conf (INI format) via XMLHttpRequest
        // Sets activeTheme, defaultUser, sessionDirs
    }
}
```

**Key points:**
- `Variants` over `Quickshell.screens` — one PanelWindow per monitor
- Primary monitor (DP-2): full theme with exclusive keyboard focus
- Secondary monitors: black PanelWindow, no keyboard focus, no theme
- Greetd `onReadyToLaunch`: reads the selected session command and calls `launch()`
- Greetd `onLaunched`: immediate `Qt.quit()` — no delay timer
- Config parsed at startup from `/etc/greetd/greeter.conf`

---

## 3. `GreetdShim.qml` — SDDM Compatibility Layer

Exposes the four SDDM globals that every qylock theme expects, backed by `Quickshell.Services.Greetd`.

```qml
import QtQuick
import Quickshell
import Quickshell.Services.Greetd

Item {
    id: shim

    // ── Inputs ──
    property string themePath: ""
    property string defaultUser: ""
    property string sessionDirs: ""

    // ── State ──
    property int selectedSessionIndex: 0

    // ── SDDM API surface (consumed by themes) ──

    property var sddm: QtObject {
        signal loginFailed()
        signal loginSucceeded()

        function login(user, password, sessionIndex) {
            shim.selectedSessionIndex = sessionIndex
            shim._pendingPassword = password
            Greetd.createSession(user)
        }

        function reboot() {
            Quickshell.execDetached(["systemctl", "reboot"])
        }

        function powerOff() {
            Quickshell.execDetached(["systemctl", "poweroff"])
        }
    }

    property var userModel: ListModel {
        property string lastUser: ""
        property int lastIndex: 0
    }

    property var sessionModel: ListModel {
        property int lastIndex: 0
    }

    property var config: ({})

    // ── Internal ──
    property string _pendingPassword: ""

    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired && shim._pendingPassword !== "") {
                Greetd.respond(shim._pendingPassword)
                shim._pendingPassword = ""
            }
        }

        function onReadyToLaunch() {
            _persistLastUser()
            shim.sddm.loginSucceeded()
        }

        function onAuthFailure(message) {
            shim._pendingPassword = ""
            shim.sddm.loginFailed()
        }
    }

    // ── Initialization ──
    Component.onCompleted: {
        _loadLastUser()
        _scanSessions()
        _loadThemeConfig()
    }

    // ── Helpers ──

    function _loadLastUser() {
        // Read /var/lib/greeter/last-user via Process
        // Fallback to defaultUser property
        // Populate userModel with single entry
    }

    function _persistLastUser() {
        // Write current user to /var/lib/greeter/last-user via Process
    }

    function _scanSessions() {
        // For each dir in sessionDirs (colon-separated):
        //   List *.desktop files
        //   Parse Name= and Exec= lines
        //   Append to sessionModel: { name, file, exec }
        // Set lastIndex to Hyprland entry if found
    }

    function _loadThemeConfig() {
        // XMLHttpRequest to read themePath + "/theme.conf"
        // Parse INI key=value lines into config object
    }
}
```

**Auth flow:**
1. Theme calls `sddm.login("ice", "password", 0)`
2. Shim stores password and session index, calls `Greetd.createSession("ice")`
3. Greetd sends `authMessage` with `responseRequired: true`
4. Shim responds with stored password via `Greetd.respond(password)`
5. On success: `readyToLaunch` → persist last-user → emit `loginSucceeded()` → `greeter_shell.qml` calls `Greetd.launch(session)` → `Qt.quit()` on `launched()`
6. On failure: `authFailure` → clear password → emit `loginFailed()` → theme shows error

**Session scanning:**
- Reads `.desktop` files from `/usr/share/wayland-sessions/` and `/usr/share/xsessions/`
- Parses `Name=` and `Exec=` fields
- Defaults `lastIndex` to whichever entry is Hyprland

**User model:**
- Single entry populated from `/var/lib/greeter/last-user` (persisted on successful login)
- Falls back to `defaultUser` from `greeter.conf` on first boot

---

## 4. `greeter.conf` — Configuration File

```ini
# QuickShell Greeter Configuration
# Installed to: /etc/greetd/greeter.conf

[greeter]
theme = pixel-rainyroom
default_user = ice
session_dirs = /usr/share/wayland-sessions:/usr/share/xsessions
```

- **`theme`** — Directory name under `/etc/greetd/themes/`. Change to switch themes.
- **`default_user`** — Pre-filled username. Fallback if no last-user cache exists.
- **`session_dirs`** — Colon-separated paths to scan for `.desktop` session files.

---

## 5. `hyprland.conf` — Greeter Compositor Config

Based on the existing `system/regreet/hyprland.conf`. Changes:

```
# Unchanged:
env = LIBVA_DRIVER_NAME,nvidia
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = __GL_GSYNC_ALLOWED,1
env = __GL_VRR_ALLOWED,0
env = GDK_SCALE,1
env = GDK_DPI_SCALE,1
env = XCURSOR_SIZE,24
env = GTK_USE_PORTAL,0
env = GDK_DEBUG,no-portals
monitor = DP-2,2560x1440@165,0x0,1
monitor = DP-1,2560x1440@165,-1440x-560,1,transform,1
cursor { no_hardware_cursors = true }
general { gaps_in = 0; gaps_out = 0; border_size = 0 }
decoration { rounding = 0 }
animations { enabled = false }
misc { disable_hyprland_logo = true; disable_splash_rendering = true; force_default_wallpaper = 0 }
workspace = 1, monitor:DP-2, default:true

# Changed:
# Removed: windowrule for regreet class
# Changed: exec-once launches QuickShell with import path
exec-once = env QML2_IMPORT_PATH=/etc/greetd/imports quickshell -p /etc/greetd/greeter_shell.qml; hyprctl dispatch exit
```

---

## 6. `config.toml` — greetd Daemon Config

Identical to current, no changes needed:

```toml
[terminal]
vt = 1

[default_session]
command = "env GTK_USE_PORTAL=0 GDK_DEBUG=no-portals start-hyprland -- --config /etc/greetd/hyprland.conf"
user = "greeter"
```

---

## 7. `install.sh` — Installation Script

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/../lib/helpers.sh"

log_header "Greeter"

GREETD_DIR="/etc/greetd"
GREETER_STATE="/var/lib/greeter"
QYLOCK_REPO="https://github.com/IceS2/qylock.git"

# ── Dependencies check ──
for cmd in quickshell git; do
    command -v "$cmd" &>/dev/null || log_warn "Missing dependency: $cmd"
done

# ── Create directories ──
sudo mkdir -p "$GREETD_DIR/shim" "$GREETD_DIR/imports" "$GREETER_STATE"

# ── Copy QML files ──
sudo_copy "system/greeter/greeter_shell.qml" "$GREETD_DIR/greeter_shell.qml"
sudo_copy "system/greeter/greeter.conf"      "$GREETD_DIR/greeter.conf"
sudo_copy "system/greeter/shim/GreetdShim.qml" "$GREETD_DIR/shim/GreetdShim.qml"

# ── Copy import shims (recursive) ──
for dir in QtGraphicalEffects QtMultimedia SddmComponents; do
    sudo mkdir -p "$GREETD_DIR/imports/$dir"
    for f in "$DOTFILES_DIR/system/greeter/imports/$dir"/*; do
        [[ -f "$f" ]] || continue
        sudo_copy "system/greeter/imports/$dir/$(basename "$f")" \
                  "$GREETD_DIR/imports/$dir/$(basename "$f")"
    done
done

# ── Copy system configs ──
sudo_copy "system/greeter/config.toml"   "$GREETD_DIR/config.toml"
sudo_copy "system/greeter/hyprland.conf" "$GREETD_DIR/hyprland.conf"

# ── Clone/update qylock themes ──
if [[ -d "$GREETD_DIR/themes/.git" ]]; then
    log_info "Updating qylock themes..."
    sudo git -C "$GREETD_DIR/themes" pull --ff-only
else
    log_info "Cloning qylock themes..."
    sudo git clone "$QYLOCK_REPO" "$GREETD_DIR/themes"
fi

# ── Permissions ──
sudo chown -R greeter:greeter "$GREETER_STATE" 2>/dev/null || true
sudo chmod 0755 "$GREETER_STATE" 2>/dev/null || true
```

**Notes:**
- Uses existing `sudo_copy` helper from `lib/helpers.sh` (idempotent, skips if identical)
- Clones entire qylock fork (themes are in `themes/` subdirectory) — the theme Loader path accounts for this
- `git pull --ff-only` for safe updates (no merge conflicts)
- Warns on missing dependencies but doesn't abort (user may install later)
- Does NOT remove old regreet files — manual cleanup after confirming the new greeter works

---

## 8. Import Shims

Copied directly from the qylock fork's `quickshell-lockscreen/imports/` directory. These are pure Qt5→Qt6 compatibility bridges:

**QtGraphicalEffects/** (28 files) — Each file is ~2 lines:
```qml
import Qt5Compat.GraphicalEffects as T
T.DropShadow {}
```

**QtMultimedia/** (7 files) — `Video.qml` is the most substantial (~75 lines), wrapping Qt6's `MediaPlayer` + `VideoOutput` with a Qt5-compatible API. Resolves theme-relative asset paths.

**SddmComponents/** (3 files) — `TextConstants.qml` provides static strings themes reference. `LayoutMirroring.qml` is a no-op stub.

These are kept in the dotfiles repo (small text files) rather than relying on the qylock clone, since they're part of the greeter's core infrastructure and we may need to maintain them independently.

---

## 9. Theme Path Resolution

The qylock fork is cloned to `/etc/greetd/themes/`. Inside that repo, themes live at `themes/<name>/`. So the full path to a theme's `Main.qml` is:

```
/etc/greetd/themes/themes/<name>/Main.qml
```

The `themePath` in `greeter_shell.qml` accounts for this:
```qml
property string themePath: "/etc/greetd/themes/themes/" + activeTheme
```

Alternatively, the install script could clone only the `themes/` subdirectory (sparse checkout) to flatten the path to `/etc/greetd/themes/<name>/`. This is cleaner but adds git complexity. The nested path works fine and keeps the clone simple.

---

## 10. Prerequisites

**Packages needed:**
- `quickshell` — the shell framework (already installed)
- `qt6-multimedia` with FFmpeg backend — required for video themes (mp4 backgrounds)
- `qt6-5compat` (Qt5Compat module) — required for GraphicalEffects shims
- `greetd` — the display manager (already installed)
- `git` — for cloning themes (already installed)

**System setup:**
- `greeter` user must exist (already does for current regreet setup)
- `/var/lib/greeter/` directory writable by `greeter` user
- greetd socket accessible to greeter process (default behavior)

**User action required:**
- Fork `Darkkal44/qylock` to your GitHub account before running install

---

## 11. Available Themes

All 20 qylock themes work unmodified:

| Theme | Type | Background |
|-------|------|------------|
| pixel-rainyroom | Pixel art | Video (mp4) |
| pixel-coffee | Pixel art | Video (mp4) |
| pixel-dusk-city | Pixel art | Video (mp4) |
| pixel-emerald | Pixel art | Video (mp4) |
| pixel-hollowknight | Pixel art | Video (mp4) |
| pixel-munchax | Pixel art | Video (mp4) |
| pixel-night-city | Pixel art | Video (mp4) |
| pixel-skyscrapers | Pixel art | Video (mp4) |
| Genshin | Game | Static image |
| nier-automata | Game | Static image |
| terraria | Game | Static image |
| minecraft | Game | Static image |
| cyberpunk | Aesthetic | Static image |
| tui | Terminal | Solid color (5 variants) |
| cozytile | Tiling | Static image (5 variants) |
| paper | Minimal | Static image |
| windows_7 | Retro | Static image |
| porsche | Aesthetic | Static image |
| ninja_gaiden | Game | Static image |
| enfield | Aesthetic | Static image |
| sword | Game | Static image |

---

## 12. Verification

```bash
# 1. Install
./system/greeter/install.sh

# 2. Test in current session (won't authenticate, but checks theme loading)
env QML2_IMPORT_PATH=/etc/greetd/imports quickshell -p /etc/greetd/greeter_shell.qml

# 3. Reboot and test real login
sudo systemctl restart greetd

# 4. Verify:
#    - Theme loads on DP-2 (primary monitor)
#    - Secondary monitor shows black
#    - Username pre-filled
#    - Session dropdown populated (Hyprland should be default)
#    - Password entry works
#    - Successful login launches Hyprland session
#    - Failed password shows error via theme UI
#    - Reboot/power off buttons work
#    - Next login remembers username (last-user persistence)

# 5. Switch themes
# Edit /etc/greetd/greeter.conf: theme = pixel-coffee
# Reboot to see new theme
```

---

## Files Summary

| File | Action |
|------|--------|
| `system/greeter/config.toml` | Create |
| `system/greeter/hyprland.conf` | Create (based on regreet version) |
| `system/greeter/greeter.conf` | Create |
| `system/greeter/greeter_shell.qml` | Create |
| `system/greeter/shim/GreetdShim.qml` | Create |
| `system/greeter/imports/QtGraphicalEffects/*` | Create (from qylock fork) |
| `system/greeter/imports/QtMultimedia/*` | Create (from qylock fork) |
| `system/greeter/imports/SddmComponents/*` | Create (from qylock fork) |
| `system/greeter/install.sh` | Create |
| `system/install.sh` | Edit (replace regreet block with greeter block) |
