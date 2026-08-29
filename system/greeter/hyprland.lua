-- Hyprland config for the QuickShell greeter (Lua).
-- Copied to: /etc/greetd/hyprland.lua, loaded via `--config` from config.toml.
--
-- Replaces the deprecated hyprlang config (hyprland.conf); upstream drops
-- .conf support in 0.57. Keep this minimal: it exists only to bring up two
-- monitors and hand the screen to QuickShell.

-- ===== Portals =====
-- The greeter user has no portal stack running; asking GTK to use one stalls.
hl.env("GTK_USE_PORTAL", "0")
hl.env("GDK_DEBUG", "no-portals")

-- ===== Rendering quality =====
hl.env("GDK_SCALE", "1")
hl.env("GDK_DPI_SCALE", "1")
hl.env("XCURSOR_SIZE", "24")

-- ===== NVIDIA =====
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("__GL_GSYNC_ALLOWED", "1")
hl.env("__GL_VRR_ALLOWED", "0") -- off at the greeter: no benefit, avoids modeset churn

-- ===== Monitors ===== (both enabled; theme renders on DP-2, black on DP-1)
-- NOTE: DP-1 sits at -1440x-560 here, not the -1440x-460 the session uses.
-- Intentional? Probably not, but it only shifts the black filler screen.
hl.monitor({ output = "DP-2", mode = "2560x1440@165", position = "0x0",        scale = 1 })
hl.monitor({ output = "DP-1", mode = "2560x1440@165", position = "-1440x-560", scale = 1, transform = 1 })

hl.config({
  -- Software cursor (NVIDIA)
  cursor = {
    no_hardware_cursors = true,
  },

  -- Chromeless: the greeter is one fullscreen surface, no window decoration.
  general = {
    gaps_in     = 0,
    gaps_out    = 0,
    border_size = 0,
  },

  decoration = {
    rounding = 0,
  },

  animations = {
    enabled = false,
  },

  misc = {
    disable_hyprland_logo    = true,
    disable_splash_rendering = true,
    force_default_wallpaper  = 0,
  },
})

hl.workspace_rule({ workspace = "1", monitor = "DP-2", default = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-2" })

-- ===== Launch the greeter =====
-- launch.sh execs quickshell and blocks; when it returns (user picked a
-- session, greeter quit) we tear down this compositor so greetd can start the
-- real session.
hl.on("hyprland.start", function()
  hl.exec_cmd("/etc/greetd/launch.sh; hyprctl dispatch exit")
end)
