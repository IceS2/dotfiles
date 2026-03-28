# dotfiles

Arch Linux + Hyprland (NVIDIA) rice. Catppuccin Mocha everywhere.

## Stack

| Component | Tool |
|-----------|------|
| WM / Compositor | Hyprland |
| Bar / Launcher / Notifications | QuickShell (QML) |
| Terminal | Kitty |
| Shell | Zsh + Starship |
| Editor | Neovim (lazy.nvim) |
| Theme | Catppuccin Mocha / Matugen (Material You) |
| Wallpaper | wpaperd |
| File Manager | Yazi |
| Audio | PipeWire + WirePlumber |
| GPU | NVIDIA (open-dkms) |

## Structure

```
hypr/           Hyprland config (modular), hypridle, hyprlock, NVIDIA systemd services
quickshell/     QML bar, launcher, notifications, clipboard, overview, media, tray
nvim/           Neovim with lazy.nvim
kitty/          Terminal
zsh/            Shell config + starship.toml
theme/          Colors, GTK 3/4, Qt 5/6, Kvantum, wallpaper (wpaperd)
media/          Bluetooth, PipeWire, WirePlumber, MPV
gaming/         MangoHud, GameMode, gpu-screen-recorder
git/            Git config + delta
gnupg/          GPG agent
tools/          yazi, zathura, swayimg, paru, scripts
system/         modprobe.d, regreet (greetd), xdg-desktop-portal
local/          DBus services
lib/            Shared install helpers
```

## Install

```bash
git clone https://github.com/<user>/dotfiles ~/.dotfiles
cd ~/.dotfiles
./install.sh              # all modules
./install.sh hypr theme   # specific modules
./install.sh --list       # list modules
```

Each module is also standalone: `./theme/install.sh`

All operations are idempotent -- second run shows all [SKIP].

## Keybinds

See `hypr/configs/keybinds.conf`. Designed for Sofle v2 split keyboard with Gallium layout and home row mods.
