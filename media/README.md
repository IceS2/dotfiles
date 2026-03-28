# Media Configuration

Audio, Bluetooth, and media configuration for Arch Linux with PipeWire/WirePlumber.

## Structure

```
media/
├── bluetooth/system/main.conf              → /etc/bluetooth/main.conf
├── wireplumber/
│   ├── wireplumber.conf.d/
│   │   ├── 10-bluetooth.conf               → ~/.config/wireplumber/wireplumber.conf.d/
│   │   └── 50-device-priorities.conf       → ~/.config/wireplumber/wireplumber.conf.d/
│   ├── scripts/arctis-auto-switch.sh       → ~/.config/wireplumber/scripts/
│   └── systemd/arctis-auto-switch.service  → ~/.config/systemd/user/
├── pipewire/pipewire-pulse.conf.d/
│   ├── switch-on-connect.conf              → ~/.config/pipewire/pipewire-pulse.conf.d/
│   ├── 10-rates.conf                       → ~/.config/pipewire/pipewire-pulse.conf.d/
│   └── 10-resample-quality.conf            → ~/.config/pipewire/pipewire-pulse.conf.d/
├── mpv/mpv.conf                            → ~/.config/mpv/mpv.conf
├── install.sh
└── README.md
```

## Features

### Bluetooth
- **AutoEnable** - Adapter powers on at boot
- **High-quality codecs** - LDAC (990kbps), aptX HD, aptX, AAC, SBC-XQ
- **Hardware volume control** enabled

### Audio Device Priorities
- **Arctis 7+**: 1400 (highest)
- **USB S/PDIF**: 1200
- **Other USB**: 900

### Auto-Switching (Arctis 7+)
- **Detection**: HeadsetControl battery status polling
- **Headset ON** → Arctis output + Arctis mic
- **Headset OFF** → S/PDIF output + USB mic
- **Polling**: Every 3 seconds

### Sample Rates
- **Default**: 48kHz
- **Supported**: 44.1, 48, 88.2, 96, 192 kHz (no resampling when matched)
- **Quality**: Level 10 (high quality, balanced CPU)

## Installation

### Prerequisites

```bash
sudo pacman -S pipewire pipewire-pulse wireplumber bluez bluez-utils mpv
paru -S headsetcontrol  # Required for Arctis auto-switch
```

### Install

```bash
~/.dotfiles/media/install.sh
```

The script:
1. Copies `/etc/bluetooth/main.conf` (requires sudo)
2. Symlinks configs to `~/.config/`
3. Enables and starts `arctis-auto-switch.service`
4. Restarts audio services

## Usage

### Bluetooth

```bash
# Enable at boot
sudo systemctl enable bluetooth

# Pair device (CLI)
bluetoothctl
> power on
> scan on
> pair <MAC>
> trust <MAC>
> connect <MAC>
```

### Audio Management

```bash
# List devices
wpctl status

# Set default
wpctl set-default <ID>

# Check priorities
wpctl inspect <ID> | grep priority

# Monitor audio
pw-top
```

### Arctis Auto-Switch

```bash
# Check service
systemctl --user status arctis-auto-switch
journalctl --user -u arctis-auto-switch -f

# Test HeadsetControl
headsetcontrol -b
# ON:  BATTERY_AVAILABLE + level
# OFF: BATTERY_UNAVAILABLE

# Stop/start service
systemctl --user stop arctis-auto-switch
systemctl --user start arctis-auto-switch
```

## Customization

### Change Device Priority

Edit `wireplumber/wireplumber.conf.d/50-device-priorities.conf`:

```json
{
  matches = [ { node.name = "~alsa_.*YourDevice.*" } ]
  actions = {
    update-props = {
      priority.driver = 1300
      priority.session = 1300
    }
  }
}
```

Restart: `systemctl --user restart wireplumber`

**Guidelines:**
- Sinks (outputs): 600-1000 default, max 1500
- Sources (inputs): 1600-2000 default

### Change LDAC Quality

Edit `wireplumber/wireplumber.conf.d/10-bluetooth.conf`:

```lua
["bluez5.a2dp.ldac.quality"] = "hq"  # Options: auto, hq, sq, mq
```

- `hq` = 990kbps (best quality)
- `sq` = 660kbps (balanced)
- `mq` = 330kbps (mobile)
- `auto` = adaptive

### Change Sample Rates

Edit `pipewire/pipewire-pulse.conf.d/10-rates.conf`:

```conf
default.clock.allowed-rates = [ 44100 48000 96000 ]
```

## Troubleshooting

### Arctis Auto-Switch Not Working

```bash
# 1. Check HeadsetControl
headsetcontrol -b
# Should show BATTERY_AVAILABLE when headset is ON

# 2. Check service logs
journalctl --user -u arctis-auto-switch -n 50

# 3. Verify node IDs
wpctl status
# Compare with script output

# 4. Test script manually
~/.config/wireplumber/scripts/arctis-auto-switch.sh
```

**Common issues:**
- HeadsetControl not installed: `paru -S headsetcontrol`
- Wrong device names: Edit script variables at top
- Service not enabled: `systemctl --user enable arctis-auto-switch`

### Bluetooth Audio Quality Issues

```bash
# Check active codec
pactl list sinks | grep -A10 bluez | grep codec
# Should show LDAC, aptX, or AAC (not SBC)

# If using SBC:
# 1. Device may not support better codecs
# 2. Restart WirePlumber: systemctl --user restart wireplumber
# 3. Reconnect device
```

### Device Doesn't Auto-Switch

```bash
# Check if module loaded
pactl list modules | grep switch-on-connect

# Verify config exists
ls ~/.config/pipewire/pipewire-pulse.conf.d/switch-on-connect.conf

# Restart
systemctl --user restart pipewire-pulse
```

### Audio Crackling

```bash
# Increase buffer size in 10-rates.conf:
default.clock.quantum = 2048  # Increase from 1024

# Restart
systemctl --user restart pipewire pipewire-pulse wireplumber
```

## Hyprland Integration

Volume keys in `hyprland.conf`:

```conf
binde = , XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
binde = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
```

Bluetooth applet:

```conf
exec-once = blueman-applet
```

## References

- [PipeWire Documentation](https://docs.pipewire.org/)
- [WirePlumber 0.5 Documentation](https://pipewire.pages.freedesktop.org/wireplumber/)
- [WirePlumber ALSA Configuration](https://pipewire.pages.freedesktop.org/wireplumber/daemon/configuration/alsa.html)
- [HeadsetControl](https://github.com/Sapd/HeadsetControl)
- [ArchWiki: Bluetooth](https://wiki.archlinux.org/title/Bluetooth)
- [ArchWiki: PipeWire](https://wiki.archlinux.org/title/PipeWire)

---

**Last Updated:** 2026-02-04
**Maintained By:** ice

**Note:** Auto-switch requires HeadsetControl. The script detects headset power state via battery availability, not USB dongle connection.
