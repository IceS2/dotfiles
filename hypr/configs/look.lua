local C = require("lib.colors")

hl.config({
  general = {
    gaps_in     = 10,
    gaps_out    = 16,
    border_size = 2,

    col = {
      active_border   = { colors = { C.rgb("secondary"), C.rgb("primary") }, angle = 45 },
      inactive_border = C.rgb("surface_container"),
    },

    layout = "dwindle",

    -- Enables the per-window `immediate` rule (see rules.lua, steam_app_*).
    -- Tearing only occurs for fullscreen windows that opt in -- reduces input
    -- latency when FPS exceeds refresh; VRR handles the rest.
    allow_tearing = true,
  },

  dwindle = {
    preserve_split       = true, -- keep split direction permanent (no surprise shifts)
    force_split          = 2,    -- always split right/bottom (predictable)
    special_scale_factor = 0.9,  -- scratchpad at 90% screen size
  },

  decoration = {
    rounding       = 8,
    rounding_power = 2, -- superellipse (squircle) -- iOS/macOS quality corners

    -- Transparency/opacity (fully glassy aesthetic)
    active_opacity     = 0.90,
    inactive_opacity   = 0.75,
    fullscreen_opacity = 1.0,

    -- Subtle inactive dimming (stacks with opacity for extra depth)
    dim_inactive = true,
    dim_strength = 0.05,
    dim_special  = 0.5,

    blur = {
      enabled = true,
      size    = 7,
      passes  = 4,

      -- Quality enhancements
      noise             = 0.0117, -- prevent banding
      contrast          = 0.9,    -- slightly soft (glassy)
      brightness        = 0.95,   -- slightly dark (depth)
      vibrancy          = 0.3,    -- moderate colour boost
      vibrancy_darkness = 0.6,    -- richer dark colours

      popups             = true,  -- blur popups/menus
      popups_ignorealpha = 0.2,
      special            = true,  -- blur scratchpad
    },

    shadow = {
      enabled        = true,
      range          = 20,
      render_power   = 3,
      color          = C.rgba("surface_container_lowest", "aa"),
      color_inactive = C.rgba("surface", "aa"),
      offset         = "0 2", -- directional lighting (downward shadow)
      scale          = 1.0,
    },
  },

  -- Group (tabbed window) styling.
  -- These four colours previously came from the static Catppuccin theme, so
  -- groups silently ignored dynamic theming. Values are identical in static
  -- mode; they now follow the wallpaper too.
  group = {
    col = {
      border_active   = { colors = { C.rgb("secondary"), C.rgb("primary") }, angle = 45 },
      border_inactive = C.rgb("surface_container"),
    },

    groupbar = {
      height    = 14,
      font_size = 10,
      col = {
        active   = C.rgb("secondary"),
        inactive = C.rgb("surface_container"),
      },
      text_color = C.rgb("on_surface"),
    },
  },
})
