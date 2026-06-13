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

# ── Arctis 7+ ChatMix daemon ──
# Reads the headset's ChatMix dial over USB HID (interface 5) and creates two
# virtual sinks (Arctis_Game / Arctis_Chat). Requires python-pyusb. The udev
# rule only grants non-root USB access; the service is a plain
# WantedBy=default.target unit that waits for the dongle itself (the upstream
# dev-arctis7.device coupling was unreliable and was removed).
if [[ -f "$DOTFILES_DIR/media/arctis-chatmix/Arctis_7_Plus_ChatMix.py" ]]; then
    ensure_dir "$HOME/.local/bin"
    link_to media/arctis-chatmix/Arctis_7_Plus_ChatMix.py \
        "$HOME/.local/bin/Arctis_7_Plus_ChatMix.py"
    ensure_dir "$HOME/.config/systemd/user"
    link_to media/arctis-chatmix/arctis7pcm.service \
        "$HOME/.config/systemd/user/arctis7pcm.service"
    sudo_copy media/arctis-chatmix/91-steelseries-arctis-7p.rules \
        /etc/udev/rules.d/91-steelseries-arctis-7p.rules
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
    sudo udevadm control --reload-rules 2>/dev/null || true
    sudo udevadm trigger --subsystem-match=usb --attr-match=idVendor=1038 2>/dev/null || true
    # The unit's [Install] changed from WantedBy=dev-arctis7.device to
    # WantedBy=default.target. Do NOT `systemctl disable` here: the unit file
    # is a symlink in ~/.config/systemd/user and `disable` deletes that
    # symlink. Just remove the stale generated want directly.
    rm -f "$HOME/.config/systemd/user/dev-arctis7.device.wants/arctis7pcm.service"
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable arctis7pcm.service 2>/dev/null || true
    if systemctl --user restart arctis7pcm.service 2>/dev/null; then
        log_ok "Arctis ChatMix daemon restarted"
    else
        log_warn "Arctis ChatMix daemon failed to start — check: journalctl --user -u arctis7pcm.service"
    fi
fi
