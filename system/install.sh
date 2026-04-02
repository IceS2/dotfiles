#!/usr/bin/env bash
# System-level configuration installer
# Handles: modprobe.d, regreet (greetd), xdg-desktop-portal
source "$(dirname "$0")/../lib/helpers.sh"

log_header "System"

# ── modprobe.d ──
for f in "$DOTFILES_DIR"/system/modprobe.d/*.conf; do
    [[ -f "$f" ]] || continue
    name="$(basename "$f")"
    sudo_copy "system/modprobe.d/$name" "/etc/modprobe.d/$name"
done

# ── ReGreet (greetd login screen) ──
if [[ -d "$DOTFILES_DIR/system/regreet" ]]; then
    log_info "Installing ReGreet configs..."
    sudo mkdir -p /etc/greetd /var/lib/regreet /var/log/regreet

    for conf in config.toml regreet.toml regreet.css hyprland.conf; do
        if [[ -f "$DOTFILES_DIR/system/regreet/$conf" ]]; then
            sudo_copy "system/regreet/$conf" "/etc/greetd/$conf"
        fi
    done

    sudo chown -R greeter:greeter /var/lib/regreet /var/log/regreet 2>/dev/null || true
    sudo chmod 0755 /var/lib/regreet /var/log/regreet 2>/dev/null || true
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
