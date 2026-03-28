local map = vim.keymap.set

-- Better Escape
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })
map("t", "jk", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Window Navigation
map("n", "<A-Left>", "<C-w>h", { desc = "Go to left window" })
map("n", "<A-Down>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<A-Up>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<A-Right>", "<C-w>l", { desc = "Go to right window" })

-- Search
map("n", "n", "nzz", { desc = "Next result (centered)" })
map("n", "N", "Nzz", { desc = "Prev result (centered)" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- Editing
map("v", "p", '"_dP', { desc = "Paste without yanking" })
