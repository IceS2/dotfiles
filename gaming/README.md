# Gaming Configuration

Complete Steam and gaming setup for Arch Linux + NVIDIA + Hyprland.

## Setup Complete ✅

- ✅ Steam installed and configured
- ✅ Proton Experimental enabled (Windows game compatibility)
- ✅ NVIDIA drivers with Wayland support (590.48.01 with nvidia-open-dkms)
- ✅ GameMode installed and ready
- ✅ MangoHud configured with performance overlay
- ✅ Hyprland window rules for games
- ✅ VRR/G-Sync environment variables set

## Quick Start

### Launch Options for Steam Games

Right-click game → Properties → Launch Options:

```bash
# Recommended for all games
gamemoderun mangohud %command%

# For Windows games with stuttering
DXVK_ASYNC=1 gamemoderun mangohud %command%

# For games with graphical issues
PROTON_USE_WINED3D=1 gamemoderun %command%
```

### MangoHud Controls (In-Game)

- **Shift+F12** - Toggle overlay on/off
- **Shift+F1** - Cycle FPS limiter (unlimited → 144 → 165)
- **Shift+F2** - Toggle performance logging

### GameMode Verification

Check if GameMode is active while game is running:
```bash
gamemoded -s
```

Expected output: `gamemoded is running`

## Configuration Files

### Locations

- **MangoHud config:** `~/.dotfiles/gaming/MangoHud/MangoHud.conf`
- **GameMode config:** `~/.dotfiles/gaming/gamemode.ini` → `/etc/gamemode.ini`
- **Hyprland gaming rules:** `~/.config/hypr/configs/windowrules.conf`
- **MangoHud logs:** `~/Documents/mangohud_logs/`

### MangoHud Configuration

Edit `~/.dotfiles/gaming/MangoHud/MangoHud.conf` to customize:
- Position: `position=top-right` (or top-left, bottom-right, etc.)
- Font size: `font_size=20`
- Metrics displayed: fps, cpu_temp, gpu_temp, ram, vram, etc.
- Toggle key: `toggle_hud=Shift_R+F12`

After editing, changes apply immediately (no restart needed).

### GameMode Configuration

Edit `~/.dotfiles/gaming/gamemode.ini` to customize:

**CPU Governor:**
- `desiredgov=schedutil` - Dynamic performance (recommended, balanced)
- `desiredgov=performance` - Max performance (highest power, minimal benefit)
- `default_gov=powersave` - Power saving when not gaming

**GPU Mode:**
- `apply_gpu_optimisations=accept` - Max NVIDIA performance during gaming
- `gpu_device=0` - First GPU (adjust if you have multiple GPUs)

**Process Priority:**
- `renice=10` - Game gets niceness -10 (high priority, less likely to be interrupted)

**Notifications:**
- Uses QuickShell Toast for consistent UI via IPC
- Shows "󰊗 GameMode Active" on start, "󰊗 GameMode Disabled" on exit
- IPC command: `qs ipc call toast display "<icon>" "<text>"`
- Icon displayed separately for better visibility

After editing, run `./install.sh gaming` to install to `/etc/gamemode.ini`.

## Steam Window Rules

Games automatically get these optimizations:
- **Fullscreen mode** (no borders, no gaps)
- **Immediate rendering** (reduced input latency)
- **No blur** (better performance)
- **Full opacity** (prevents transparency effects)
- **No rounding** (clean edges)

Window class pattern: `steam_app_*` (matches all Steam games)

## Hyprland NVIDIA Settings

Environment variables in `hyprland.conf`:
```bash
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = NVD_BACKEND,direct
env = __GL_GSYNC_ALLOWED,1
env = __GL_VRR_ALLOWED,1
env = __GL_SYNC_TO_VBLANK,1
```

Cursor settings:
```bash
cursor {
  no_hardware_cursors = true
  no_break_fs_vrr = true
}
```

## Troubleshooting

### Game Has Black Screen
**Cause:** Wrong 32-bit driver
**Fix:**
```bash
sudo pacman -S lib32-nvidia-utils --overwrite '*'
```

### Game Stutters/Lags
**Check:**
1. GameMode is running: `gamemoded -s`
2. CPU governor: `cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`
   - Should be: `schedutil` or `performance` (during gaming)
   - Should NOT be: `powersave` (causes stuttering)
3. GPU usage: `nvidia-smi dmon -s u`
4. QuickShell toast showed "GameMode Active" when game launched

**Try:**
- Add `DXVK_ASYNC=1` to launch options
- Disable blur: Edit hyprland.conf decoration section
- Try different Proton version: Game Properties → Compatibility

### MangoHud Not Showing
**Check:**
1. Config exists: `ls -la ~/.config/MangoHud/`
2. Test: `MANGOHUD=1 vkcube`
3. Launch option includes: `mangohud %command%`

