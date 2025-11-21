local wezterm = require 'wezterm'
local action = wezterm.action
local nerdfonts = wezterm.nerdfonts
local mux = wezterm.mux

local F = require("functions")
local W = require("workspaces")

local colors = {}
local config = {}
local custom = {}

-- Custom
custom = {
  color_scheme = {
    dark = "Tokyo Night Moon",
    light = "Tokyo Night Day",
  },
  hostname = {
    current = string.lower(wezterm.hostname()),
    work = "mac",
  },
  timeout = {
    key = 3000,
    leader = 1000,
  },
  username = os.getenv("USER") or os.getenv("LOGNAME") or os.getenv("USERNAME"),
}

-- Launching
config.default_prog = { "/bin/zsh" }
config.automatically_reload_config = true

-- Clipboard
if F.is_linux() then
  if os.getenv("XDG_SESSION_TYPE") == "wayland" then
    custom.clipboard = { copy = "wl-copy -n" }
  elseif os.getenv("XDG_SESSION_TYPE") == "x11" then
    custom.clipboard = { copy = "xsel --clipboard" }
  end
elseif F.is_macos() then
  custom.clipboard = { copy = "pbcopy" }
end

-- Colorscheme
config.color_scheme = F.scheme_for_appearance(
  wezterm.gui.get_appearance(),
  custom.color_scheme.dark,
  custom.color_scheme.light
)

colors = wezterm.get_builtin_color_schemes()[config.color_scheme]

config.colors = {
  compose_cursor = colors.ansi[2],
  cursor_bg = colors.foreground,
  cursor_border = colors.foreground,
  split = colors.foreground,
  tab_bar = {
    background = colors.background,
    active_tab = {
      bg_color = colors.background,
      fg_color = colors.foreground,
      italic = true,
    }
  },
  visual_bell = colors.ansi[1]
}

-- Bell
config.visual_bell = {
  fade_in_function = "Constant",
  fade_in_duration_ms = 0,
  fade_out_function = "Constant",
  fade_out_duration_ms = 300,
  target = "CursorColor",
}

-- Pane
config.inactive_pane_hsb = {
  brightness = 0.6,
  hue = 1.0,
  saturation = 0.6
}

-- IME
config.use_ime = false

