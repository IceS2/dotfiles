-- Leader Key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Text
vim.opt.fileencoding   = "utf-8"

-- Line Numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Indentation
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- UI
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.showmode = false
vim.opt.pumheight = 10

-- Splits
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Misc
vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = "a"
vim.opt.undofile = true
vim.opt.scrolloff = 20
vim.opt.updatetime = 200
vim.opt.timeoutlen = 300

-- Line Wrapping
vim.opt.wrap = true
vim.opt.breakindent = true
vim.opt.linebreak = true

-- Invisible Characters
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Live Substitution Preview
vim.opt.inccommand = "split"

-- Prompt Instead of error on unsaved
vim.opt.confirm = true

-- Cleaner UI
vim.opt.fillchars = { eob = " " }

-- Scroll
vim.opt.smoothscroll = true

-- StatusLine
vim.opt.laststatus = 3

-- Diagnostics
vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.HINT] = "",
      [vim.diagnostic.severity.INFO] = "",
    }
  },
  virtual_text = false,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = "single",
    source = true,
    header = "",
    prefix = "",
    max_width = 80,
    max_height = 20,
  },
})

vim.api.nvim_create_autocmd("CursorHold", {
  group = vim.api.nvim_create_augroup("DiagnosticFloat", { clear = true }),
  callback = function()
    vim.diagnostic.open_float(nil, { focus = false, scope = "cursor" })
  end,
})

-- Folding (nvim-ufo)
vim.opt.foldcolumn = "1"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true

-- Highlight on Yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("HighlightYank", { clear = true }),
  callback = function()
    vim.hl.on_yank({ timeout = 200 })
  end,
})

vim.filetype.add({
  extension = {
    mdx = "mdx",
  },
})
