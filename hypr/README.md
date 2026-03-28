# Hyprland Configuration

Window manager, compositor, and display configuration for Arch Linux with NVIDIA GPU.

## Structure

```
hypr/
├── configs/
│   ├── autostart.conf
│   ├── decorations.conf
│   ├── env.conf                          → NVIDIA environment variables
│   ├── general.conf
│   ├── groups.conf
│   ├── input.conf
│   ├── keybinds.conf
│   ├── misc.conf
│   ├── monitors.conf                     → Dual monitor setup
│   ├── windowrules.conf
│   └── workspaces.conf                   → Workspace assignments
├── scripts/
│   ├── caps-lock-indicator.sh
│   └── suspend-hyprland.sh               → NVIDIA suspend/resume fix
├── systemd/
│   ├── hyprland-suspend.service          → /etc/systemd/system/
│   ├── hyprland-resume.service           → /etc/systemd/system/
│   └── README.md
├── themes/catppuccin/
├── hyprland.conf                         → Main config (sources modular configs)
├── hypridle.conf                         → Idle management
├── hyprlock.conf                         → Screen lock
├── xdph.conf                             → Portal config
├── install.sh
└── README.md
```

## Features

### Monitor Setup
- **DP-1**: Left monitor, VERTICAL (1440x2560), 165Hz - Even workspaces (2,4,6,8,10)
- **DP-2**: Primary monitor, HORIZONTAL (2560x1440), 165Hz - Odd workspaces (1,3,5,7,9)

### NVIDIA Optimizations
- **AQ_NO_ATOMIC**: Prevents Aquamarine crashes on NVIDIA
- **__GL_THREADED_OPTIMIZATIONS=0**: Preserves OpenGL contexts across lock/unlock
- **nvidia_anti_flicker**: Reduces screen tearing
- **Suspend/Resume Fix**: Prevents application freezes after DPMS wake

### Idle Management (hypridle)
- **5min**: Dim to 10%
- **15min**: Lock screen (hyprlock)
- **20min**: DPMS off (displays power off)

### Theme
- **Catppuccin Mocha** throughout
- Border frame with glassy backdrop
- Blur on all surfaces

## Installation

### Prerequisites

```bash
sudo pacman -S hyprland hypridle hyprlock qt6ct
paru -S hyprpicker-git  # Color picker
```

### Install

```bash
~/.dotfiles/hypr/install.sh
```

The script:
1. Symlinks suspend/resume services to `/etc/systemd/system/` (requires sudo)
2. Enables services for NVIDIA suspend fix
3. Verifies NVIDIA services are enabled
4. Checks configuration files

## NVIDIA Suspend/Resume Fix

### The Problem
On NVIDIA systems, when monitors wake from DPMS or system resume:
- Applications (especially kitty) freeze for ~1 minute
- Workspaces temporarily appear on wrong monitors
- Hyprland may crash or become unresponsive

**Root cause:** Hyprland tries to communicate with NVIDIA driver while it's still suspending/resuming.

### The Solution
The suspend/resume services pause Hyprland **before** the NVIDIA driver suspends:

1. **Before suspend**: Send `STOP` signal to Hyprland (pause process)
2. **NVIDIA driver suspends** (Hyprland is already paused)
3. **NVIDIA driver resumes**
4. **After resume**: Send `CONT` signal to Hyprland (unpause process)

This prevents the race condition that causes freezes.

### Verification

```bash
# Check services are enabled
systemctl list-unit-files | grep hyprland

# Check status
systemctl status hyprland-suspend.service
systemctl status hyprland-resume.service

# View logs after suspend/resume
journalctl -u hyprland-suspend.service -u hyprland-resume.service --since today
```

## Configuration

### Workspace Assignments

Workspaces are bound to monitors in `configs/workspaces.conf`:

```conf
# DP-2 (primary): odd workspaces
workspace = 1, monitor:DP-2, default:true, persistent:true
workspace = 3, monitor:DP-2, persistent:true
# ...

# DP-1 (secondary): even workspaces
workspace = 2, monitor:DP-1, default:true, persistent:true
workspace = 4, monitor:DP-1, persistent:true
# ...
```