### Game Won't Launch
**Try different Proton:**
- Right-click game → Properties → Compatibility
- Check "Force the use of a specific Steam Play compatibility tool"
- Try: Proton 9.0, Proton 8.0, or Proton Experimental

**Check logs:**
```bash
# Steam logs
~/.local/share/Steam/logs/

# Game-specific log
~/.local/share/Steam/steamapps/compatdata/<APPID>/pfx/drive_c/
```

### Controller Not Working
**Install:**
```bash
sudo pacman -S lib32-libusb
sudo usermod -aG input $USER
# Log out and back in
```

## Per-Game Optimizations

### Competitive Games (CS:GO, Valorant, etc.)
```bash
# Maximize performance, minimal overlays
SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS=0 gamemoderun %command%
```

Disable MangoHud for lowest latency, or use minimal config:
```ini
# MangoHud.conf
fps
cpu_temp
gpu_temp
```

### Heavy/Demanding Games
```bash
# Full monitoring
gamemoderun mangohud %command%
```

Use MangoHud logs to identify bottlenecks:
- Shift+F2 to start logging
- Play for 5 minutes
- Check `~/Documents/mangohud_logs/`

### Older Windows Games
```bash
# Use WineD3D instead of DXVK
PROTON_USE_WINED3D=1 gamemoderun %command%
```

Or try older Proton versions (Proton 5.0, 6.0).

## Gamescope (Advanced)

For games that don't play well with Hyprland:
```bash
# Run game in isolated compositor
gamescope -w 1920 -h 1080 -W 2560 -H 1440 -f --mangoapp -- %command%
```

**Options:**
- `-w/-h` - Game internal resolution
- `-W/-H` - Display resolution (upscaling)
- `-f` - Fullscreen
- `-F fsr` - AMD FSR upscaling
- `--mangoapp` - Use MangoHud with gamescope

## VRR (Variable Refresh Rate)

Currently **enabled** in Hyprland config (`vrr = 3` — content-type based, activates for games/video only).

Both monitors run at 165Hz with G-Sync enabled via `__GL_GSYNC_ALLOWED=1` and `__GL_VRR_ALLOWED=1`.

## Performance Monitoring

### Real-time GPU Stats
```bash
# GPU usage monitor
nvidia-smi dmon -s u

# GPU temperature/power
watch -n 1 nvidia-smi
```

### MangoHud Logging Analysis
```bash
# Start game with logging
# In-game: Shift+F2 to start, Shift+F2 to stop

# Analyze logs
cd ~/Documents/mangohud_logs/
cat *.log | grep -E "fps|frametime"
```

## Useful Commands

```bash
# Test Vulkan + MangoHud
MANGOHUD=1 vkcube

# Check GameMode status
gamemoded -s

# List installed Proton versions
ls ~/.local/share/Steam/steamapps/common/ | grep Proton

# Check which GPU game is using
nvidia-smi

# Steam logs
tail -f ~/.local/share/Steam/logs/stderr.txt
```

## Setup

To install/update configurations:
```bash
./install.sh gaming
# or standalone:
./gaming/install.sh
```

This symlinks MangoHud config, creates the log directory, and copies `gamemode.ini` to `/etc/`.

## Resources

- [ProtonDB](https://www.protondb.com/) - Game compatibility database
- [Steam Deck Verified](https://www.steamdeck.com/en/verified) - Proton-verified games
- [MangoHud GitHub](https://github.com/flightlessmango/MangoHud) - Documentation
- [Hyprland Wiki](https://wiki.hypr.land/) - Window manager docs

## Screen Recording (Instant Replay)

GPU Screen Recorder with NVENC hardware encoding (3-5% CPU overhead).

### Keybinds

- **Alt+Z** - Open/close ShadowPlay-style overlay (configure settings here)
- **Super+F9** - Toggle replay buffer on/off
- **Super+F10** - Save replay clip

### Workflow

1. Start gaming, press **Super+F9** to enable replay buffer (records last 5min to RAM)
2. Something cool happens, press **Super+F10** to save clip
3. Done gaming, press **Super+F9** to stop replay buffer

### Compress for Discord

```bash
# Default 25MB target
discord-compress ~/Videos/Replays/clip.mkv

# Custom size (e.g., 10MB)
discord-compress ~/Videos/Replays/clip.mkv 10
```

Uses NVENC two-pass encoding. Warns if video is too long for target size.

### Configuration

- **Overlay settings:** Alt+Z (codec, quality, audio, replay duration, output folder)
- **Replay output:** `~/Videos/Replays/`
- **Systemd service:** `gpu-screen-recorder-ui.service` (keeps daemon available)
- **Compress script:** `~/.dotfiles/tools/scripts/discord-compress.sh`

## Next Steps

1. **Launch a game** with `gamemoderun mangohud %command%`
2. **Test MangoHud** (Shift+F12 to toggle)
3. **Monitor performance** and adjust settings as needed
4. **Report issues** to ProtonDB for Windows games
5. **Customize MangoHud** config for your preferences
