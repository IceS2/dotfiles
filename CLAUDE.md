# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for an Arch Linux system. The configuration is designed to be symlinked from `~/.dotfiles` to `~/.config` and `$HOME`.

**Current State:** Transitioning from X11/bspwm to Wayland/Hyprland setup.

## Working Style Preferences

**User Preference:** Research state-of-the-art tooling, provide comprehensive comparisons, and guide step-by-step with clear explanations rather than making direct changes.

### Research-First Approach

Before implementing any feature or tool:
1. **Research current state-of-the-art** - Search for modern alternatives and best practices (2026 tooling)
2. **Compare options thoroughly** - Create comparison matrices showing features, pros/cons, and trade-offs
3. **Provide multiple recommendations** - Present 2-3 well-researched options with clear reasoning
4. **Explain the landscape** - Give context about why certain tools exist and what problems they solve
5. **Consider the full stack** - Think about integration with existing tools (Hyprland, NVIDIA, QuickShell, etc.)

**Example pattern:**
- "We need a screenshot tool" → Research: grimblast vs hyprshot vs grim+slurp
- Compare: features, performance, NVIDIA compatibility, Rust/language, community support
- Recommend: grimblast (official) + satty (Rust, GPU-accelerated annotation)
- Explain: Why these over alternatives, what each tool does, how they integrate

### Implementation Approach

When implementing features or configurations:
1. **Explain before doing** - Describe what will be done and why
2. **Guide step-by-step** - Break down complex tasks into clear, numbered steps
3. **Explain reasoning** - Clarify the purpose and trade-offs of each decision
4. **Let the user execute** - Provide commands/code for the user to run themselves
5. **Document decisions** - Update project documentation with notes about implementation choices

### Educational Focus

This approach ensures the user:
- Understands the "why" behind each change
- Learns the system deeply through hands-on implementation
- Maintains full control over their configuration
- Can make informed decisions about alternatives
- Stays current with modern tooling and best practices
- Builds expertise in the Wayland/Hyprland ecosystem

## Migration to Hyprland (Target System)

### System Specifications
- **GPU:** NVIDIA (requires specific Hyprland configuration)
- **CPU:** Intel
- **Browser:** Waterfox
- **Compositor/WM:** Hyprland (Wayland)
- **Primary Use:** Development + Gaming
- **Status Bar/Launcher:** QuickShell (QML/Qt-based, can potentially handle both bar and app launching)
- **Keyboard:** Sofle v2 (split ergonomic) with Gallium layout
  - Home row mods
  - Layer-based navigation (NAV layer for arrows)
  - Thumb cluster for layer activation
  - **Preference:** Arrow keys on layer are acceptable for window management
  - **Note:** Gallium layout reference: https://github.com/GalileoBlues/Gallium

### Migration Goals
When assisting with this repository, prioritize:

1. **Achieving Feature Parity:** Replicate the current bspwm experience on Hyprland:
   - Dual monitor workspace layout (maintain current DP-2/DP-0 setup)
   - All existing hotkeys and workflows
   - Visual aesthetics and theming
   - Audio management and device switching
   - Screen locking and idle management

2. **NVIDIA Compatibility:** Ensure all recommendations work with NVIDIA drivers:
   - Proper environment variables for Hyprland on NVIDIA
   - Compatible compositor settings
   - Working screensharing/screen capture
   - Optimal performance configurations

3. **Modern Best Practices:**
   - Research and recommend state-of-the-art Wayland-native tools
   - **Prioritize Rust-based tools** when stable and feature-complete
   - Suggest modern alternatives to X11-specific components
   - Guide on Wayland-specific best practices
   - Recommend tools with active development and strong community support
   - Ensure gaming compatibility (gamemode, steam, performance optimization)

