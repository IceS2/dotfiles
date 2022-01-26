local opt = vim.opt

-- When in doubt, use :help <option> to read the documentation
-- ----------------------------------
-- Number settings
opt.number = true
opt.relativenumber = true

-- Color Support
opt.termguicolors = true

-- Clipboard
opt.clipboard = "unnamedplus"

-- Mouse
opt.mouse = "a"

-- Cursor
opt.cursorline = true

-- Indentation
opt.breakindent = true
opt.smartindent = true
opt.expandtab = true
opt.shiftwidth = 2

-- Case
opt.tagcase = "smart"
opt.ignorecase = true
opt.smartcase = true

-- Ruler
opt.colorcolumn = "80"

-- Other Text Options
opt.fileencoding = "utf-8"
opt.wrap = true
opt.linebreak = true
opt.list = true

-- Etc
opt.showmode = false
opt.gdefault = true
opt.lazyredraw = true
opt.diffopt = "vertical"

opt.pyxversion = 3

-- vim.cmd[[highlight Normal ctermbg=none]]
vim.cmd[[filetype plugin indent on]]
