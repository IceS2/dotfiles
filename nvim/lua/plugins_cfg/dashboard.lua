local g = vim.g
local fn = vim.fn

if vim.fn.has("win32") == 1 then
  plugins_count = fn.len(fn.globpath("~/AppData/Local/nvim-data/site/pack/packer/start", "*", 0, 1))
else
  plugins_count = fn.len(fn.globpath("~/.local/share/nvim/site/pack/paqs/start", "*", 0, 1))
end

vim.cmd[[au VimEnter * highlight dashboardHeader ctermfg=147 guifg=#afafff]]
vim.cmd[[au VimEnter * highlight dashboardFooter ctermfg=147 guifg=#afafff]]
vim.cmd[[au VimEnter * highlight dashboardCenter ctermfg=147 guifg=#af87ff]]
vim.cmd[[au VimEnter * highlight dashboardShortCut ctermfg=147 guifg=#ffffaf]]

dashboard_custom_header = {
"8888888888                           888             ",
"888                                  888             ",
"888                                  888             ",
"8888888    888d888  .d88b.  .d8888b  888888 888  888 ",
"888        888P\"   d88\"\"88b 88K      888    888  888 ",
"888        888     888  888 \"Y8888b. 888    888  888 ",
"888        888     Y88..88P      X88 Y88b.  Y88b 888 ",
"888        888      \"Y88P\"   88888P'  \"Y888  \"Y88888 ",
"                                                 888 ",
"                                            Y8b d88P ",
"                                             \"Y88P\"  "
}

dashboard_custom_footer = {
    "Frosty Loaded " .. plugins_count .. " plugins!  ",
    "Frosty v0.1"
}


require('dashboard').setup {
  theme = 'doom',
  config = {
    header = dashboard_custom_header,
    center = {
      {
        icon = '  ',
        icon_h1 = 'Title',
        desc = 'Find File',
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