4. **Component Migration Mapping:**
   - **bspwm → Hyprland (Rust):** Native window management configuration ✅
   - **sxhkd → Hyprland binds:** ✅ Built-in keybinding system (complete, all general binds migrated)
   - **picom → Hyprland compositor:** Built-in compositor (no separate daemon needed) ✅
   - **polybar/rofi → QuickShell:** ✅ Unified QML-based system (complete)
   - **dunst → QuickShell:** ✅ Custom notification center (complete, QML-based)
   - **feh → swww:** ✅ Rust-based, GPU-accelerated animated wallpaper daemon (complete)
   - **xidlehook → hypridle:** ✅ Hyprland-native idle management (complete with system suspend)
   - **Screen lock → hyprlock:** ✅ Hyprland-native screen locker (complete)
   - **Screenshot → grimblast + satty:** ✅ Rust annotation tool (complete)
   - **Clipboard → cliphist (Go) + wl-clipboard + QuickShell:** ✅ Clipboard history manager (complete, SearchModal-based UI with preview)
   - **Terminal → kitty:** ✅ Wayland-native with Catppuccin Mocha theme

5. **QuickShell Unified Architecture (Complete):**
   - ✅ **Decision Made:** QuickShell as unified system for launcher + bar + notifications
   - ✅ **Launcher:** Complete and production-ready (QML-based, Catppuccin themed)
   - ✅ **Status Bar:** Complete (Volume, Network, VPN, Clock, Workspaces, Notifications widgets)
   - ✅ **Notifications:** Complete (NotificationCenter, popups, persistence, DND, per-app rules)
   - ✅ **Workspace Overview:** Complete (OverviewPanel + OverviewWidget, Super+Tab via IPC)
   - **Benefits:** Single cohesive system, hot reload, full QML control, GPU-accelerated
   - **Guide:** See `quickshell/README.md` for architecture overview

6. **Tool Ecosystem:**
   - Rust tools: swww (wallpaper), satty (screenshot annotation)
   - Performance tools: ✅ gamemode, mangohud, gamescope (complete, configured)
   - Screen recording: ✅ gpu-screen-recorder + gpu-screen-recorder-ui (NVENC, instant replay, systemd service)
   - Night light: hyprsunset (official) — deferred (low priority)
   - NVIDIA optimizations: DRM kernel mode setting, explicit sync patches, driver settings
   - File managers: yazi (Rust terminal TUI) ✅ configured
   - PDF viewer: zathura (vi-like, Catppuccin themed) ✅ configured
   - Image viewer: swayimg (Wayland-native, Hyprland integration) ✅ configured
   - Bluetooth: Overskride (Rust + GTK4) — planned
   - System monitor: btop (TUI) + Mission Center (Rust GUI) — planned
   - Disk usage: dua-cli + dust (both Rust) — planned
   - Emoji picker: QuickShell SearchModal-based (future project, no rofi dependency)
   - Dynamic theming: Matugen (Rust, Material You) ✅ configured (wallpaper-based + static Catppuccin toggle)

### Gaming Setup (Complete)
**Status:** ✅ Fully configured and ready
**Guide:** `gaming/README.md`
- [x] gamemode installed (with lib32 support)
- [x] mangohud installed and configured (with lib32 support)
- [x] gamescope installed
- [x] Hyprland window rules for Steam games (steam_app_* pattern)
- [x] NVIDIA-specific environment variables for optimal gaming performance
- [x] MangoHud overlay configuration with performance metrics
- [x] Steam launch options documented (gamemoderun mangohud %command%)
- [x] Per-game optimizations guide
- [x] GameMode config in dotfiles (`gaming/gamemode.ini`)
- [x] GameMode QuickShell Toast integration (`qs ipc call toast display "<icon>" "<text>"`)
- [x] VRR (Variable Refresh Rate) enabled for both monitors (165Hz)
- [x] Troubleshooting documentation

**Usage:** Right-click Steam game → Properties → Launch Options → `gamemoderun mangohud %command%`

## Completed Features

### Screen Sharing
**Status:** ✅ Complete and tested
- [x] xwaylandvideobridge installed (AUR)
- [x] Portal configuration created and symlinked
- [x] Hyprland autostart configured
- [x] Window rules added
- [x] All services verified running
- [x] Tested with OBS Studio (PipeWire capture)
- [x] Tested with Discord screen share (xwaylandvideobridge)