-- Keys Mapping
config.disable_default_key_bindings = true
config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = custom.timeout.leader }
config.keys = {
  { key = "o", mods = "LEADER",
    action = action.ActivateKeyTable {
      name = "open",
      one_shot = false,
      until_unknown = true,
      timeout_milliseconds = custom.timeout.key,
    }
  },
  { key = "m", mods = "LEADER",
    action = action.ActivateKeyTable {
      name = "move",
      one_shot = false,
      until_unknown = false,
      timeout_milliseconds = custom.timeout.key
    }
  },
  { key = "r", mods = "LEADER",
    action = action.ActivateKeyTable {
      name = "resize",
      one_shot = false,
      until_unknown = true,
      timeout_milliseconds = custom.timeout.key
    }
  },
  { key = "y", mods = "LEADER",
    action = action.ActivateKeyTable {
      name = "copy",
      one_shot = false,
      until_unknown = true,
      timeout_milliseconds = custom.timeout.key
    }
  },
  { key = "c", mods = "LEADER", action = action.ShowLauncherArgs { flags = "FUZZY|LAUNCH_MENU_ITEMS" } },
  { key = "d", mods = "LEADER", action = action.ShowDebugOverlay },
  { key = "h", mods = "LEADER", action = action.ActivateCommandPalette },
  { key = "l", mods = "CTRL|SHIFT", action = action.Multiple {
                                              action.ClearScrollback "ScrollbackOnly",
                                              action.EmitEvent "flash-terminal"
                                              }
  },
  { key = "l", mods = "LEADER", action = action.Multiple {
                                          wezterm.action_callback(function(window,pane)
                                            F.switch_previous_workspace(window,pane)
                                          end),
                                          action.EmitEvent "set-previous-workspace"
                                          }
  },
  { key = "p", mods = "CTRL", action = action.PasteFrom("Clipboard") },
  { key = "q", mods = "LEADER", action = action.QuitApplication },
  { key = "s", mods = "LEADER", action = action.Multiple {
                                          action.ShowLauncherArgs { flags = "FUZZY|WORKSPACES" },
                                          action.EmitEvent "set-previous-workspace"
                                          }
  },
  { key = "t", mods = "CTRL", action = action.SpawnTab("DefaultDomain") },
  { key = "t", mods = "LEADER", action = action.ShowLauncherArgs { flags = "TABS" } },
  { key = "v", mods = "LEADER", action = action.ActivateCopyMode },
  { key = "w", mods = "LEADER", action = action.CloseCurrentPane { confirm = true } },
  { key = "y", mods = "CTRL", action = action.Multiple {
                                          action.CopyTo("ClipboardAndPrimarySelection"),
                                          action.ClearSelection
                                          }
  },
  { key = "z", mods = "LEADER", action = action.TogglePaneZoomState },
  { key = "DownArrow", mods = "ALT", action = action.ActivatePaneDirection("Down") },
  { key = "DownArrow", mods = "SHIFT", action = action.ScrollByLine(1) },
  { key = "End", mods = "SHIFT", action = action.ScrollToBottom },
  { key = "Home", mods = "SHIFT", action = action.ScrollToTop },
  { key = "LeftArrow", mods = "ALT", action = action.ActivatePaneDirection("Left") },
  { key = "PageDown", mods = "SHIFT", action = action.ScrollByPage(1) },
  { key = "PageUp", mods = "SHIFT", action = action.ScrollByPage(-1) },
  { key = "RightArrow", mods = "ALT", action = action.ActivatePaneDirection("Right") },
  { key = "UpArrow", mods = "ALT", action = action.ActivatePaneDirection("Up") },
  { key = "UpArrow", mods = "SHIFT", action = action.ScrollByLine(-1) },
  { key = "0", mods = "ALT", action = action.EmitEvent "toggle-opacity-reset" },
  { key = "0", mods = "CTRL", action = action.ResetFontSize },
  { key = "-", mods = "ALT", action = action.EmitEvent "toggle-opacity-minus" },
  { key = "-", mods = "CTRL", action = action.DecreaseFontSize },
  { key = "=", mods = "ALT", action = action.EmitEvent "toggle-opacity-plus" },
  { key = "=", mods = "CTRL", action = action.IncreaseFontSize },
  { key = "[", mods = "ALT", action = action.ActivateTabRelative(-1) },
  { key = "[", mods = "ALT|CTRL", action = action.Multiple {
                                          action.SwitchWorkspaceRelative(-1),
                                          action.EmitEvent "set-previous-workspace"
                                          }
  },
  { key = "]", mods = "ALT", action = action.ActivateTabRelative(1) },
  { key = "]", mods = "ALT|CTRL", action = action.Multiple {
                                          action.SwitchWorkspaceRelative(1),
                                          action.EmitEvent "set-previous-workspace"
                                          }
  },
  { key = "/", mods = "LEADER", action = action.Search { CaseInSensitiveString = "" } },
  { key = "-", mods = "LEADER", action = action.SplitVertical { domain = "CurrentPaneDomain" } },
  { key = "|", mods = "LEADER|SHIFT", action = action.SplitHorizontal { domain = "CurrentPaneDomain" } },
  { key = ",", mods = "LEADER", action = action.PromptInputLine
      {
         description = wezterm.format {
            { Attribute = { Intensity = "Bold"} },
            { Foreground = { Color = colors.foreground }},
            { Text = "Renaming tab title:" }},
          action = wezterm.action_callback(function(window, _, line)
            if line then
              window:active_tab():set_title(line)
            end
          end),
      }
  },
  { key = "$", mods = "LEADER|SHIFT", action = action.PromptInputLine
      {
         description = wezterm.format {
            { Attribute = { Intensity = "Bold"} },
            { Foreground = { Color = colors.foreground }},
            { Text = "Renaming session/workspace:" }},
          action = wezterm.action_callback(function(window, _, line)
            if line then
              mux.rename_workspace(mux.get_active_workspace(), line)
            end
          end),
      }
  },

  -- Mac OS Specifics
  {
    key = "c",
    mods = "CMD",
    action = wezterm.action.CopyTo("Clipboard"),
  },
  {
    key = "v",
    mods = "CMD",
    action = wezterm.action.PasteFrom("Clipboard"),
  },
  -- { key = "LeftArrow",  mods = "ALT",  action = wezterm.action.SendString("\x1bb") },
  -- { key = "RightArrow", mods = "ALT",  action = wezterm.action.SendString("\x1bf") },
}

