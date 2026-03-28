# Wallpaper Configuration

Wallpaper setup using **wpaperd** (Rust, GPU-accelerated) for Hyprland.

---

## Structure

```
~/.dotfiles/theme/wallpaper/
├── install.sh          # Symlink installer
├── README.md           # This file
├── wpaperd/
│   └── config.toml    # wpaperd config
└── images/            # Wallpaper files
    └── peakpx.jpg     # Current: cyberpunk purple
```

---

## Installation

```bash
# Install wpaperd
paru -S wpaperd

# Run installer
cd ~/.dotfiles
./theme/install.sh

# Start daemon
wpaperd -d
```

**Auto-start:** Already added to `~/.config/hypr/hyprland.conf`

---

## Configuration

**File:** `~/.dotfiles/theme/wallpaper/wpaperd/config.toml`

**Current setup:**
- DP-2 (horizontal): `peakpx.jpg`
- DP-1 (vertical): `peakpx.jpg`

**Change wallpaper:**
```toml
[DP-2]
path = "/home/ice/.dotfiles/theme/wallpaper/images/your-image.jpg"
mode = "fit"
```

**Modes:** `fit`, `stretch`, `center`, `tile`, `fit-border-color`

---

## Usage

```bash
# Reload config
wpaperctl reload

# Next/previous (if using directory)
wpaperctl next
wpaperctl previous
```

---

## Adding Wallpapers

1. Copy to `~/.dotfiles/theme/wallpaper/images/`
2. Update `wpaperd/config.toml`
3. Run `wpaperctl reload`

**Sources:**
- Wallhaven.cc (anime + purple filter)
- Catppuccin wallpaper repos
- Search: anime, cozy, pastel, dark, purple

---

## Troubleshooting

```bash
# Check if running
ps aux | grep wpaperd

# Check monitor names
hyprctl monitors

# Restart daemon
killall wpaperd && wpaperd -d
```

---

**Created:** 2026-02-04
**Status:** Production Ready
