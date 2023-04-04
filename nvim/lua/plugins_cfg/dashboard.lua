local vim = vim

local plugins_count

if vim.fn.has("win32") == 1 then
  plugins_count = vim.fn.len(vim.fn.globpath("~/AppData/Local/nvim-data/site/pack/packer/start", "*", 0, 1))
else
  plugins_count = vim.fn.len(vim.fn.globpath("~/.local/share/nvim/site/pack/paqs/start", "*", 0, 1))
end

vim.cmd[[au VimEnter * highlight DashboardHeader ctermfg=147 guifg=#9388FF]]
vim.cmd[[au VimEnter * highlight DashboardFooter ctermfg=147 guifg=#9388FF]]
vim.cmd[[au VimEnter * highlight DashboardDesc ctermfg=147 guifg=#AFAFFF]]
vim.cmd[[au VimEnter * highlight DashboardKey ctermfg=147 guifg=#AFAFFF]]
vim.cmd[[au VimEnter * highlight DashboardIcon ctermfg=147 guifg=#9B70FF]]
vim.cmd[[au VimEnter * highlight DashboardShortCut ctermfg=147 guifg=#FFFFAF]]


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

local dashboard_custom_footer = {
    "",
    "────────────────────────────────────────────────",
    "Icy Loaded " .. plugins_count .. " plugins!  ",
    "Icy v0.1"
}


require('dashboard').setup {
  theme = 'doom',
  config = {
    header = dashboard_custom_header,
    center = {
      {
        icon = '  ',
        icon_h1 = 'Title',
        desc = 'Find File            ',
        desc_h1 = 'String',
        key = 'a',
        keymap = 'SPC f f',
        key_h1 = 'Number',
        action = 'Telescope find_files find_command=rg,--follow,--hidden,--files'
      },
      {
        icon = '  ',
        icon_h1 = 'Title',
        desc = 'Recents',
        desc_h1 = 'String',
        key = 'b',
        keymap = 'SPC f o',
        key_h1 = 'Number',
        action = 'Telescope oldfiles'
      },
      {
        icon = '  ',
        icon_h1 = 'Title',
        desc = 'Find Word',
        desc_h1 = 'String',
        key = 'c',
        keymap = 'SPC f w',
        key_h1 = 'Number',
        action = 'Telescope live_grep'
      },
      {
        icon = '洛 ',
        icon_h1 = 'Title',
        desc = 'New File',
        desc_h1 = 'String',
        key = 'd',
        keymap = 'SPC f n',
        key_h1 = 'Number',
        action = 'enew'
      },
      {
        icon = '  ',
        icon_h1 = 'Title',
        desc = 'Bookmarks',
        desc_h1 = 'String',
        key = 'e',
        keymap = 'SPC b m',
        key_h1 = 'Number',
        action = 'Telescope marks'
      },
      {
        icon = '  ',
        icon_h1 = 'Title',
        desc = 'Open Project',
        desc_h1 = 'String',
        key = 'f',
        keymap = 'SPC f p',
        key_h1 = 'Number',
        action = 'Telescope projects'
      },
    },
    footer = dashboard_custom_footer
  }
}
