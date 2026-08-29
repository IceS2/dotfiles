local MOD = "SUPER"

-- ===== Applications =====
hl.bind(MOD .. " + Return",    hl.dsp.exec_cmd("kitty"))
hl.bind(MOD .. " + Space",     hl.dsp.global("quickshell:launcher_toggle"))
hl.bind(MOD .. " + N",         hl.dsp.global("quickshell:notifications_toggle"))
hl.bind(MOD .. " + SHIFT + V", hl.dsp.global("quickshell:clipboard_toggle"))
hl.bind(MOD .. " + W",         hl.dsp.global("quickshell:wallpaper_toggle"))
hl.bind(MOD .. " + SHIFT + T", hl.dsp.global("quickshell:theme_toggle"))
hl.bind(MOD .. " + E",         hl.dsp.global("quickshell:emoji_toggle"))

-- ===== Session management =====
hl.bind(MOD .. " + Q", hl.dsp.window.close())
hl.bind(MOD .. " + X", hl.dsp.global("quickshell:power_toggle"))

-- ===== Window states =====
hl.bind(MOD .. " + F",         hl.dsp.window.fullscreen({ mode = 1 })) -- maximize (keeps gaps/bar)
hl.bind(MOD .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = 0 })) -- real fullscreen
hl.bind(MOD .. " + V",         hl.dsp.window.float({ action = "toggle" }))
hl.bind(MOD .. " + P",         hl.dsp.window.pin())                    -- visible on all workspaces
hl.bind(MOD .. " + O",         hl.dsp.window.set_prop({ prop = "opaque", value = "toggle" }))

-- Minimize / restore
hl.bind(MOD .. " + M",         hl.dsp.window.move({ workspace = "special:minimized", silent = true }))
hl.bind(MOD .. " + SHIFT + M", hl.dsp.workspace.toggle_special("minimized"))
hl.bind(MOD .. " + SHIFT + U", hl.dsp.window.move({ workspace = "e+0", silent = true }))

-- ===== Window management =====
local DIRS = { left = "left", right = "right", up = "up", down = "down" }
for key, dir in pairs(DIRS) do
  hl.bind(MOD .. " + " .. key,         hl.dsp.focus({ direction = dir }))
  hl.bind(MOD .. " + SHIFT + " .. key, hl.dsp.window.swap({ direction = dir }))
end

hl.bind(MOD .. " + C",       hl.dsp.window.center())
hl.bind("ALT + Tab",         hl.dsp.window.cycle_next())
hl.bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ prev = true }))

-- Move current workspace to the other monitor (dual monitor swap)
hl.bind(MOD .. " + CTRL + left",  hl.dsp.workspace.move({ monitor = "l" }))
hl.bind(MOD .. " + CTRL + right", hl.dsp.workspace.move({ monitor = "r" }))

-- ===== Resize submap =====
-- Three step sizes: plain 20px, CTRL 5px (precise), SHIFT 100px (fast).
local RESIZE_STEPS = { [""] = 20, ["CTRL + "] = 5, ["SHIFT + "] = 100 }
local RESIZE_AXES  = {
  right = { 1, 0 }, left = { -1, 0 },
  down  = { 0, 1 }, up   = { 0, -1 },
}

hl.define_submap("resize", function()
  for prefix, step in pairs(RESIZE_STEPS) do
    for key, axis in pairs(RESIZE_AXES) do
      hl.bind(prefix .. key,
        hl.dsp.window.resize({ x = axis[1] * step, y = axis[2] * step, relative = true }),
        { repeating = true })
    end
  end

  -- Exit resize mode
  hl.bind("escape",      hl.dsp.submap("reset"))
  hl.bind("return",      hl.dsp.submap("reset"))
  hl.bind(MOD .. " + R", hl.dsp.submap("reset")) -- toggle off with the same key
end)

hl.bind(MOD .. " + R", hl.dsp.submap("resize"))

-- ===== Mouse bindings =====
hl.bind(MOD .. " + mouse:272", hl.dsp.window.drag(),   { drag = true })
hl.bind(MOD .. " + mouse:273", hl.dsp.window.resize(), { drag = true })

-- ===== Scratchpads =====
hl.bind(MOD .. " + T", hl.dsp.workspace.toggle_special("term"))

-- ===== Workspaces =====
-- Super+1-9,0 switches; Super+Shift+1-9,0 moves. Key "0" maps to workspace 10.
for i = 1, 10 do
  local key = tostring(i % 10)
  hl.bind(MOD .. " + " .. key,         hl.dsp.focus({ workspace = i }))
  hl.bind(MOD .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Cycle workspaces on the current monitor (Super+Home/End on the NAV layer)
local CYCLE = "~/.config/hypr/scripts/cycle-workspace.sh"
hl.bind(MOD .. " + Home",         hl.dsp.exec_cmd(CYCLE .. " prev"))
hl.bind(MOD .. " + End",          hl.dsp.exec_cmd(CYCLE .. " next"))
hl.bind(MOD .. " + SHIFT + Home", hl.dsp.exec_cmd(CYCLE .. " prev --move"))
hl.bind(MOD .. " + SHIFT + End",  hl.dsp.exec_cmd(CYCLE .. " next --move"))

-- Workspace overview (Mission Control)
hl.bind(MOD .. " + Tab", hl.dsp.global("quickshell:overview_toggle"))
hl.bind("mouse:276",     hl.dsp.exec_cmd("qs ipc call overview toggle"))

-- Colour picker (copies hex to clipboard)
hl.bind(MOD .. " + I", hl.dsp.exec_cmd("hyprpicker -a"))

-- ===== Screenshots =====
local SHOT_OUT = "~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png"
hl.bind("Print",
  hl.dsp.exec_cmd("grimblast --notify save screen - | satty --filename - --output-filename " .. SHOT_OUT))
hl.bind("CTRL + Print",
  hl.dsp.exec_cmd("grimblast --notify save area - | satty --filename - --output-filename " .. SHOT_OUT))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("grimblast --notify copy area"))

-- ===== Media & audio keys =====
-- locked = works on the lock screen; repeating = key repeat held down.
hl.bind("XF86AudioRaiseVolume", hl.dsp.global("quickshell:osd_volume_up"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.global("quickshell:osd_volume_down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.global("quickshell:osd_toggle_mute"), { locked = true })

-- Playback control routed through QuickShell (works during fullscreen)
hl.bind("XF86AudioPlay", hl.dsp.global("quickshell:media_toggle_play"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.global("quickshell:media_toggle_play"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.global("quickshell:media_next"),        { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.global("quickshell:media_previous"),    { locked = true })

-- ===== Screen recording =====
hl.bind("ALT + Z",       hl.dsp.exec_cmd("gsr-ui-cli toggle-show"))   -- ShadowPlay-style settings UI
hl.bind(MOD .. " + F9",  hl.dsp.exec_cmd("gsr-ui-cli toggle-replay")) -- instant replay buffer on/off
hl.bind(MOD .. " + F10", hl.dsp.exec_cmd("gsr-ui-cli replay-save"))

-- ===== Jellyfin desktop hardening =====
-- The CEF/Chromium jellyfin-desktop client can hang in fullscreen during a
-- playback stall and wedge the screen. pkill on the binary path works even when
-- the frozen surface covers everything and the window can't be focused.
hl.bind(MOD .. " + SHIFT + J",
  hl.dsp.exec_cmd("pkill -9 -f /opt/jellyfin-desktop/jellyfin-desktop"))
