#!/usr/bin/env bash
# ============================================
# Wallpaper Engine — span / per-monitor / random via swww
# ============================================
# Usage:
#   wallpaper.sh span <image>                  Crop & span across both monitors
#   wallpaper.sh set <image> [image2]          Fit per-monitor (1=both, 2=each)
#   wallpaper.sh set-monitor <output> <image>  Set single monitor
#   wallpaper.sh random [span|fit]             Random from WALLPAPER_DIR
#   wallpaper.sh                               Re-apply last wallpaper (autostart)
#
# Monitor layout is read dynamically from hyprctl monitors.

set -euo pipefail

WALLPAPER_DIR="${WALLPAPER_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/wallpaper/images}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper"
STATE_FILE="$CACHE_DIR/state"
CROP_DIR="$CACHE_DIR/crops"
TRANSITION="--transition-type fade --transition-duration 1"

mkdir -p "$CACHE_DIR" "$CROP_DIR"

# ── Read monitor geometry from Hyprland ──────────────────

read_monitors() {
    # Parse hyprctl monitors into per-output variables:
    #   <name>_W, <name>_H (effective, after transform), <name>_X, <name>_Y
    # Also computes CANVAS_W, CANVAS_H and per-monitor canvas offsets.
    local json
    json="$(hyprctl monitors -j)"

    # Extract per-monitor data (name, effective w/h after transform, x, y)
    eval "$(echo "$json" | python3 -c '
import json, sys
monitors = json.load(sys.stdin)
min_x = min(m["x"] for m in monitors)
min_y = min(m["y"] for m in monitors)
max_r = 0
max_b = 0
for m in monitors:
    t = m.get("transform", 0)
    w, h = m["width"], m["height"]
    if t in (1, 3):
        w, h = h, w
    cx = m["x"] - min_x  # canvas-relative
    cy = m["y"] - min_y
    max_r = max(max_r, cx + w)
    max_b = max(max_b, cy + h)
    safe = m["name"].replace("-", "_")
    print(f"{safe}_W={w} {safe}_H={h} {safe}_X={cx} {safe}_Y={cy}")
print(f"CANVAS_W={max_r} CANVAS_H={max_b}")
# Also emit the output names in order
names = " ".join(m["name"] for m in monitors)
print(f"MONITOR_NAMES=({names})")
')"
}

read_monitors

# ── Helpers ──────────────────────────────────────────────

save_state() {
    # Save last-applied state for autostart re-apply
    printf '%s\n' "$@" > "$STATE_FILE"
}

# Trigger matugen color generation if in dynamic mode
# Skipped when WALLPAPER_PREVIEW=1 (WallpaperPicker handles its own preview pipeline)
trigger_matugen() {
    [[ "${WALLPAPER_PREVIEW:-}" == "1" ]] && return
    local image="$1"
    local theme_dir="${XDG_CONFIG_HOME:-$HOME/.config}/theme"
    local mode_file="$theme_dir/.mode"

    if [[ -f "$mode_file" ]] && [[ "$(cat "$mode_file" | tr -d '[:space:]')" == "dynamic" ]]; then
        if command -v matugen &>/dev/null; then
            # Extract most vibrant color from wallpaper (matugen's built-in
            # quantization favors frequency over vibrancy, producing dull
            # seeds from dark wallpapers). Fall back to image mode if extraction fails.
            local vibrant
            vibrant=$("$theme_dir/extract-color.sh" "$image" 2>/dev/null) || true
            if [[ -n "$vibrant" ]]; then
                matugen color hex "$vibrant" --mode dark -t scheme-vibrant \
                    --config "$theme_dir/matugen/config.toml"
            else
                matugen image "$image" --mode dark -t scheme-vibrant \
                    -r nearest --config "$theme_dir/matugen/config.toml"
            fi
            "$theme_dir/apply-theme.sh"
        fi
    fi
}

apply_swww() {
    local output="$1" image="$2"
    swww img "$image" --outputs "$output" --resize fit $TRANSITION
}