-- Active tab by index
for i = 1, 9 do
  table.insert(config.keys, { key = tostring(i), mods = "ALT", action = action.ActivateTab(i-1) })
end

config.key_tables = {
  copy = {
    { key = "b", action = action.EmitEvent "copy-buffer-from-pane" },
    { key = "l", action = action.QuickSelectArgs {
                            label = "COPY LINE",
                            patterns = { "^.*\\S+.*$" },
                            scope_lines = 1,
                            action = action.Multiple {
                              action.CopyTo("ClipboardAndPrimarySelection"),
                              action.ClearSelection
                            }
                          }
    },
    { key = "p", action = action.EmitEvent "copy-text-from-pane" },
    { key = "r", action = action.QuickSelectArgs {
                            label = "COPY REGEX",
                            patterns = {
                              "(\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}(?:/\\d{1,2})?)", -- ipv4
                              "((?:[[:xdigit:]]{0,4}:){2,7}[[:xdigit:]]{0,4}(?:/\\d{1,3})?)", -- ipv6
                              "[[:xdigit:]]{2}:[[:xdigit:]]{2}:[[:xdigit:]]{2}:[[:xdigit:]]{2}:[[:xdigit:]]{2}:[[:xdigit:]]{2}", -- mac address
                              "\\S+@\\S+\\.\\S+", -- e-mail
                              "[[:xdigit:]]{12}", -- container id
                              "\\S+/\\S+:\\S+", -- container image name
                              "(br(?:-[[:xdigit:]]{12}|\\d)|eth\\d|en[opsx]\\ds\\d|wlp\\ds\\d\\w+|virbr\\d)", -- interface
                              "(?:https?|s?ftp)://\\S+" -- url
                            },
                            action = action.Multiple {
                              action.CopyTo("ClipboardAndPrimarySelection"),
                              action.ClearSelection
                            }
                          }
    },
  },

  move = {
    { key = "r", action = action.RotatePanes 'CounterClockwise' },
    { key = "s", action = action.PaneSelect },
    { key = "Enter", action = "PopKeyTable" },
    { key = "Escape", action = "PopKeyTable" },
    { key = "LeftArrow", mods = "SHIFT", action = action.MoveTabRelative(-1) },
    { key = "RightArrow", mods = "SHIFT", action = action.MoveTabRelative(1) },
  },

  resize = {
    { key = "DownArrow",  action = action.AdjustPaneSize { "Down",  1 } },
    { key = "LeftArrow",  action = action.AdjustPaneSize { "Left",  1 } },
    { key = "RightArrow", action = action.AdjustPaneSize { "Right", 1 } },
    { key = "UpArrow",    action = action.AdjustPaneSize { "Up",    1 } },
    { key = "Enter",      action = "PopKeyTable"                        },
    { key = "Escape",     action = "PopKeyTable"                        },
  },

  open = {
    { key = "p", action = action.SpawnCommandInNewWindow {
          label = "open CURRENT PATH on FILE MANAGER",
          args = F.is_macos() and { "open", "." } or { "xdg-open", "." },
      }
    },
    { key = "u", action = action {
        QuickSelectArgs = {
          label = "open URL on BROWSER",
          patterns = { "https?://\\S+" },
          scope_lines = 30,
          action = wezterm.action_callback(function(window, pane)
            local url = window:get_selection_text_for_pane(pane)
            wezterm.log_info("opening: " .. url)
            wezterm.open_with(url)
          end)
        }
      },
    },
  }
}

