#!/bin/bash
# Resume script after system suspend - restarts services with dead surfaces
# Called by hypridle after_sleep_cmd
#
# Note: monitor-watcher.sh handles the same restarts via monitoradded events,
# but this script is a reliable fallback since hypridle's after_sleep_cmd
# always fires on resume regardless of monitor event timing.
# Note: swww handles monitor reconnect natively — no wallpaper recovery needed.

log() {
    echo "[$(date '+%H:%M:%S')] resume: $*" >> /tmp/hypr-resume.log
}

restart_quickshell() {
    # Try non-destructive IPC hard reload first (preserves D-Bus + notification server)
    if qs ipc call shell reload 2>/dev/null; then
        log "QuickShell hard reload triggered via IPC"
        sleep 2
        if hyprctl layers -j | grep -q quickshell; then
            log "QuickShell surfaces recovered via reload"
            return 0
        fi
        log "Reload succeeded but surfaces still missing, falling back to restart"
    else
        log "IPC reload failed, falling back to restart"
    fi

    # Fallback: full restart (breaks long-lived D-Bus clients like Waterfox)
    pkill -9 quickshell
    sleep 0.5
    quickshell &
    log "QuickShell restarted (PID: $!)"

    # Wait for D-Bus notification server to register
    if timeout 10 bash -c 'until dbus-send --session --print-reply \
        --dest=org.freedesktop.DBus /org/freedesktop/DBus \
        org.freedesktop.DBus.GetNameOwner \
        string:"org.freedesktop.Notifications" &>/dev/null; do
        sleep 0.2
    done'; then
        log "D-Bus notification server registered"
    else
        log "WARNING: notification server did not register within 10s"
    fi
}

log "=== Resume triggered ==="

# Wait for monitors to stabilize
sleep 2

# Restart QuickShell if surfaces are gone
if ! hyprctl layers -j | grep -q quickshell; then
    log "QuickShell surfaces lost"
    restart_quickshell
else
    log "QuickShell surfaces OK"
fi

# Check for frozen Kitty terminals
FROZEN_KITTY=$(hyprctl clients -j | jq -r '.[] | select(.class == "kitty") | select(.mapped == false) | .address' 2>/dev/null)
if [[ -n "$FROZEN_KITTY" ]]; then
    log "WARNING: Found potentially frozen Kitty terminals"
fi

log "Resume complete"
