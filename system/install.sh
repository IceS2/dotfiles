#!/usr/bin/env bash
# System-level configuration installer
# Handles: modprobe.d, pacman hooks, QuickShell greeter (greetd), xdg-desktop-portal
source "$(dirname "$0")/../lib/helpers.sh"

log_header "System"

# ── modprobe.d ──
for f in "$DOTFILES_DIR"/system/modprobe.d/*.conf; do
    [[ -f "$f" ]] || continue
    name="$(basename "$f")"
    sudo_copy "system/modprobe.d/$name" "/etc/modprobe.d/$name"
done

# ── pacman hooks (pkglist snapshot) ──
if [[ -f "$DOTFILES_DIR/system/pacman-hooks/update-pkglist" ]]; then
    sudo_copy "system/pacman-hooks/update-pkglist" "/usr/local/bin/update-pkglist"
    sudo chmod 755 /usr/local/bin/update-pkglist
    sudo_copy "system/pacman-hooks/95-pkglist.hook" "/etc/pacman.d/hooks/95-pkglist.hook"
fi

# ── scx_lavd CPU scheduler (sched_ext) ──
# Latency-aware, hybrid P/E-core-aware scheduler. Requires scx-scheds package
# and a kernel with CONFIG_SCHED_CLASS_EXT=y.
if [[ -f "$DOTFILES_DIR/system/scx/scx-lavd.service" ]]; then
    if command -v scx_lavd &>/dev/null; then
        sudo_copy "system/scx/scx-lavd.service" "/etc/systemd/system/scx-lavd.service"
        sudo systemctl daemon-reload
        sudo systemctl enable scx-lavd.service
        log_ok "scx-lavd.service enabled (start: sudo systemctl start scx-lavd)"
    else
        log_warn "scx_lavd not found — install 'scx-scheds' (skipping scheduler service)"
    fi
fi

# ── QuickShell Greeter (greetd login screen) ──
if [[ -f "$DOTFILES_DIR/system/greeter/install.sh" ]]; then
    bash "$DOTFILES_DIR/system/greeter/install.sh"
fi

# ── XDG Desktop Portal ──
if [[ -f "$DOTFILES_DIR/system/xdg-desktop-portal/portals.conf" ]]; then
    link_to system/xdg-desktop-portal/portals.conf \
        "$HOME/.config/xdg-desktop-portal/portals.conf"
fi