### External Monitor Brightness Control
**Status:** ✅ Complete and configured
- [x] ddcutil and i2c-tools installed
- [x] NVIDIA driver configured for DDC/CI
- [x] i2c-dev kernel module loaded
- [x] User added to i2c group
- [x] DDC/CI enabled in monitor OSD settings
- [x] Monitor detection tested with `ddcutil detect`
- [x] Brightness control script created (`~/.config/hypr/scripts/brightness.sh`)
- [x] Display IDs mapped to monitors (DP-1 and DP-2)
- [x] Hyprland keybinds added (Super+F11/F12)
- [x] Multi-monitor support tested (focused monitor detection)

**Tools:** ddcutil (CLI, DDC/CI protocol)
**Integration:** Hyprland keybinds, QuickShell widgets (future enhancement)

## Pending Features

### Next Up — QuickShell Improvements (priority order)
1. [x] **System tray**: SNI/DBusMenu via `Quickshell.Services.SystemTray` — bar icon → popup grid, Catppuccin context menus
2. [x] **Native PipeWire audio**: Replace `wpctl` polling with `Quickshell.Services.Pipewire` (PwNode) — instant reactivity, per-app volume, device switching UI
3. [x] **MPRIS media widget**: Bar widget with track info, album art, play/pause via `Quickshell.Services.Mpris` (native API)
4. [x] **Launcher fuzzy matching**: Scored fuzzy search (replace `.includes()`), frecency/usage tracking, recent apps section

### QuickShell Polish
- [x] Move hardcoded values to Theme.qml (popup widths, clipboard dimensions, fontSizeCaption)
- [x] Workspace indicator animation (sliding highlight with smooth easing)
- [x] Toast queuing (text toasts have min display time, pending queue; progress updates in-place)
- [x] Notification card hover depth (scale 1.02 + Translate y:-2 on hover)

### Status Bar Redesign (priority order)

1. [x] **Pill grouping** — BarPill component, restructure widgets into logical groups, remove inter-group separators
2. [x] **Hover & active states** — Background fill on hover/press, reduce scale values, pill-level glow on popup open
3. [x] **Information density reduction** — Icon-only defaults for perf/VPN/BT, remove speeds from bar, shorten clock
4. [x] **Visual hierarchy** — Weight differentiation (Bold/DemiBold/Medium) + color hierarchy (on.surface/on.surfaceVariant/outline)
5. [ ] **Polish & micro-interactions** — Pill entrance/exit animations (media progress line ✅, workspace worm animation ✅)

### Desktop Polish & UX Enhancements (priority order)

1. [x] **Hyprland animation upgrade** — Overshoot bezier curves (MD3 expressive spatial), squircle rounding, slidefade workspaces, triple buffering
2. [ ] **QML SpringAnimation for popups** — Physics-based bounce on popup/panel appearance (qualitatively different from bezier)
3. [ ] **Render-thread Animators** — OpacityAnimator/ScaleAnimator wrappers for 165Hz-smooth QuickShell animations
4. [ ] **Context-aware desktop modes** — Coding/Focus/Gaming/Media modes that transform bar, borders, colors, notifications via hyprshade + QuickShell
5. [ ] **Animated aurora border frame** — QML ShaderEffect on BorderFrame with animated mesh gradient (Catppuccin palette)
6. [ ] **Kinetic typography** — Morphing clock digits, typewriter notification text, staggered character reveals
7. [ ] **Progressive disclosure bar** — Minimal default state, hover reveals full, active-expansion on value change, breathing idle
8. [ ] **Haptic-like visual feedback** — SpringAnimation click depress/release, press-and-hold progress ring
9. [ ] **Parallax wallpaper** — Hyprlax multi-layer depth on workspace switch
10. [ ] **Generative shader wallpaper** — NeoWall Shadertoy wallpaper driven by system metrics (CPU/RAM/network)
11. [ ] **Music-reactive desktop chrome** — Border glow pulses to bass, notification cards tinted to album art
12. [ ] **AI context widget** — Git branch/status from focused terminal CWD, quick actions, Claude/Ollama integration
13. [x] **Unified slider component** — ProgressBar.qml serves as shared slider/progress component

