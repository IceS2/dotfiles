-- Monitors and workspace assignment. Monitors must be declared before the
-- workspace rules that reference them.
--
-- Physical layout: [DP-1 vertical] [DP-2 horizontal]
-- DP-1: left, PORTRAIT, rotated 90 deg clockwise (transform 1).
--       2560x1440 native -> 1440x2560 effective.
--       Position -1440x-460 = left of DP-2, vertically centred.
-- DP-2: centre/main, LANDSCAPE, PRIMARY.

hl.monitor({ output = "DP-1", mode = "2560x1440@165", position = "-1440x-460", scale = 1, transform = 1 })
hl.monitor({ output = "DP-2", mode = "2560x1440@165", position = "0x0",        scale = 1 })

-- Workspace -> monitor, matching the old bspwm layout:
-- odd workspaces on DP-2 (primary), even on DP-1. Workspaces 1 and 2 are the
-- default for their respective monitors. Key "0" maps to workspace 10
-- (it was "0" under bspwm).
for i = 1, 10 do
  hl.workspace_rule({
    workspace = tostring(i),
    monitor   = (i % 2 == 1) and "DP-2" or "DP-1",
    default   = (i == 1 or i == 2) or nil,
  })
end

-- Terminal scratchpad (Super+T)
hl.workspace_rule({
  workspace        = "special:term",
  on_created_empty = "kitty --class scratchpad",
})
