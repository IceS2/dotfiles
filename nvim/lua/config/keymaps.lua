local keymap = vim.api.nvim_set_keymap

-- Better escape using jk in insert and terminal mode
keymap("i", "jk", "<ESC>", { noremap = true, silent = true })
keymap("t", "jk", "<C-\\><C-n>", { noremap = true, silent = true })

-- Center search results
keymap("n", "n", "nzz", { noremap = true, silent = true })
keymap("n", "N", "Nzz", { noremap = true, silent = true })

-- Cancel search highlighting with ESC
keymap("n", "<ESC>", ":nohlsearch<Bar>:echo<CR>", { noremap = true, silent = true })


keymap("n", "qq", "<NOP>", {})
