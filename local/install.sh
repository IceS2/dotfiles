#!/usr/bin/env bash
# Local user share configuration installer
# Handles: dbus services
source "$(dirname "$0")/../lib/helpers.sh"

log_header "Local"

# DBus services
ensure_dir "$HOME/.local/share/dbus-1/services"
for f in "$DOTFILES_DIR"/local/share/dbus-1/services/*.service; do
    [[ -f "$f" ]] || continue
    name="$(basename "$f")"
    link_to "local/share/dbus-1/services/$name" "$HOME/.local/share/dbus-1/services/$name"
done
