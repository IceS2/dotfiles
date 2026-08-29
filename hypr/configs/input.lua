-- Keyboard, mouse, and tablet input.
--
-- Tablet setup: plug in, run `hyprctl devices`, copy the exact name from the
-- "Tablets:" section into hl.device below.
-- Verify: hyprctl devices | grep -A2 "Tablets:"
-- Debug:  sudo libinput debug-events

hl.config({
  input = {
    kb_layout  = "us",
    kb_variant = "intl",

    follow_mouse = 1,

    -- Key repeat (faster than default for snappy editing)
    repeat_rate  = 35,
    repeat_delay = 400,

    -- Mouse (flat = raw input, no acceleration -- best for gaming)
    sensitivity   = 0,
    accel_profile = "flat",

    -- Wacom tablet for drawing in Krita
    tablet = {
      output         = "DP-2",   -- map to the main landscape monitor
      relative_input = false,    -- absolute positioning (required for drawing)
      -- NOTE: use left_handed for 180 deg rotation, not transform -- transform is bugged
      left_handed    = false,
    },
  },
})

-- Per-device mapping.
-- Optional aspect-ratio correction: the Intuos BT S is ~16:10 (152x95mm) and
-- the monitor is 16:9, causing slight vertical stretch. To correct, add:
--   active_area_size = "152 85.5", active_area_position = "0 4.75"
hl.device({
  name   = "wacom-intuos-bt-s-pen",
  output = "DP-2",
})
