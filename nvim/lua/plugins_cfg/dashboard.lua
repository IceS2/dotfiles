local g = vim.g
local fn = vim.fn

if vim.fn.has("win32") == 1 then
  plugins_count = fn.len(fn.globpath("~/AppData/Local/nvim-data/site/pack/packer/start", "*", 0, 1))
else
  plugins_count = fn.len(fn.globpath("~/.local/share/nvim/site/pack/paqs/start", "*", 0, 1))
end

g.dashboard_disable_statusline = 1
g.dashboard_default_executive = "telescope"
vim.cmd[[au VimEnter * highlight dashboardHeader ctermfg=147 guifg=#afafff]]
vim.cmd[[au VimEnter * highlight dashboardFooter ctermfg=147 guifg=#afafff]]
vim.cmd[[au VimEnter * highlight dashboardCenter ctermfg=147 guifg=#af87ff]]
vim.cmd[[au VimEnter * highlight dashboardShortCut ctermfg=147 guifg=#ffffaf]]

g.dashboard_custom_header = {
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

g.dashboard_custom_section = {
    a = { description = { "  Find File                 SPC f f" }, command = "Telescope find_files find_command=rg,--follow,--hidden,--files" },
    b = { description = { "  Recents                   SPC f o" }, command = "Telescope oldfiles" },
    c = { description = { "  Find Word                 SPC f w" }, command = "Telescope live_grep" },
    d = { description = { "洛 New File                  SPC f n" }, command = "DashboardNewFile" },
    e = { description = { "  Bookmarks                 SPC b m" }, command = "Telescope marks" },
    f = { description = { "  Open Project              SPC f p" }, command = "Telescope projects" },
    g = { description = { "  Load Last Session         SPC s l" }, command = "SessionLoad" }
}

g.dashboard_custom_footer = {
    "Frosty Loaded " .. plugins_count .. " plugins!  ",
    "Frosty v0.1"
}

-- Disable statusline and cursorline in dashboard.
vim.cmd("autocmd BufEnter * if &ft is \"dashboard\" | set laststatus=0 | else | set laststatus=2 | endif")
vim.cmd("autocmd BufEnter * if &ft is \"dashboard\" | set nocursorline | endif")


