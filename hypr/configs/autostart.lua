-- Autostart. Replaces exec-once; the handler fires once on compositor start.
-- Commands are dispatched in order; launched processes run asynchronously.

hl.on("hyprland.start", function()
  -- Dispatch the shell before notification-producing services.
  hl.exec_cmd("~/.config/hypr/scripts/start-quickshell.sh")

  -- ===== Theme & appearance =====
  hl.exec_cmd([[gsettings set org.gnome.desktop.interface gtk-theme "catppuccin-mocha-lavender-standard+default"]])
  hl.exec_cmd([[gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"]])

  -- ===== Display & compatibility =====
  -- Set primary monitor for XWayland (fixes gaming resolution/focus issues)
  hl.exec_cmd("xrandr --output DP-2 --primary")

  -- Expose session environment to systemd and D-Bus (needed for screen sharing,
  -- keyring, etc.), then bring up graphical-session.target via
  -- hyprland-session.target so xdg-desktop-portal can start on demand (its unit
  -- has Requisite=graphical-session.target). Chained with && so the env reaches
  -- systemd before the target starts.
  hl.exec_cmd("dbus-update-activation-environment --systemd --all && systemctl --user start hyprland-session.target")

  -- XWayland video bridge for Discord/Zoom screen sharing
  hl.exec_cmd("xwaylandvideobridge")

  -- ===== System services =====
  -- Credential storage (secrets + PKCS#11, no SSH -- using GPG agent for SSH)
  hl.exec_cmd("gnome-keyring-daemon --start --components=pkcs11,secrets")

  -- Polkit authentication agent (GUI privilege prompts)
  hl.exec_cmd("/usr/lib/hyprpolkitagent/hyprpolkitagent")

  -- Idle daemon (screen lock, dpms)
  hl.exec_cmd("hypridle")

  -- Wallpaper daemon (awww handles monitor reconnect natively)
  hl.exec_cmd("awww-daemon && ~/.config/hypr/scripts/wallpaper.sh")

  -- ===== Clipboard ===== (text and images)
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")

  -- ===== System tray =====
  hl.exec_cmd("nm-applet --indicator") -- --indicator = tray icon only, no window
  hl.exec_cmd("udiskie --smart-tray")

  -- ===== User interface =====
  hl.exec_cmd("~/.config/theme/apply-theme.sh --no-reload")

  -- Monitor watcher -- restart services that lose surfaces after a monitor
  -- power cycle (NVIDIA)
  hl.exec_cmd("~/.config/hypr/scripts/monitor-watcher.sh")
end)
