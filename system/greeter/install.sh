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
sudo_copy "system/greeter/hyprland.lua"  "$GREETD_DIR/hyprland.lua"
sudo_copy "system/greeter/greeter.conf"  "$GREETD_DIR/greeter.conf"

# Old hyprlang config -- superseded by hyprland.lua (.conf support dropped in
# Hyprland 0.57). Removed so nobody edits the file that is no longer loaded.
if [[ -f "$GREETD_DIR/hyprland.conf" ]]; then
    sudo rm -f "$GREETD_DIR/hyprland.conf"
    log_ok "Removed stale $GREETD_DIR/hyprland.conf"
fi

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
