local function map(mode, lhs, rhs, opts)
  local options = {noremap = true}
  if opts then options = vim.tbl_extend("force", options, opts) end
  vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end


-- Mapping leader key
vim.g.mapleader = " "

-- Terminal
map('n', "<leader>ftn", ":FloatermNew --height=0.8 --width=0.7 --autoclose=2 --name=")
map('n', "t", ":FloatermToggle<CR>")
map('t', "<Esc>", "<C-\\><C-n>:q<CR>")
map('n', "<F2>", ":FloatermPrev<CR>")
map('t', "<F2>", "<C-\\><C-n>:FloatermPrev<CR>")
map('n', "<F3>", ":FloatermNext<CR>")
map('t', "<F3>", "<C-\\><C-n>:FloatermNext<CR>")

-- Clear highlights after searching
map("n", "cl", ":noh<CR>")

-- Split navigations.
map("n", "<A-j>", "<C-w><C-j>")
map("n", "<A-k>", "<C-w><C-k>")
map("n", "<A-l>", "<C-w><C-l>")
map("n", "<A-h>", "<C-w><C-h>")

-- Buffer resizing
map("n", "<S-h>", ":call ResizeLeft(3)<CR><Esc>")
map("n", "<S-l>", ":call ResizeRight(3)<CR><Esc>")
map("n", "<S-k>", ":call ResizeUp(1)<CR><Esc>")
map("n", "<S-j>", ":call ResizeDown(1)<CR><Esc>")

-- NvimTree toggle
map("n", "<leader>nt", ":NvimTreeToggle<CR>")

-- Telescope
---- Files
map("n", "<leader>ff", ":Telescope find_files find_command=rg,--follow,--hidden,--files<CR>")
map("n", "<leader>fw", ":Telescope live_grep<CR>")
map("n", "<leader>fo", ":Telescope oldfiles<CR>")
---- Projects
map("n", "<leader>fp", ":Telescope projects<CR>")
---- Git
map("n", "<leader>gs", ":Telescope git_status<CR>")
map("n", "<leader>gb", ":Telescope git_branches<CR>")
map("n", "<leader>gc", ":Telescope git_commits<CR>")
---- Buffers
map("n", "<leader>fb", ":Telescope buffers<CR>")
---- Clipboard
map("n", "<leader>sn", ":Telescope neoclip ")
---- todo comments
map("n", "<leader>ft", ":TodoTelescope<CR>")
---- Aerial
map("n", "<leader>fa", ":Telescope aerial<CR>")
---- Color Scheme
map("n", "<leader>th", ":Telescope colorscheme<CR>")

-- Dashboard
map("n", "<leader>db", ":Dashboard<CR>")

--Lsp
local lsp_opts = { noremap=true, silent=true }
map("n", "gD", ":lua vim.lsp.buf.declaration()<CR>", lsp_opts)
map("n", "gd", ":lua vim.lsp.buf.definition()<CR>", lsp_opts)
map("n", "<leader>k", ":lua vim.lsp.buf.hover()<CR>", lsp_opts)
map("n", "gi", ":lua vim.lsp.buf.implementation()<CR>", lsp_opts)
map("n", "<C-k>", ":lua vim.lsp.buf.signature_help()<CR>", lsp_opts)
map("n", "<leader>wa", ":lua vim.lsp.buf.add_workspace_folder()<CR>", lsp_opts)
map("n", "<leader>wr", ":lua vim.lsp.buf.remove_workspace_folder()<CR>", lsp_opts)
map("n", "<leader>wl", ":lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>", lsp_opts)
map("n", "<leader>D", ":lua vim.lsp.buf.type_definition()<CR>", lsp_opts)
map("n", "<leader>rn", ":lua vim.lsp.buf.rename()<CR>", lsp_opts)
map("n", "<leader>ca", ":lua vim.lsp.buf.code_action()<CR>", lsp_opts)
map("n", "gr", ":lua vim.lsp.buf.references()<CR>", lsp_opts)
map("n", "<leader>e", ":lua vim.lsp.diagnostic.show_line_diagnostics()<CR>", lsp_opts)
map("n", "[d", ":lua vim.lsp.diagnostic.goto_prev()<CR>", lsp_opts)
map("n", "]d", ":lua vim.lsp.diagnostic.goto_next()<CR>", lsp_opts)
map("n", "<leader>q", ":lua vim.lsp.diagnostic.set_loclist()<CR>", lsp_opts)

map("n", "gdv", ":vs | lua vim.lsp.buf.definition()<CR>", lsp_opts)
map("n", "grv", ":vs | lua vim.lsp.buf.references()<CR>", lsp_opts)

-- Dap
---- Movements
map("n", "<leader>dct", ":lua require(\"dap\").continue()<CR>")
map("n", "<leader>dsv", ":lua require(\"dap\").step_over()<CR>")
map("n", "<leader>dsi", ":lua require(\"dap\").step_into()<CR>")
map("n", "<leader>dso", ":lua require(\"dap\").step_out()<CR>")
map("n", "<leader>dsb", ":lua require(\"dap\").step_back()<CR>")
map("n", "<leader>dte", ":lua require(\"dap\").terminate()<CR>")

map("n", "<leader>drc", ":lua require(\"dap\").run_to_cursor()<CR>")
map("n", "<leader>dro", ":lua require(\"dap\").repl.open()<CR>")
map("n", "<leader>drl", ":lua require(\"dap\").run_last()<CR>")
---- Breakpoints
map("n", "<leader>dtb", ":lua require(\"dap\").toggle_breakpoint()<CR>")
map("n", "<leader>dsc", ":lua require(\"dap\").set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>")
map("n", "<leader>dlp", ":lua require(\"dap\").set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>")
---- UI
map('n', '<leader>dsc', '<cmd>lua require"dap.ui.variables".scopes()<CR>')
map('n', '<leader>dhh', '<cmd>lua require"dap.ui.variables".hover()<CR>')
map('v', '<leader>dhv', '<cmd>lua require"dap.ui.variables".visual_hover()<CR>')
map('n', '<leader>duh', '<cmd>lua require"dap.ui.widgets".hover()<CR>')
map('n', '<leader>duf', "<cmd>lua local widgets=require'dap.ui.widgets';widgets.centered_float(widgets.scopes)<CR>")
map('n', '<leader>dt', '<cmd>lua require"dapui".toggle()<CR>')


-- Remove unnecessary white spaces
map("n", "<leader>cw", ":StripWhitespace<CR>")

-- CodeActionMenu
map("n", "<leader>ca", ":CodeActionMenu<CR>")

-- Spectre
map("n", "<leader>sg", ":lua require('spectre').open()<CR>")
map("n", "<leader>sl", ":lua require('spectre').open_file_search()<CR>")

-- Split
map("n", "<leader>vs", ":vs | Telescope find_files find_command=rg,--follow,--hidden,--files<CR>")
map("n", "<leader>hs", ":sp | Telescope find_files find_command=rg,--follow,--hidden,--files<CR>")