# ── Commands ─────────────────────────────────────────────

cmd_span() {
    local image="$1"
    [[ -f "$image" ]] || { echo "File not found: $image" >&2; exit 1; }

    local hash
    hash="$(stat -c '%Y%s' "$image")_${CANVAS_W}x${CANVAS_H}"

    # Check if all crops exist (cached by mtime+size+geometry)
    local all_cached=true
    for name in "${MONITOR_NAMES[@]}"; do
        local safe="${name//-/_}"
        [[ -f "$CROP_DIR/${hash}_${safe}.jpg" ]] || { all_cached=false; break; }
    done

    if [[ "$all_cached" == false ]]; then
        # Resize source to cover the combined canvas, then crop each monitor region
        local resized="$CROP_DIR/${hash}_resized.jpg"
        magick "$image" -resize "${CANVAS_W}x${CANVAS_H}^" \
            -gravity center -extent "${CANVAS_W}x${CANVAS_H}" \
            "$resized"

        for name in "${MONITOR_NAMES[@]}"; do
            local safe="${name//-/_}"
            local w="${safe}_W" h="${safe}_H" x="${safe}_X" y="${safe}_Y"
            magick "$resized" -crop "${!w}x${!h}+${!x}+${!y}" +repage "$CROP_DIR/${hash}_${safe}.jpg"
        done
        rm -f "$resized"
    fi

    for name in "${MONITOR_NAMES[@]}"; do
        local safe="${name//-/_}"
        apply_swww "$name" "$CROP_DIR/${hash}_${safe}.jpg"
    done
    save_state "span" "$image"
    trigger_matugen "$image"
}

cmd_set() {
    local image1="$1"
    local image2="${2:-$image1}"
    [[ -f "$image1" ]] || { echo "File not found: $image1" >&2; exit 1; }
    [[ -f "$image2" ]] || { echo "File not found: $image2" >&2; exit 1; }

    apply_swww DP-2 "$image1"
    apply_swww DP-1 "$image2"
    save_state "set" "$image1" "$image2"
    trigger_matugen "$image1"
}

cmd_set_monitor() {
    local output="$1" image="$2"
    [[ -f "$image" ]] || { echo "File not found: $image" >&2; exit 1; }

    apply_swww "$output" "$image"
    # Don't overwrite full state — partial update
}

cmd_random() {
    local mode="${1:-fit}"
    local images=()
    while IFS= read -r -d '' f; do
        images+=("$f")
    done < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print0)

    [[ ${#images[@]} -gt 0 ]] || { echo "No images in $WALLPAPER_DIR" >&2; exit 1; }

    local pick="${images[RANDOM % ${#images[@]}]}"

    case "$mode" in
        span) cmd_span "$pick" ;;
        fit)  cmd_set "$pick" ;;
        *)    echo "Unknown mode: $mode (use span or fit)" >&2; exit 1 ;;
    esac
}

cmd_restore() {
    # Re-apply last wallpaper from state file (used on autostart)
    if [[ -f "$STATE_FILE" ]]; then
        mapfile -t args < "$STATE_FILE"
        case "${args[0]}" in
            span) cmd_span "${args[1]}" ;;
            set)  cmd_set "${args[1]}" "${args[2]:-${args[1]}}" ;;
        esac
    else
        # First boot fallback
        local default="$WALLPAPER_DIR/peakpx.jpg"
        if [[ -f "$default" ]]; then
            cmd_set "$default"
        else
            cmd_random fit
        fi
    fi
}

# ── Main ─────────────────────────────────────────────────

case "${1:-}" in
    span)        cmd_span "${2:?Usage: wallpaper.sh span <image>}" ;;
    set)         cmd_set "${2:?Usage: wallpaper.sh set <image> [image2]}" "${3:-}" ;;
    set-monitor) cmd_set_monitor "${2:?Usage: wallpaper.sh set-monitor <output> <image>}" "${3:?}" ;;
    random)      cmd_random "${2:-fit}" ;;
    *)           cmd_restore ;;
esac