-- Window
config.bold_brightens_ansi_colors = true
config.initial_cols = 200
config.initial_rows = 50
config.foreground_text_hsb = {
  brightness = 1.0,
  hue = 1.0,
  saturation = 1.0,
}
-- config.text_background_opacity = 0.9
config.window_background_opacity = 0.9
config.window_decorations = "RESIZE"
config.window_padding = {
  left = 3,
  right = 3,
  top = 10,
  bottom = 3,
}

if F.is_macos() then
  config.macos_window_background_blur = 20
  config.send_composed_key_when_left_alt_is_pressed = false
  config.send_composed_key_when_right_alt_is_pressed = false
end

-- Graphics
if F.is_macos() then
  config.front_end = "OpenGL"
else
  config.front_end = "WebGpu"
end

config.animation_fps = 30
config.max_fps = 120
config.webgpu_power_preference = "HighPerformance"

-- Cursor
F.gsettings_config(config)
config.bypass_mouse_reporting_modifiers = "SHIFT"
config.cursor_blink_ease_in = "Linear"
config.cursor_blink_rate = 500
config.default_cursor_style = "BlinkingBlock"
config.force_reverse_video_cursor = false
config.hide_mouse_cursor_when_typing = false

-- Mouse
config.mouse_bindings = {
  { event = { Down = { streak = 1, button = "Middle" }}, mods = "NONE", action = action.PasteFrom("Clipboard") },
  { event = { Down = { streak = 1, button = "Left"   }}, mods = "NONE", action = action.Multiple { action.ClearSelection }},
  { event = { Up   = { streak = 1, button = "Left"   }}, mods = "NONE", action = action.Nop },
  { event = { Up   = { streak = 2, button = "Left"   }}, mods = "NONE", action = action.Multiple { action.CopyTo "ClipboardAndPrimarySelection", action.ClearSelection }},
  { event = { Up   = { streak = 3, button = "Left"   }}, mods = "NONE", action = action.Multiple { action.CopyTo "ClipboardAndPrimarySelection", action.ClearSelection }},
  { event = { Up   = { streak = 1, button = "Left"   }}, mods = "CTRL", action = action.OpenLinkAtMouseCursor  },
}

-- Font
config.font = wezterm.font("Cascadia Code", { weight = "Medium" })
config.font_size = 14
config.freetype_load_target = 'Normal'
config.freetype_render_target = 'HorizontalLcd'

-- Nerd Font symbols fallback
config.font_rules = {
  {
    intensity = 'Bold',
    italic = false,
    font = wezterm.font('Cascadia Code', { weight = 'Bold' }),
  },
  {
    italic = true,
    intensity = 'Normal',
    font = wezterm.font('Cascadia Code', { weight = 'Medium', italic = true }),
  },
  {
    italic = true,
    intensity = 'Bold',
    font = wezterm.font('Cascadia Code', { weight = 'Bold', italic = true }),
  },
}

-- Hyperlink
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- Scrolling
config.enable_scroll_bar = false
config.scrollback_lines = 100000
config.alternate_buffer_wheel_scroll_speed = 5

-- Tab
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.show_new_tab_button_in_tab_bar = false
config.show_tab_index_in_tab_bar = true
config.status_update_interval = 1000
config.tab_bar_at_bottom = false
config.tab_max_width = 35
config.use_fancy_tab_bar = false

-- Launch Commands
-- TODO

