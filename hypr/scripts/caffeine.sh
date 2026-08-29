#!/usr/bin/env bash
# Caffeine toggle: prevents screen lock + system suspend by turning hypridle
# off. hypridle owns the idle timers (see hypr/hypridle.conf) and ignores
# systemd inhibitors, so the reliable way to "caffeinate" is to stop the
# daemon and relaunch it to restore normal idle behaviour.

if pidof hypridle >/dev/null; then
    pkill hypridle
    qs ipc call toast display "󰛊" "Caffeine ON — idle disabled"
else
    hypridle &
    disown
    qs ipc call toast display "󰾪" "Caffeine OFF — idle enabled"
fi