### Pending Evaluation
- [ ] **Matugen 4.0** `--prefer saturation` + `--source-color-index N`: When it hits Arch `extra` stable (in `extra-testing` as of 2025-02), test if it can replace `extract-color.sh` for vibrant color extraction. The built-in Score algorithm weights 70% by population — `--prefer saturation` re-ranks results, which may suffice for accents >1% of pixels.

### Someday / Maybe
- Emoji picker (QuickShell SearchModal-based), Keybind viewer (PopupPanel)
- Keyboard cheatsheet overlay
- `hyprsunset` (night light)
- `dua-cli` (interactive disk cleanup TUI, complements dust), `Overskride` (Bluetooth GUI for advanced tasks: file transfer, audio profiles), `Ianny` (break reminders)
- Neubrutalism theme variant (toggle between glass and raw aesthetic)
- Brightness widget + OSD (blocked: ddcutil too laggy on Wayland/NVIDIA external monitors — needs research)

### Rejected / Not Needed
- ~~C++ plugins~~ — break on every Hyprland update, hyprpm removed
- ~~hyprexpo~~ — NVIDIA crashes + replaced by QuickShell Overview
- ~~hyprfocus / hyprdim~~ — built-in `active_opacity`/`inactive_opacity` suffices
- ~~xtra-dispatchers~~ — `moveorexec` scriptable with `hyprctl clients -j`
- ~~hypr-dynamic-cursors~~ — forces software cursor on NVIDIA
- ~~hyprtrails / hyprbars / hy3 / hyprsplit~~ — not needed for keyboard-driven dwindle workflow
- ~~wlogout~~ — replaced by QuickShell Power Menu
- ~~hyprshell~~ — Alt+Tab cycling + QuickShell Overview already cover this
- ~~Quick Settings panel~~ — individual popups (Audio, Network, Bluetooth) already provide deeper control
- ~~Power profiles~~ — desktop system, no battery; GameMode handles gaming performance
- ~~hyprfreeze-rs~~ — rarely needed, trivially scriptable with `kill -STOP`
- ~~EasyMotion~~ — C++ plugin, breaks on every Hyprland update
- ~~hyprscrolling~~ — C++ plugin + different layout paradigm (scrolling columns vs dwindle)
- ~~hyprwinwrap~~ — C++ plugin + cosmetic only (desktop hidden in tiling workflow)
- ~~Clipvault~~ — cliphist works fine, switching risks QuickShell integration for marginal gains
- ~~nwg-displays~~ — fixed dual-monitor, not needed

### Language Environment Management
**Status:** ✅ Python configured, others deferred

#### Python: uv (Configured)
- ✅ **Decided:** Using `uv` - Rust-based, 10-100x faster than pip
- ✅ **Installed:** Configured in `zsh/zsh-tools.zsh`
- **Features:** Unified tool (replaces pip/venv/pyenv/poetry), automatic Python version management
- **Rationale:** Aligns with Rust tooling philosophy, zero startup overhead, production-ready

#### Other Languages (Deferred)
- Evaluate: jenv vs sdkman vs system (Java)
- **Node:** ✅ Using `fnm` (already configured)
- Evaluate: rbenv vs rvm vs system (Ruby)
- Prioritize: Fast startup, minimal overhead

### Git Configuration
**Status:** ✅ Single identity with GPG signing
- [x] GPG signing with key `7CB5E227FAA5CB81` (RSA 4096)
- [x] GPG agent for SSH support with pinentry-gnome3 (stable on Hyprland/Wayland)
- [x] SSH keys for GitHub and Codeberg
- [x] Credential helper using libsecret (gnome-keyring)
- [x] Delta diff viewer with Catppuccin Mocha theme
- [x] Personal info in `~/.gitconfig.local` (gitignored)

