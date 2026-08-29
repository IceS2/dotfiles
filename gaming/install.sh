#!/usr/bin/env bash
# Gaming configuration installer
# Handles: MangoHud, GameMode
source "$(dirname "$0")/../lib/helpers.sh"

log_header "Gaming"

# MangoHud config
link_config gaming/MangoHud MangoHud

# MangoHud log directory
ensure_dir "$HOME/Documents/mangohud_logs"

# GameMode system config
sudo_copy gaming/gamemode.ini /etc/gamemode.ini

# ── Sunshine game streaming (host) ──
# User configs: per-file symlinks ONLY — ~/.config/sunshine holds Sunshine's
# own credentials + pairing state and must stay a real directory.
ensure_dir "$HOME/.config/sunshine"
link_to gaming/sunshine/sunshine.conf "$HOME/.config/sunshine/sunshine.conf"
link_to gaming/sunshine/apps.json     "$HOME/.config/sunshine/apps.json"

# System integration for Sunshine
sudo_copy gaming/sunshine/uinput.conf            /etc/modules-load.d/uinput.conf
sudo_copy gaming/sunshine/99-sunshine-setcap.hook /etc/pacman.d/hooks/99-sunshine-setcap.hook

# Load uinput now (module autoload only takes effect next boot) + refresh udev
sudo modprobe uinput
sudo udevadm control --reload-rules && sudo udevadm trigger

# systemd user drop-in: bind Sunshine to the graphical session (inherits Wayland env)
if command -v sunshine &>/dev/null; then
    dropin_dir="$HOME/.config/systemd/user/app-dev.lizardbyte.app.Sunshine.service.d"
    ensure_dir "$dropin_dir"
    link_to gaming/sunshine/systemd-override.conf "$dropin_dir/override.conf"

    # KMS capture capability (dropped on every upgrade — pacman hook re-applies it)
    sudo setcap 'cap_sys_admin,cap_sys_nice+p' "$(readlink -f "$(command -v sunshine)")"

    systemctl --user daemon-reload
    # --now also STARTS it this session; `enable` alone won't start a unit whose
    # graphical-session.target is already active (would need a re-login otherwise).
    systemctl --user enable --now app-dev.lizardbyte.app.Sunshine.service
    log_ok "Sunshine service enabled + started (also auto-starts with graphical-session.target)"
else
    log_warn "sunshine not installed — run 'paru -S sunshine-bin', then re-run ./gaming/install.sh"
fi
