local function map(mode, lhs, rhs, opts)
  local options = {noremap = true}
  if opts then options = vim.tbl_extend("force", options, opts) end
  vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end


-- Mapping leader key
vim.g.mapleader = " "

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

-- Buffer switching
map("n", "<A-[>", ":BufferLineCyclePrev<CR>")
map("n", "<A-]>", ":BufferLineCycleNext<CR>")

-- Buffer closing
map("n", "<leader>bc", ":BufferLinePickClose<CR>")

-- Buffer moving
map("n", "<leader>bl", ":BufferLineMoveNext<CR>")
map("n", "<leader>bh", ":BufferLineMovePrev<CR>")

-- NvimTree toggle
map("n", "<leader>nt", ":NvimTreeToggle<CR>")

-- Telescope
map("n", "<leader>fw", ":Telescope live_grep<CR>")
map("n", "<leader>gt", ":Telescope git_status<CR>")
map("n", "<leader>cm", ":Telescope git_commit<CR>")
map("n", "<leader>ff", ":Telescope find_files find_command=rg,--follow,--hidden,--files<CR>")
map("n", "<leader>fb", ":Telescope buffers<CR>")
map("n", "<leader>fh", ":Telescope help_tags<CR>")
map("n", "<leader>fo", ":Telescope oldfiles<CR>")
map("n", "<leader>th", ":Telescope colorscheme<CR>")
map("n", "<leader>fr", ":Telescope registers<CR>")
map("n", "<leader>sn", ":Telescope neoclip ")
map("n", "<leader>fa", ":Telescope aerial<CR>")
map("n", "<leader>fp", ":Telescope projects<CR>")
map("n", "<leader>ft", ":TodoTelescope<CR>")

-- Dashboard
map("n", "<leader>db", ":Dashboard<CR>")
map("n", "<leader>fn", ":DashboardNewFile<CR>")
map("n", "<leader>bm", ":DashboardJumpMarks<CR>")
map("n", "<C-s>l", ":SessionLoad<CR>")
map("n", "<C-s>s", ":SessionSave<CR>")

-- Todo
-- map("n", "<leader>td", ":TodoTelescope<CR>")

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
map("n", "<leader>dt", ":lua require(\"dap\").toggle()<CR>")
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
map("n", "<leader>dsb", ":lua require(\"dap\").set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>")
map("n", "<leader>dlp", ":lua require(\"dap\").set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>")
---- UI
map('n', '<leader>dsc', '<cmd>lua require"dap.ui.variables".scopes()<CR>')
map('n', '<leader>dhh', '<cmd>lua require"dap.ui.variables".hover()<CR>')
map('v', '<leader>dhv', '<cmd>lua require"dap.ui.variables".visual_hover()<CR>')
map('n', '<leader>duh', '<cmd>lua require"dap.ui.widgets".hover()<CR>')
map('n', '<leader>duf', "<cmd>lua local widgets=require'dap.ui.widgets';widgets.centered_float(widgets.scopes)<CR>")
map('n', '<leader>dui', '<cmd>lua require"dapui".open()<CR>')
---- Telescope
map('n', '<leader>dcc', '<cmd>lua require"telescope".extensions.dap.commands{}<CR>')
map('n', '<leader>dco', '<cmd>lua require"telescope".extensions.dap.configurations{}<CR>')
map('n', '<leader>dlb', '<cmd>lua require"telescope".extensions.dap.list_breakpoints{}<CR>')
map('n', '<leader>dv', '<cmd>lua require"telescope".extensions.dap.variables{}<CR>')
map('n', '<leader>df', '<cmd>lua require"telescope".extensions.dap.frames{}<CR>')


-- ToggleTerm
map("n", "<C-t>", ":ToggleTerm dir=%:p:h<CR>")
map("t", "<C-t>", ":ToggleTerm dir=%:p:h<CR>")
map("n", "v:count1 <C-t>", ":v:count1" .. "\"ToggleTerm\"<CR>")
map("v", "v:count1 <C-t>", ":v:count1" .. "\"ToggleTerm\"<CR>")
function _G.set_terminal_keymaps()
  map("t", "<esc>", "<C-\\><C-n>")
  map("t", "<A-h>", "<C-\\><C-n><C-w>h")
  map("t", "<A-j>", "<C-\\><C-n><C-w>j")
  map("t", "<A-k>", "<C-\\><C-n><C-w>k")
  map("t", "<A-l>", "<C-\\><C-n><C-w>l")

  map("t", "<S-h>", "<C-\\><C-n>:call ResizeLeft(3)<CR>")
  map("t", "<S-j>", "<C-\\><C-n>:call ResizeDown(1)<CR>")
  map("t", "<S-k>", "<C-\\><C-n>:call ResizeUp(1)<CR>")
  map("t", "<S-l>", "<C-\\><C-n>:call ResizeRight(3)<CR>")
end
vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")

-- Remove unnecessary white spaces
map("n", "<leader>cw", ":StripWhitespace<CR>")

-- Comment
-- map("n", "ct", ":CommentToggle<CR>")
-- map("v", "ct", ":'<,'>CommentToggle<CR>")

-- Code Formatter
-- map("n", "<leader>fr", ":Neoformat<CR>", lsp_opts)

-- CodeActionMenu
map("n", "<leader>ca", ":CodeActionMenu<CR>")

-- Spectre
map("n", "<leader>sg", ":lua require('spectre').open()<CR>")
map("n", "<leader>sl", ":lua require('spectre').open_file_serach()<CR>")

-- Split
map("n", "<leader>vs", ":vs | Telescope find_files find_command=rg,--follow,--hidden,--files<CR>")
map("n", "<leader>hs", ":sp | Telescope find_files find_command=rg,--follow,--hidden,--files<CR>")

