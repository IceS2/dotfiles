-- NVIDIA / compositor system tuning.
-- Merged from the old env.conf (render, opengl) and misc.conf (cursor, misc),
-- which split one concern across two files for no reason.

hl.config({
  -- Cursor (NVIDIA fix -- replaces WLR_NO_HARDWARE_CURSORS)
  cursor = {
    no_hardware_cursors = true,
    no_break_fs_vrr     = true,
  },

  misc = {
    vrr            = 3,                      -- content-type based (game/video only)
    enable_swallow = true,                   -- terminal -> GUI window swallowing
    swallow_regex  = "^(kitty|wezterm)$",
  },

  render = {
    -- 2 = auto: bypass the compositor for fullscreen unoccluded clients
    -- (lower input latency, tearing-free games); auto-disengages when an
    -- overlay/popup appears, avoiding the glitches that motivated `false`.
    direct_scanout = 2,
  },

  opengl = {
    nvidia_anti_flicker = true,
  },
})
