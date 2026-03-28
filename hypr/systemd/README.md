# Hyprland Systemd Services

## NVIDIA Suspend/Resume Fix

These services prevent application freezes and crashes when waking from DPMS/suspend on NVIDIA systems.

### The Problem
When Hyprland tries to communicate with the NVIDIA driver after it enters suspend mode, the driver cannot respond. This causes:
- Applications (especially kitty) to freeze for ~1 minute after unlock
- Workspaces temporarily appearing on wrong monitors
- Potential Hyprland crashes

### The Solution
These services suspend Hyprland **before** the NVIDIA driver suspends, and resume it **after** the driver resumes.

## Installation

```bash
# Symlink services to system directory
sudo ln -sf ~/.config/hypr/systemd/hyprland-suspend.service /etc/systemd/system/
sudo ln -sf ~/.config/hypr/systemd/hyprland-resume.service /etc/systemd/system/

# Reload systemd and enable services
sudo systemctl daemon-reload
sudo systemctl enable hyprland-suspend.service
sudo systemctl enable hyprland-resume.service

# Verify services are enabled
systemctl list-unit-files | grep hyprland
```

## Testing

After installation, test by:
1. Locking screen (Super+L or wait 15 minutes)
2. Letting displays power off (wait 20 minutes for DPMS)
3. Coming back and unlocking

**Expected results:**
- ✅ Applications (kitty, etc.) should not freeze
- ✅ Workspaces stay on correct monitors
- ✅ No rendering delays or hangs

## Verification

Check service status:
```bash
systemctl status hyprland-suspend.service
systemctl status hyprland-resume.service
```

View service logs:
```bash
journalctl -u hyprland-suspend.service -u hyprland-resume.service --since today
```

## References
- [Hyprland NVIDIA Suspend Fix](https://github.com/MysticBytes786/hyprland-suspend-fix)
- [Hyprland Issue #7608](https://github.com/hyprwm/Hyprland/issues/7608)
- [Hyprland Forum Discussion](https://forum.hypr.land/t/hyprlock-hypridle-crashes-on-nvidia-when-monitor-goes-off/639)
