# QuickShell Configuration

Personal QuickShell setup for Hyprland with application launcher.

## Requirements

**System:**
- Arch Linux + Hyprland (Wayland)
- NVIDIA GPU configured (works on any GPU)

**Install:**
```bash
# QuickShell with all features
paru -S quickshell-allflags-git

# Dependencies (auto-installed)
# qt6-base qt6-declarative qt6-svg qt6-wayland kitty ttf-jetbrains-mono-nerd
```

**Recommended:**
- Icon theme: Papirus, Breeze, or Catppuccin
- Font: JetBrainsMono Nerd Font

## Installation

```bash
# Symlink to config directory
ln -sf ~/.dotfiles/quickshell ~/.config/quickshell

# Test it works
quickshell

# Add to Hyprland config
echo 'exec-once = quickshell' >> ~/.config/hypr/hyprland.conf
echo 'bind = SUPER, Space, exec, qs ipc call launcher toggle' >> ~/.config/hypr/hyprland.conf

# Reload Hyprland
hyprctl reload
```

## Modules

### 🚀 Launcher (Production Ready)

Application launcher with fuzzy search and keyboard navigation.

**Features:**
- Fuzzy search (name, description, ID)
- Keyboard navigation (arrows, Home/End, Enter, ESC)
- System icon theme integration
- Auto-detects terminal apps (launches in kitty)
- IPC control via keybind

**Keybinds:**
| Key | Action |
|-----|--------|
| `Super+Space` | Toggle launcher |
| `ESC` | Close |
| `↑/↓` | Navigate |
| `Enter` | Launch selected app |
| `Home/End` | Jump to first/last |

**IPC Usage:**
```bash
qs ipc call launcher toggle  # Toggle visibility
qs ipc call launcher show    # Show
qs ipc call launcher hide    # Hide
```

## Customization

**Colors** - Edit `launcher/launcher.qml`:
```qml
// Catppuccin Mocha theme (lines 31-36)
readonly property color ctp_base: "#1e1e2e"
readonly property color ctp_mauve: "#cba6f7"
// ... etc
```

**Terminal** - Edit `launcher/launcher.qml`:
```qml
// Change "kitty" to your terminal in launchApp() function
Quickshell.execDetached(["kitty", "-e"].concat(app.command))
// Examples: ["alacritty", "-e"] or ["wezterm", "start", "--"]
```

**Window Size** - Edit `launcher/launcher.qml`:
```qml
implicitWidth: 800   // Change width
implicitHeight: 600  // Change height
```

**Keybind** - Edit `~/.config/hypr/hyprland.conf`:
```conf
bind = SUPER, D, exec, qs ipc call launcher toggle  # Use Super+D instead
```

## Troubleshooting

**Launcher doesn't appear:**
```bash
pgrep quickshell                              # Check if running
cat /run/user/1000/quickshell/by-id/*/log.qslog  # Check logs
qs ipc show                                   # Verify IPC works
```

**Icons missing:**
```bash
paru -S papirus-icon-theme                    # Install icon theme
export QS_ICON_THEME="Papirus"                # Set theme (optional)
```

**Terminal apps don't launch:**
```bash
which kitty                                   # Verify kitty installed
# Or change terminal in launcher/launcher.qml launchApp() function
```

**Keybind doesn't work:**
```bash
qs ipc call launcher toggle                   # Test IPC directly
hyprctl reload                                # Reload Hyprland config
```

## Development

**Hot Reload:**
Changes to QML files apply instantly on save (no restart needed).

**Debug Mode:**
```bash
QT_LOGGING_RULES="*.debug=true" quickshell    # Verbose output
qs ipc show                                   # List IPC targets
```

## Structure

```
quickshell/
├── shell.qml              # Entry point + Bar definitions + IPC handlers
├── qmldir                 # Module definitions
├── services/              # Singleton services
│   ├── Theme.qml          # Catppuccin Mocha theme + design tokens
│   ├── Audio.qml          # Volume control (wpctl)
│   ├── Network.qml        # Network status (nmcli)
│   ├── Clock.qml          # Time/date service
│   ├── Workspaces.qml     # Hyprland workspace tracking
│   └── Launcher.qml       # Application launcher logic
├── components/            # UI components
│   ├── Bar.qml            # Status bar component
│   ├── LauncherWindow.qml # Launcher window
│   ├── WorkspacesWidget.qml
│   ├── VolumeWidget.qml
│   ├── NetworkWidget.qml
│   ├── ClockWidget.qml
│   ├── AppListItem.qml
│   ├── EmptyState.qml
│   └── Icon.qml
└── README.md              # This file
```

## Resources

- [QuickShell Docs](https://quickshell.org/docs/)
- [QuickShell GitHub](https://github.com/quickshell-mirror/quickshell)

---

**Note:** Minor Qt SVG warning during startup is harmless. Icons render correctly.
