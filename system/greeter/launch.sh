#!/usr/bin/env bash
# QuickShell Greeter Launcher
# Reads greeter.conf and launches QuickShell with correct env vars.
# Called from hyprland.conf exec-once.

CONF="/etc/greetd/greeter.conf"

# Portals are unused in the greeter and crash when its compositor exits.
systemctl --user --quiet mask --runtime --now \
    xdg-desktop-portal.service \
    xdg-desktop-portal-gtk.service \
    xdg-desktop-portal-hyprland.service

# Parse theme from greeter.conf
THEME=$(sed -n 's/^theme *= *//p' "$CONF" 2>/dev/null)
export QS_THEME="${THEME:-pixel-rainyroom}"

# Import shims path (Qt5→Qt6 bridges for SDDM themes)
export QML2_IMPORT_PATH="/etc/greetd/imports"

exec quickshell -p /etc/greetd/greeter_shell.qml
