-- Window and layer rules.
--
-- Property values keep their hyprlang spelling verbatim (e.g.
-- opacity = "1.0 override 1.0 override"); only the wrapper changed.

-- ===== Scratchpad styling =====
hl.window_rule({
  name  = "scratchpad",
  match = { class = "^(scratchpad)$" },
  float   = true,
  size    = "70% 70%",
  center  = true,
  opacity = "0.95 override 0.95 override",
})

-- ===== Gaming =====

-- Shared performance/visual profile. Applied to the Steam class pattern and to
-- gamescope, which are byte-identical rule sets in the old config.
local function gaming_profile(name, match)
  hl.window_rule({
    name  = name,
    match = match,
    -- Performance
    immediate = true,
    content   = "game",
    no_blur   = true,
    -- Visual cleanup
    border_size = 0,
    rounding    = 0,
    opacity     = "1.0 override 1.0 override",
    -- Placement
    workspace = "1 silent", -- dedicated gaming workspace
    monitor   = "DP-2",     -- always on primary
  })
end

-- Steam games use the class pattern steam_app_<APPID>
gaming_profile("steam-games", { class = "^(steam_app_)" })

-- gamescope (Lutris) -- the game runs nested inside gamescope, so the Hyprland
-- window class is "gamescope", not steam_app_*.
gaming_profile("gamescope", { class = "^(gamescope)$" })

-- Guilty Gear Strive (APPID 1384160). Supplements the steam_app_ rules above
-- with title-matched placement; NOT a third copy of the gaming profile.
hl.window_rule({
  name  = "guilty-gear",
  match = { title = "^(Guilty Gear)" },
  monitor    = "DP-2",
  workspace  = "1",
  fullscreen = true,
})

-- Guild Wars 2 (Lutris/umu Proton -- native, no gamescope; class gw2-64.exe).
-- Launcher and game share this class. Deliberately NOT the gaming profile.
-- suppress_event fullscreen: the game requests fullscreen on map
-- (fullscreenClient), which would override float/center -- suppressing it keeps
-- the window floating.
-- monitor DP-2: DP-1 is rotated, and moving a fullscreen buffer across
-- transforms corrupts on NVIDIA.
hl.window_rule({
  name  = "gw2",
  match = { class = "^(gw2-64\\.exe)$" },
  monitor        = "DP-2",
  suppress_event = "fullscreen maximize",
  float          = true,
  center         = true,
})

-- Stremio -- deliberately excluded from immediate/VRR: prevents the cursor
-- freeze on paused video.
hl.window_rule({
  name  = "stremio",
  match = { class = "^(com.stremio.stremio)$" },
  no_blur = true,
  opacity = "1.0 override 1.0 override",
  content = "none",
})

-- ===== Application opacity =====
-- Waterfox -- force fully opaque (overrides global active/inactive opacity)
hl.window_rule({
  name  = "waterfox-opaque",
  match = { class = "^(waterfox)$" },
  opacity = "1.0 override 1.0 override",
})

-- ===== Polkit agent ===== (styled, pinned, centered)
hl.window_rule({
  name  = "polkit-agent",
  match = { class = "^(hyprpolkitagent)$" },
  float  = true,
  center = true,
  pin    = true,
})

-- ===== Utility windows =====
-- XWayland video bridge -- hide the bridge window
hl.window_rule({
  name  = "xwaylandvideobridge",
  match = { title = "^(xwaylandvideobridge)" },
  opacity = "0.0 override 0.0 override",
  size    = "1 1",
  move    = "0 0",
})

-- ===== QuickShell layer rules =====
-- Every QuickShell surface gets blur + ignore_alpha. All use 0.05 except the
-- power menu, which needs a higher threshold for its dimmed backdrop.
local QUICKSHELL_LAYERS = {
  "border", "bar",
  "launcher-box",
  "notification-popup", "notification-center",
  "calendar",
  "clipboard-box",
  "wallpaper",
  "overview",
  "tray-popup", "tray-menu",
  "media", "audio", "network", "bluetooth",
  "performance", "updates",
  "toast", "emoji",
}

for _, ns in ipairs(QUICKSHELL_LAYERS) do
  hl.layer_rule({
    match        = { namespace = "quickshell-" .. ns },
    blur         = true,
    ignore_alpha = 0.05,
  })
end

hl.layer_rule({
  match        = { namespace = "quickshell-power" },
  blur         = true,
  ignore_alpha = 0.3,
})