## Setup and Installation

### Initial Setup
```bash
./install.sh              # Install all modules
./install.sh hypr theme   # Install specific modules
./install.sh --list       # List available modules
```

The root `install.sh` orchestrator runs per-module install scripts in dependency order.
Each module's `install.sh` is also standalone-runnable (e.g., `./theme/install.sh`).

**Shared helpers** in `lib/helpers.sh` provide idempotent operations:
- `link_config` — symlink to `~/.config/`
- `link_home` — symlink to `~/`
- `link_to` — symlink to arbitrary path
- `sudo_copy` — copy to /etc/ (skip if identical)
- `sudo_link` — sudo symlink

All operations are idempotent: second run shows all [SKIP].

### Module Install Order
zsh → git → gnupg → nvim → kitty → hypr → quickshell → theme → media → gaming → tools → system → local

## Theming & Colorschemes

**Current Approach:** Hybrid static/dynamic theming strategy

### Primary Theme: Catppuccin Mocha
The system uses **Catppuccin Mocha** as the primary colorscheme across all applications:
- **Flavor:** Mocha (dark with purple/mauve accents)
- **Philosophy:** Soothing pastel colors, carefully curated for consistency
- **Coverage:** Hyprland, GTK, Qt, Kitty, Neovim, and all major components

### Color Palette Reference
| Color | Hex | Usage |
|-------|-----|-------|
| Mauve | #cba6f7 | Primary accent (purple) |
| Pink | #f5c2e7 | Secondary accent |
| Base | #1e1e2e | Main background |
| Text | #cdd6f4 | Main text |
| Red | #f38ba8 | Error/urgent |
| Green | #a6e3a1 | Success |

Full palette: https://github.com/catppuccin/catppuccin

### Dynamic Theming: Matugen (Material You)
**Status:** ✅ Complete

- **Matugen** (Rust) extracts colors from wallpaper, generates Material You palette
- **Hybrid approach**: Toggle between static (Catppuccin Mocha) and dynamic (wallpaper-derived) via `Super+Shift+T`
- **Pipeline**: wallpaper change → matugen → `theme/colors.json` → apply-theme.sh → Hyprland/kitty/nvim/starship/hyprlock/zathura/GTK
- **QuickShell integration**: Theme.qml watches `colors.json` via FileView, live preview during wallpaper selection
- **Files**: `theme/` directory (colors.json, catppuccin-mocha.json, .mode, apply-theme.sh, switch-theme.sh, matugen/)
- **IPC**: `qs ipc call theme toggleMode/setStatic/setDynamic/reloadColors`

### Related Files
- `quickshell/AESTHETIC_IMPROVEMENTS.md`: QuickShell aesthetic enhancements log
- `hypr/themes/`: Theme files directory
- Legacy X11 themes preserved in git history (pre-reorganization)

## Architecture

### Repository Structure
```
~/.dotfiles/
├── install.sh              # Orchestrator
├── lib/helpers.sh          # Shared idempotent functions
├── CLAUDE.md
├── .gitignore
├── hypr/                   # Hyprland WM + systemd services
├── quickshell/             # QML bar + launcher + notifications
├── nvim/                   # Neovim (lazy.nvim)
├── kitty/                  # Terminal emulator
├── zsh/                    # Shell + starship.toml
├── theme/                  # Colors, GTK, Qt, Kvantum, wallpaper
├── media/                  # Bluetooth, PipeWire, WirePlumber, MPV
├── gaming/                 # MangoHud, GameMode
├── git/                    # Git config + delta
├── gnupg/                  # GPG agent
├── tools/                  # yazi, zathura, swayimg, paru, scripts
├── system/                 # modprobe.d, regreet, xdg-desktop-portal
├── local/                  # .desktop entries, dbus services
└── openspec/               # Project spec files
```