-- Events update status
wezterm.on("update-status", function(window, pane)

  -- Workspace name
  local active_key_table = window:active_key_table()
  local stat = window:active_workspace()
  local workspace_color = colors.ansi[3]
  local time = wezterm.strftime("%Y-%m-%d %H:%M")

  if active_key_table then
    stat = active_key_table
    workspace_color = colors.ansi[4]
  elseif window:leader_is_active() then
    stat = "leader"
    workspace_color = colors.ansi[2]
  end

  -- Current working directory
  local cwd = pane:get_current_working_dir()
  if cwd then
    if type(cwd) == "userdata" then
      -- Wezterm introduced the URL object in 20240127-113634-bbcac864
      if string.len(cwd.path) > config.tab_max_width then
        cwd = ".." .. string.sub(cwd.path, config.tab_max_width * -1, -1)
      else
        cwd = cwd.path
      end
    end
  else
    cwd = ""
  end

  -- Left status (left of the tab line)
  window:set_left_status(wezterm.format({
    { Attribute  = { Intensity = "Bold" }                       },
    { Background = { Color = colors.background }                },
    { Text       = " "                                          },
    { Background = { Color = colors.background }                },
    { Foreground = { Color = workspace_color }                  },
    { Text       = nerdfonts.ple_left_half_circle_thick         },
    { Background = { Color = workspace_color }                  },
    { Foreground = { Color = colors.ansi[1] }                   },
    { Text       = nerdfonts.cod_terminal_tmux .. " "           },
    { Background = { Color = colors.ansi[1] }                   },
    { Foreground = { Color = workspace_color }                  },
    { Text       = " " .. stat .. " "                           },
    { Background = { Color = colors.background }                },
    { Foreground = { Color = colors.ansi[1] }                   },
    { Text       = nerdfonts.ple_right_half_circle_thick .. " " },
  }))

  -- Right status
  window:set_right_status(wezterm.format({
    -- Wezterm has a built-in nerd fonts
    -- https://wezfurlong.org/wezterm/config/lua/wezterm/nerdfonts.html
    --
    { Text       = " "                                   },
    { Background = { Color = colors.background }         },
    { Foreground = { Color = colors.ansi[4] }            },
    { Text       = nerdfonts.ple_left_half_circle_thick  },
    { Background = { Color = colors.ansi[4] }            },
    { Foreground = { Color = colors.background }         },
    { Text       = nerdfonts.md_folder .. " "            },
    { Background = { Color = colors.ansi[1] }            },
    { Foreground = { Color = colors.foreground }         },
    { Text       = " " .. cwd                            },
    { Background = { Color = colors.background }         },
    { Foreground = { Color = colors.ansi[1] }            },
    { Text       = nerdfonts.ple_right_half_circle_thick },

    { Text       = " "                                   },
    { Background = { Color = colors.background }         },
    { Foreground = { Color = colors.ansi[6] }            },
    { Text       = nerdfonts.ple_left_half_circle_thick  },
    { Background = { Color = colors.ansi[6] }            },
    { Foreground = { Color = colors.background }         },
    { Text       = nerdfonts.fa_user .. " "              },
    { Background = { Color = colors.ansi[1] }            },
    { Foreground = { Color = colors.foreground }         },
    { Text       = " " .. custom.username                },
    { Background = { Color = colors.background }         },
    { Foreground = { Color = colors.ansi[1] }            },
    { Text       = nerdfonts.ple_right_half_circle_thick },

    { Text       = " "                                   },
    { Background = { Color = colors.background }         },
    { Foreground = { Color = colors.ansi[7] }            },
    { Text       = nerdfonts.ple_left_half_circle_thick  },
    { Background = { Color = colors.ansi[7] }            },
    { Foreground = { Color = colors.ansi[1] }            },
    { Text       = nerdfonts.cod_server .. " "           },
    { Background = { Color = colors.ansi[1] }            },
    { Foreground = { Color = colors.foreground }         },
    { Text       = " " .. custom.hostname.current        },
    { Background = { Color = colors.background }         },
    { Foreground = { Color = colors.ansi[1] }            },
    { Text       = nerdfonts.ple_right_half_circle_thick },

    { Text       = " "                                   },
    { Background = { Color = colors.background }         },
    { Foreground = { Color = colors.ansi[8]}             },
    { Text       = nerdfonts.ple_left_half_circle_thick  },
    { Background = { Color = colors.ansi[8]}             },
    { Foreground = { Color = colors.background }         },
    { Text       = nerdfonts.md_calendar_clock .. " "    },
    { Background = { Color = colors.ansi[1] }            },
    { Foreground = { Color = colors.foreground }         },
    { Text       = " " .. time                           },
    { Background = { Color = colors.background }         },
    { Foreground = { Color = colors.ansi[1] }            },
    { Text       = nerdfonts.ple_right_half_circle_thick },

  }))

end)

