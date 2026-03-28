#!/usr/bin/env bash
# ============================================
# switch-theme.sh — Toggle between static and dynamic theming
# ============================================
# Usage:
#   switch-theme.sh toggle         Toggle between static/dynamic
#   switch-theme.sh static         Switch to static Catppuccin Mocha
#   switch-theme.sh dynamic        Switch to dynamic (wallpaper-based)
#   switch-theme.sh status         Print current mode

set -euo pipefail

THEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/theme"
MODE_FILE="$THEME_DIR/.mode"
COLORS_FILE="$THEME_DIR/colors.json"
STATIC_FILE="$THEME_DIR/catppuccin-mocha.json"
APPLY_SCRIPT="$THEME_DIR/apply-theme.sh"

current_mode() {
    if [[ -f "$MODE_FILE" ]]; then
        cat "$MODE_FILE" | tr -d '[:space:]'
    else
        echo "static"
    fi
}

set_static() {
    echo "static" > "$MODE_FILE"
    cp "$STATIC_FILE" "$COLORS_FILE"
    "$APPLY_SCRIPT"
    echo "Switched to static theme (Catppuccin Mocha)"
}

set_dynamic() {
    echo "dynamic" > "$MODE_FILE"
    # Generate from current wallpaper
    if command -v matugen &>/dev/null; then
        local state_file="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper/state"
        if [[ -f "$state_file" ]]; then
            local wallpaper
            wallpaper="$(sed -n '2p' "$state_file")"
            if [[ -f "$wallpaper" ]]; then
                matugen image "$wallpaper" --mode dark -t scheme-expressive \
                    --config "$THEME_DIR/matugen/config.toml"
                "$APPLY_SCRIPT"
                echo "Switched to dynamic theme (generated from wallpaper)"
                return
            fi
        fi
        echo "No wallpaper found — keeping current colors in dynamic mode"
    else
        echo "matugen not installed — install with: paru -S matugen"
        echo "Keeping current colors in dynamic mode"
    fi
}

toggle() {
    local mode
    mode="$(current_mode)"
    if [[ "$mode" == "static" ]]; then
        set_dynamic
    else
        set_static
    fi
}

case "${1:-toggle}" in
    toggle)  toggle ;;
    static)  set_static ;;
    dynamic) set_dynamic ;;
    status)  echo "Current mode: $(current_mode)" ;;
    *)       echo "Usage: switch-theme.sh {toggle|static|dynamic|status}" >&2; exit 1 ;;
esac