### Hyprland Configuration
- **hypr/hyprland.conf**: Entry point (sources modular configs)
- **hypr/configs/**: 13 modular config files (animations, keybinds, monitors, env, etc.)
- **hypr/systemd/**: NVIDIA suspend/resume fix services
- **hypr/scripts/**: Helper scripts (caps-lock-indicator, brightness)
- **hypr/themes/**: Color overrides for hyprlock

### Terminal Configuration
- **kitty/**: Terminal emulator config (Catppuccin Mocha theme)

### Shell (zsh)
Modular XDG-compliant structure:
- **zsh/.zshenv**: Minimal bootstrap (sets ZDOTDIR only) → symlinked to `~/.zshenv`
- **zsh/config/**: Modular config directory → symlinked to `~/.config/zsh`
  - `.zshrc`, `zsh-env.zsh`, `zsh-options.zsh`, `zsh-completion.zsh`
  - `zsh-plugins.zsh`, `zsh-aliases.zsh`, `zsh-functions.zsh`
  - `zsh-keybindings.zsh`, `zsh-tools.zsh`, `plugins/`
- **zsh/starship.toml**: Prompt config → symlinked to `~/.config/starship.toml`

**Features:** Custom plugin loader, `zsh-defer` lazy loading, starship/zoxide/fzf integration.
**Aliases:** `icy` (nvim launcher), `ls`→`eza`, `cat`→`bat`, `update`→`tools/scripts/update.sh`

### Neovim Configuration
- **nvim/init.lua**: Entry point
- **nvim/lua/config/**: options, lazy.lua, keymaps
- **nvim/lua/plugins/**: core/, editor/, git/, lsp/, snacks/, terminal, debug/, test/
- **nvim/lua/lang/**: Language-specific (lua, rust, python, javascript)
- **nvim/lazy-lock.json**: Plugin lockfile

### Theme
- **theme/**: Core colors (colors.json, catppuccin-mocha.json, apply-theme.sh, matugen/)
- **theme/gtk-3.0/**, **theme/gtk-4.0/**: GTK theming (individual file symlinks; colors.css is runtime-generated)
- **theme/qt5ct/**, **theme/qt6ct/**, **theme/Kvantum/**: Qt theming (whole-dir symlinks)
- **theme/wallpaper/**: wpaperd config + wallpaper images

### Tools
- **tools/yazi/**: Terminal file manager
- **tools/zathura/**: PDF viewer (Catppuccin themed)
- **tools/swayimg/**: Image viewer (Wayland-native)
- **tools/paru/**: AUR helper config
- **tools/scripts/**: Utility scripts (update.sh, discord-compress.sh)

## Development Workflow

### Modifying Neovim Configuration
- Add new plugins by creating files in appropriate `nvim/lua/plugins/` subdirectory
- Language-specific configs go in `nvim/lua/lang/`
- After adding plugins, lazy.nvim will automatically install them on next nvim launch
- Use `:Lazy` command in nvim to manage plugins

### Modifying Hyprland
- Config changes apply after `hyprctl reload` or save (if auto-reload is on)
- Keybind changes: edit `hypr/configs/keybinds.conf`
- QuickShell changes: hot-reload on save (QML)

### Shell Plugin Management
Use the custom `plugin-update` function in zsh to update all plugins:
```bash
plugin-update
```

### Adding a New Module
1. Create directory: `mymodule/`
2. Add `mymodule/install.sh` sourcing `lib/helpers.sh`
3. Add module name to `ALL_MODULES` array in root `install.sh`
4. Run `./install.sh mymodule` to test

## Key Integration Points

- The `icy` function in zsh is the primary nvim launcher (opens Dashboard when no args)
- QuickShell is the unified bar + launcher + notifications system
- Screen locking via hypridle triggers hyprlock after idle
- Audio managed via PipeWire/WirePlumber with Arctis auto-switch service
- Theme changes propagate via `theme/apply-theme.sh` → Hyprland/kitty/nvim/starship/hyprlock/zathura/GTK
