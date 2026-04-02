#!/usr/bin/env bash
# ============================================
# Monitor Watcher — Restart services on monitor reconnect
# ============================================
# NVIDIA + DisplayPort drops HPD on power-off, causing Hyprland to destroy
# wl_outputs. QuickShell loses its layer surfaces and cannot recover.
# This script listens for monitoradded events and restarts it.
# Note: awww handles monitor reconnect natively — no wallpaper recovery needed.
#
# Launched via exec-once in autostart.conf

log() {
    echo "[$(date '+%H:%M:%S')] monitor-watcher: $*" >> /tmp/hypr-resume.log
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

restart_services() {
    sleep 2

    # Restart QuickShell if layer surfaces are gone
    if ! hyprctl layers -j | grep -q quickshell; then
        log "QuickShell surfaces lost"
        restart_quickshell
    else
        log "QuickShell surfaces OK"
    fi
}

main() {
    log "=== Monitor watcher started ==="

    socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" \
        | while read -r line; do
            case "$line" in
                monitoradded*)
                    log "Event: $line"
                    restart_services
                    ;;
            esac
        done

    log "Socket closed, exiting"
}

main
