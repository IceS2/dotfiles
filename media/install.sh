#!/usr/bin/env bash
# Media configuration installer
# Handles: Bluetooth, PipeWire, WirePlumber, MPV, Arctis auto-switch
source "$(dirname "$0")/../lib/helpers.sh"

log_header "Media"

# ── System-level: Bluetooth ──
sudo_copy media/bluetooth/system/main.conf /etc/bluetooth/main.conf

# ── WirePlumber ──
ensure_dir "$HOME/.config/wireplumber/wireplumber.conf.d"
ensure_dir "$HOME/.config/wireplumber/scripts"

link_to media/wireplumber/wireplumber.conf.d/10-bluetooth.conf \
    "$HOME/.config/wireplumber/wireplumber.conf.d/10-bluetooth.conf"
link_to media/wireplumber/wireplumber.conf.d/50-device-priorities.conf \
    "$HOME/.config/wireplumber/wireplumber.conf.d/50-device-priorities.conf"
link_to media/wireplumber/scripts/arctis-auto-switch.sh \
    "$HOME/.config/wireplumber/scripts/arctis-auto-switch.sh"

# ── PipeWire ──
ensure_dir "$HOME/.config/pipewire/pipewire-pulse.conf.d"

for conf in 10-rates.conf 10-resample-quality.conf; do
    src="media/pipewire/pipewire-pulse.conf.d/$conf"
    if [[ -e "$DOTFILES_DIR/$src" ]]; then
        link_to "$src" "$HOME/.config/pipewire/pipewire-pulse.conf.d/$conf"
    fi
done

# ── MPV ──
link_config media/mpv mpv

# ── Arctis auto-switch systemd service ──
if [[ -f "$DOTFILES_DIR/media/wireplumber/systemd/arctis-auto-switch.service" ]]; then
    ensure_dir "$HOME/.config/systemd/user"
    link_to media/wireplumber/systemd/arctis-auto-switch.service \
        "$HOME/.config/systemd/user/arctis-auto-switch.service"
fi

# ── Service restarts (only with --restart flag) ──
if [[ "${1:-}" == "--restart" ]]; then
    log_info "Restarting media services..."
    if systemctl is-active --quiet bluetooth.service; then
        sudo systemctl restart bluetooth.service
        log_ok "Bluetooth restarted"
    fi
    systemctl --user restart pipewire pipewire-pulse wireplumber 2>/dev/null || true
    log_ok "PipeWire stack restarted"
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable arctis-auto-switch.service 2>/dev/null || true
    systemctl --user restart arctis-auto-switch.service 2>/dev/null || true
    log_ok "Arctis auto-switch restarted"
fi
