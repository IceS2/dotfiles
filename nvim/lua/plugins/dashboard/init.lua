local dashboard_custom_header = {
"",
"",
"────────────────────────────────────────────────",
" ██████████  ██████████████  ████████  ████████ ",
" ██░░░░░░██  ██░░░░░░░░░░██  ██░░░░██  ██░░░░██ ",
" ████░░████  ██░░██████████  ████░░██  ██░░████ ",
"   ██░░██    ██░░██            ██░░░░██░░░░██   ",
"   ██░░██    ██░░██            ████░░░░░░████   ",
"   ██░░██    ██░░██              ████░░████     ",
"   ██░░██    ██░░██                ██░░██       ",
"   ██░░██    ██░░██                ██░░██       ",
" ████░░████  ██░░██████████        ██░░██       ",
" ██░░░░░░██  ██░░░░░░░░░░██        ██░░██       ",
" ██████████  ██████████████        ██████       ",
"────────────────────────────────────────────────",
"",
"",
}

local stats = require("lazy").stats()
local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)

local dashboard_custom_footer = {
    "",
    "────────────────────────────────────────────────",
    "Icy Loaded " .. stats.count .. " plugins in " .. ms .. "ms!  ",
    "Icy v0.1"
}


return {
  "glepnir/dashboard-nvim",
  dependencies = { {"nvim-tree/nvim-web-devicons"} },
  lazy = false,
  -- event = "VimEnter",
  config = function()
    require("dashboard").setup {
      theme = "doom",
      config = {
        header = dashboard_custom_header,
        center = {
          {
            icon = "  ",
            icon_h1 = "Title",
            desc = "Find File            ",
            desc_h1 = "String",
            key = "a",
            keymap = "SPC f f",
            key_h1 = "Number",
            action = "Telescope find_files find_command=rg,--follow,--hidden,--files"
          },
          {
            icon = "  ",
            icon_h1 = "Title",
            desc = "Recents",
            desc_h1 = "String",
            key = "b",
            keymap = "SPC f o",
            key_h1 = "Number",
            action = "Telescope oldfiles"
          },
          {
            icon = "  ",
            icon_h1 = "Title",
            desc = "Find Word",
            desc_h1 = "String",
            key = "c",
            keymap = "SPC f w",
            key_h1 = "Number",
            action = "Telescope live_grep"
          },
          {
            icon = "洛 ",
            icon_h1 = "Title",
            desc = "New File",
            desc_h1 = "String",
            key = "d",
            keymap = "SPC f n",
            key_h1 = "Number",
            action = "enew"
          },
          {
            icon = "  ",
            icon_h1 = "Title",
            desc = "Bookmarks",
            desc_h1 = "String",
            key = "e",
            keymap = "SPC b m",
            key_h1 = "Number",
            action = "Telescope marks"
          },
          {
            icon = "  ",
            icon_h1 = "Title",
            desc = "Open Project",
            desc_h1 = "String",
            key = "f",
            keymap = "SPC f p",
            key_h1 = "Number",
            action = "Telescope projects"
          },
        },
        footer = dashboard_custom_footer
      }
    }
  end
}
