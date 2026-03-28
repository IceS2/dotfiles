#!/usr/bin/env bash
# Hyprland configuration installer
# Handles: config symlink + NVIDIA suspend/resume systemd services
source "$(dirname "$0")/../lib/helpers.sh"

log_header "Hyprland"

# Main config directory
link_config hypr

# ── NVIDIA Suspend/Resume Fix ──
SUSPEND_SRC="hypr/systemd/hyprland-suspend.service"
RESUME_SRC="hypr/systemd/hyprland-resume.service"

if [[ -f "$DOTFILES_DIR/$SUSPEND_SRC" ]] && [[ -f "$DOTFILES_DIR/$RESUME_SRC" ]]; then
    log_info "Installing NVIDIA suspend/resume services..."

    sudo_link "$SUSPEND_SRC" /etc/systemd/system/hyprland-suspend.service
    sudo_link "$RESUME_SRC"  /etc/systemd/system/hyprland-resume.service

    # Only reload/enable if we can run sudo (skip in non-interactive contexts)
    if sudo -n true 2>/dev/null; then
        sudo systemctl daemon-reload
        sudo systemctl enable hyprland-suspend.service 2>/dev/null || true
        sudo systemctl enable hyprland-resume.service 2>/dev/null || true
        log_ok "Suspend/resume services enabled"
    else
        log_warn "Run 'sudo systemctl daemon-reload && sudo systemctl enable hyprland-{suspend,resume}.service' manually"
    fi
fi

# ── Verification ──
log_info "Verifying NVIDIA services..."
for svc in nvidia-suspend nvidia-resume; do
    state=$(systemctl is-enabled "$svc.service" 2>/dev/null || echo "not-found")
    if [[ "$state" == "enabled" ]]; then
        log_ok "$svc.service is enabled"
    else
        log_warn "$svc.service: $state (enable for full suspend/resume support)"
    fi
done