-- Events define tab title
wezterm.on("format-tab-title", function(tab, panes)

    local command_args = nil
    local command = nil
    local pane = tab.active_pane
    local title = F.tab_title(tab)
    local tab_number = tostring(tab.tab_index + 1)
    local program = pane.user_vars.WEZTERM_PROG

    -- Filter command name
    if not program or program ~= "" then
      command_args = program
      if command_args then
        command = string.match(command_args, "^%S+")
      end
    end

    -- Shrink title if too long
    if string.len(title) > config.tab_max_width - 3 then
      title  = string.sub(title, 1, config.tab_max_width - 12) .. ".. "
    end

    -- Add terminal icon
    -- if tab.is_active then
    --   title = nerdfonts.dev_terminal .. " " .. title
    -- end

    -- Add zoom icon
    if pane.is_zoomed then
      title = nerdfonts.cod_zoom_in .. " " .. title
    end

    -- Add copy icon
    if string.match(pane.title,"^Copy mode:") then
      title = nerdfonts.md_content_copy .. " " .. title
    end

    -- Add icon to command
    if command then

      -- Add docker icon
      if command == "docker" or command == "podman" then
        title = nerdfonts.linux_docker .. " " .. title
      end

      -- Add kubernetes icon
      if command == "kind" or command == "kubectl" then
        title = nerdfonts.md_kuberntes .. " " .. title
      end

      -- Add ssh icon
      if command == "ssh" then
        title = nerdfonts.md_remote_desktop .. " " .. title
      end

      -- Add monitoring icon
      if string.match(command,"^([bh]?)top") then
        title = nerdfonts.md_monitor_eye .. " " .. title
      end

      -- Add vim icon
      if string.match(command,"^(n?)vi(m?)") then
        title = nerdfonts.dev_vim .. " " .. title
      end

      -- Add watch icon
      if command == "watch" then
        title = nerdfonts.md_eye_outline .. " " .. title
      end

    end

    -- Add bell icon
    -- on inactive panes if something shows up
    local has_unseen_output = false
    if not tab.is_active then

      for _, pane in ipairs(tab.panes) do
        if pane.has_unseen_output then
          has_unseen_output = true
          break
        end
      end

    end

    -- Add bell icon
    if has_unseen_output then
      title = nerdfonts.md_bell_ring_outline .. " " .. title
    end

    if tab.is_active then
      return {
        { Background = { Color = colors.background }                },
        { Foreground = { Color = colors.ansi[6]    }                },
        { Text       = nerdfonts.ple_left_half_circle_thick         },
        { Background = { Color = colors.ansi[6] }                },
        { Foreground = { Color = colors.background}                },
        { Text       = title .. " "                                 },
        { Background = { Color = colors.ansi[6]}                },
        { Foreground = { Color = colors.background }                },
        { Text       = " " .. tab_number                            },
        { Background = { Color = colors.background }                },
        { Foreground = { Color = colors.ansi[6]}                },
        { Text       = nerdfonts.ple_right_half_circle_thick .. " " },
      }
    else
      return {
        { Background = { Color = colors.background }                },
        { Foreground = { Color = colors.ansi[1]    }                },
        { Text       = nerdfonts.ple_left_half_circle_thick         },
        { Background = { Color = colors.ansi[1]    }                },
        { Foreground = { Color = colors.foreground }                },
        { Text       = title .. " "                                 },
        { Background = { Color = colors.ansi[5]    }                },
        { Foreground = { Color = colors.background }                },
        { Text       = " " .. tab_number                            },
        { Background = { Color = colors.background }                },
        { Foreground = { Color = colors.ansi[5]    }                },
        { Text       = nerdfonts.ple_right_half_circle_thick .. " " },
      }
    end

end)


local function spawn_project_windows(projects, project_type)
  local project = projects[project_type]

  for _, repo in ipairs(project.repositories) do
      local _, _, w = mux.spawn_window {
        workspace = repo.workspace,
        cwd = repo.tabs[1].path
      }
      w:active_tab():set_title(repo.tabs[1].name)
      wezterm.log_info("Created workspace " .. repo.workspace)

    for i, tab_info in ipairs(repo.tabs) do
      if i ~= 1 then
        local tab = w:spawn_tab { cwd = tab_info.path, workspace = repo.workspace }
        tab:set_title(tab_info.name)
      end
    end
  end
  mux.set_active_workspace(project.default)
