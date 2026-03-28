#!/usr/bin/env bash
# ============================================
# Hyprland NVIDIA Suspend/Resume Handler
# ============================================
# Prevents application freezes and crashes when waking from DPMS/suspend
# on NVIDIA systems by pausing Hyprland before the NVIDIA driver suspends.
#
# Source: https://github.com/MysticBytes786/hyprland-suspend-fix
# Related Issues:
#   - https://github.com/hyprwm/Hyprland/issues/7608 (workspace migration)
#   - https://forum.hypr.land/t/hyprlock-hypridle-crashes-on-nvidia-when-monitor-goes-off/639
#
# Usage: Called by systemd services (hyprland-suspend.service / hyprland-resume.service)

case "$1" in
    suspend)
        killall -STOP Hyprland
        ;;
    resume)
        killall -CONT Hyprland
        ;;
    *)
        echo "Usage: $0 {suspend|resume}"
        exit 1
        ;;
esac
