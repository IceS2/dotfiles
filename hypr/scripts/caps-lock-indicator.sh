#!/bin/bash
# Check if Caps Lock is on via sysfs (Wayland-compatible)

for f in /sys/class/leds/input*capslock*/brightness; do
    if [[ -f "$f" ]] && [[ "$(cat "$f")" == "1" ]]; then
        echo "CAPS LOCK ON"
        exit 0
    fi
done

echo ""