end

-- Events when wezterm is started
wezterm.on("gui-startup", function(cmd)
    local workspace_type = "default"

    if cmd and cmd.args then
      for i, arg in ipairs(cmd.args) do
        if arg == "--workspace-type" and cmd.args[i+1] then
          workspace_type = cmd.args[i+1]
        end
      end
    end

    spawn_project_windows(W.workspaces.projects, workspace_type)
end)

wezterm.on("toggle-cursor-bg", function(window, pane, stat)
  local overrides = window:get_config_overrides() or {}
  overrides.colors = config.colors

  if window:active_key_table() then
    overrides.colors.cursor_bg = colors.ansi[4]
  else
    overrides.colors.cursor_bg = colors.indexed[16]
  end

  window:set_config_overrides(overrides)

end)

wezterm.on("toggle-opacity-minus", function(window, pane)
  local overrides = window:get_config_overrides() or {}

  if not overrides.text_background_opacity or not overrides.window_background_opacity then
    overrides.text_background_opacity   = config.text_background_opacity
    overrides.window_background_opacity = config.window_background_opacity
  end

  if overrides.window_background_opacity >= 0.01 and overrides.window_background_opacity <= 1 then
    overrides.text_background_opacity   = overrides.text_background_opacity   - 0.1
    overrides.window_background_opacity = overrides.window_background_opacity - 0.1
    window:set_config_overrides(overrides)
  end

end)

wezterm.on("toggle-opacity-plus", function(window, pane)
  local overrides = window:get_config_overrides() or {}

  if overrides then
    overrides.text_background_opacity   = tonumber(string.format("%.2f",overrides.text_background_opacity))
    overrides.window_background_opacity = tonumber(string.format("%.2f",overrides.window_background_opacity))
  else
    overrides.text_background_opacity   = config.text_background_opacity
    overrides.window_background_opacity = config.window_background_opacity
  end

  if overrides.window_background_opacity >= 0 and overrides.window_background_opacity < 1 then
    overrides.text_background_opacity   = overrides.text_background_opacity   + 0.1
    overrides.window_background_opacity = overrides.window_background_opacity + 0.1
    window:set_config_overrides(overrides)
  end

end)

wezterm.on("toggle-opacity-reset", function(window, pane)
  local overrides = window:get_config_overrides() or {}

  overrides.text_background_opacity   = config.text_background_opacity
  overrides.window_background_opacity = config.window_background_opacity
  window:set_config_overrides(overrides)

end)

wezterm.on("set-previous-workspace", function(window, pane)
  local current_workspace = window:active_workspace()

  if wezterm.GLOBAL.previous_workspace ~= current_workspace then
    wezterm.GLOBAL.previous_workspace = current_workspace
  end

end)

wezterm.on("copy-buffer-from-pane", function(window, pane)
  -- Copy the entire scrollback text
  local text = pane:get_lines_as_text(pane:get_dimensions().scrollback_rows)
  window:copy_to_clipboard(text)

  -- Flash screen
  F.flash_screen(window, pane, config, colors)

end)

wezterm.on("copy-text-from-pane", function(window, pane)
  -- Copy the visable text on pane
  local text = pane:get_lines_as_text(pane:get_dimensions().viewport_rows)
  window:copy_to_clipboard(text)

  -- Flash screen
  F.flash_screen(window, pane, config, colors)

end)

wezterm.on("flash-terminal", function(window, pane)
  -- Flash screen
  F.flash_screen(window, pane, config, colors)

end)

wezterm.on('window-focus-changed', function(window, pane)
  -- Change window's brightness and saturation to active window
  local overrides = window:get_config_overrides() or {}

  if window:is_focused() then
    overrides.foreground_text_hsb = config.foreground_text_hsb
    overrides.inactive_pane_hsb   = config.inactive_pane_hsb
  else
    overrides.foreground_text_hsb = config.inactive_pane_hsb
    overrides.inactive_pane_hsb   = config.foreground_text_hsb
  end

  window:set_config_overrides(overrides)

end)

config.debug_key_events = true

return config
