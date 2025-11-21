local wezterm   = require("wezterm")
local action    = wezterm.action
local F = {}

function F.is_linux()
  return wezterm.target_triple:find("linux") ~= nil
end

function F.is_macos()
  return wezterm.target_triple:find("apple") ~= nil
end

function F.is_windows()
  return wezterm.target_triple:find("windows") ~= nil
end

-- Check if file exists
function F.file_exists(name)
  local file = io.open(name,"r")
  if file ~= nil then
    io.close(file)
    return true
  else
    return false
  end
end

-- Match the appearance to the system's style
function F.scheme_for_appearance(appearance, dark, light)
  if appearance:find "Dark" then
    return dark
  else
    return light
  end
end

-- Get basename of path
function F.basename(string)
  return string.gsub(string, "(.*[/\\])(.*)", "%2")
end

-- Define window title
function F.tab_title(tab_info)
  local title = tab_info.tab_title
  -- if the tab title is explicitly set, take that
  if title and #title > 0 then
    return title
  end
  -- Otherwise, use the title from the active pane in that tab
  title = tab_info.active_pane.title
  title = string.gsub(title, "^Copy mode: ", "" )
  return title
end

F.switch_workspace = function(window, pane, workspace)
  local current_workspace = window:active_workspace()
  if current_workspace == workspace then
    return
  end

  window:perform_action(
    action.SwitchToWorkspace({
      name = workspace,
    }),
    pane
  )
  wezterm.GLOBAL.previous_workspace = current_workspace
end

F.switch_previous_workspace = function(window, pane)
  local current_workspace = window:active_workspace()
  local workspace = wezterm.GLOBAL.previous_workspace

  if current_workspace == workspace or wezterm.GLOBAL.previous_workspace == nil then
    return
  end

  F.switch_workspace(window, pane, workspace)
end

-- Get value from gsettings
function F.gsettings(key)
  return wezterm.run_child_process({"gsettings", "get", "org.gnome.desktop.interface", key})
end

-- Define gsettings value to config
function F.gsettings_config(config)
  if not F.is_linux() then
    -- skip if not running on linux
    return
  end
  local success, stdout, stderr = F.gsettings("cursor-theme")
  if success then
    config.xcursor_theme = stdout:gsub("'(.+)'\n", "%1")
  end

  local success, stdout, stderr = F.gsettings("cursor-size")
  if success then
    config.xcursor_size = tonumber(stdout)
  end

  config.enable_wayland = true

  if config.enable_wayland and os.getenv("WAYLAND_DISPLAY") then
    local success, stdout, stderr = F.gsettings("text-scaling-factor")
    if success then
      config.font_size = (config.font_size or 10.0) * tonumber(stdout)
    end
  end

end

-- Create a flash on terminal
function F.flash_screen(window, pane, config, colors)
  local overrides = window:get_config_overrides() or {}
  local color_bg = colors.background
  local color_flash = colors.selection_bg

  if config.colors.background then
    color_bg = config.colors.background
  else
    color_bg = colors.background
  end

  -- Get current colors
  overrides.colors = config.colors

  -- Set new background
  overrides.colors.background = color_flash
  window:set_config_overrides(overrides)

  -- wait
  wezterm.sleep_ms(100)

  -- Reset background
  overrides.colors.background = color_bg
  window:set_config_overrides(overrides)

end

return F
