-- When in doubt, use :help <option> to read the documentation
-- ----------------------------------

-- Number settings
vim.opt.number         = true
vim.opt.relativenumber = true

-- Color Support
vim.opt.termguicolors  = true

-- Clipboard
vim.opt.clipboard = "unnamedplus"

-- Mouse
vim.opt.mouse          = "a"

-- Cursor
vim.opt.cursorline     = true

-- Indentation
vim.opt.breakindent    = true
vim.opt.expandtab      = true
vim.opt.shiftround     = true
vim.opt.shiftwidth     = 2
vim.opt.tabstop        = 2
vim.opt.smartindent    = true

-- Case
vim.opt.tagcase        = "smart"
vim.opt.ignorecase     = true
vim.opt.smartcase      = true

-- Other Text options
vim.opt.fileencoding   = "utf-8"
vim.opt.list           = true
vim.opt.linebreak      = true
vim.opt.wrap           = true

-- PopUp Menu
vim.opt.pumblend       = 10
vim.opt.pumheight      = 10

-- Command Line
vim.opt.cmdheight      = 0
vim.opt.showmode       = false

-- Splits
vim.opt.diffopt        = "vertical"
vim.opt.splitbelow     = true
vim.opt.splitkeep      = "screen"
vim.opt.splitright     = true

-- Undo History
vim.opt.undofile       = true

-- Minimal number of screen line sto keep above/below left/right of the cursor
vim.opt.scrolloff      = 8
vim.opt.sidescrolloff  = 8

-- Other Stuff
vim.o.formatoptions    = "jcroqlnt"
vim.o.shortmess        = "filnxtToOFWIcC"

vim.opt.completeopt    = "menuone,noselect,preview"
vim.opt.conceallevel   = 3
vim.opt.confirm        = true
vim.opt.hidden         = true
--
-- vim.opt.hlsearch       = false
vim.opt.inccommand     = "nosplit"
vim.opt.joinspaces     = false
vim.opt.laststatus     = 3
vim.opt.signcolumn     = "yes"
vim.opt.timeoutlen     = 300
vim.opt.updatetime     = 200
vim.opt.wildmode       = "longest:full,full"

vim.opt.pyxversion     = 3

vim.g.mapleader        = " "
vim.g.maplocalleader   = " "
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

vim.api.nvim_command("filetype plugin indent on")


-- Configure Diagnostic settings
vim.fn.sign_define("DiagnosticSignError", {text = "", texthl = "DiagnosticSignError"})
vim.fn.sign_define("DiagnosticSignWarn", {text = "", texthl = "DiagnosticSignWarn"})
vim.fn.sign_define("DiagnosticSignInfo", {text = "", texthl = "DiagnosticSignInfo"})
vim.fn.sign_define("DiagnosticSignHint", {text = "", texthl = "DiagnosticSignHint"})

vim.diagnostic.config({
  virtual_text = false,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = "rounded",
    source = 'always',
    header = ''
  }
})

vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
  callback = function()
    vim.diagnostic.open_float(nil, { focusable = false, scope = "cursor" })
  end
})