The `persistent:true` flag keeps workspaces in the list even when empty.

### Environment Variables

Key NVIDIA settings in `configs/env.conf`:

```conf
env = AQ_NO_ATOMIC,1                      # Prevents Aquamarine crashes
env = __GL_THREADED_OPTIMIZATIONS,0       # Prevents OpenGL context loss
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
```

### Keybindings

Main keybinds in `configs/keybinds.conf`:

- **Super+Q**: Kill active window
- **Super+L**: Lock screen
- **Super+[1-9]**: Switch workspace
- **Super+Shift+[1-9]**: Move window to workspace
- **Super+Arrow**: Navigate windows (vim-style also: HJKL)
- **Super+F**: Toggle fullscreen
- **Super+Space**: Toggle floating

## Usage

### Locking/Idle

```bash
# Manual lock
hyprlock

# Check hypridle status
systemctl --user status hypridle

# View hypridle logs
journalctl --user -u hypridle -f
```

### Monitor Management

```bash
# List monitors
hyprctl monitors

# Move workspace to monitor
hyprctl dispatch moveworkspacetomonitor 1 DP-2

# Toggle DPMS
hyprctl dispatch dpms off
hyprctl dispatch dpms on
```

### Workspace Management

```bash
# List workspaces
hyprctl workspaces

# Switch workspace
hyprctl dispatch workspace 3

# Move window to workspace
hyprctl dispatch movetoworkspace 5
```

## Troubleshooting

### Applications Freeze After Unlock

**Symptoms:**
- Kitty/terminal windows frozen for ~1 minute after unlocking
- Mouse works but applications don't respond
- Workspaces on wrong monitors after wake

**Solution:** Install the suspend/resume fix:

```bash
~/.dotfiles/hypr/install.sh
```

**Verify NVIDIA services are enabled:**
```bash
systemctl is-enabled nvidia-suspend.service
systemctl is-enabled nvidia-resume.service
```

If not enabled:
```bash
sudo systemctl enable nvidia-suspend.service
sudo systemctl enable nvidia-resume.service
```

### Workspace on Wrong Monitor

**After the suspend fix is installed**, workspaces should stay on correct monitors.

If still having issues:
1. Check if both monitors are same model (may cause detection order issues)
2. Run diagnostics:
   ```bash
   # After noticing workspace migration
   hyprctl monitors | grep -E "Monitor|serial|active workspace"
   ```
3. Check hypridle on-resume delay:
   ```bash
   grep "on-resume" ~/.config/hypr/hypridle.conf
   # Should include: sleep 1 && hyprctl dispatch dpms on
   ```

### Hyprland Crashes on Wake

**Check logs:**
```bash
journalctl --user -u hyprland -b
coredumpctl list | grep Hyprland
```

**Common fixes:**
1. Ensure `AQ_NO_ATOMIC=1` in env.conf
2. Install suspend/resume services
3. Update to latest Hyprland/Aquamarine

### Monitor Not Detected

```bash
# Force monitor detection
hyprctl reload

# Check monitor status
hyprctl monitors

# View Hyprland logs
hyprctl logs
```

## QuickShell Integration

The bar and launcher are handled by QuickShell (separate from Hyprland).

See `~/.config/quickshell/` for bar/launcher configuration.

Hyprland autostart in `configs/autostart.conf`:
```conf
exec-once = quickshell
```

## References

- [Hyprland Wiki](https://wiki.hyprland.org/)
- [NVIDIA Suspend Fix](https://github.com/MysticBytes786/hyprland-suspend-fix)
- [Hyprland Issue #7608](https://github.com/hyprwm/Hyprland/issues/7608) - DPMS workspace migration
- [Hyprland Forum](https://forum.hypr.land/t/hyprlock-hypridle-crashes-on-nvidia-when-monitor-goes-off/639)
- [Catppuccin Hyprland](https://github.com/catppuccin/hyprland)

---

**Last Updated:** 2026-02-08
**Maintained By:** ice

**Note:** The NVIDIA suspend/resume fix is REQUIRED on NVIDIA systems to prevent application freezes and workspace migration issues after DPMS wake.
