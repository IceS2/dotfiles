return {
  "artart222/vim-resize",
  event = "VeryLazy",
  keys = {
    { "<C-Left>", "<CMD>:call ResizeLeft(3)<CR>", desc = "Resize Left" },
    { "<C-Down>", "<CMD>:call ResizeDown(1)<CR>", desc = "Resize Down" },
    { "<C-Up>", "<CMD>:call ResizeUp(1)<CR>", desc = "Resize Up" },
    { "<C-Right>", "<CMD>:call ResizeRight(4)<CR>", desc = "Resize Right" },

    { mode="t", "<C-Left>", "<C-\\><C-n> <CMD>:call ResizeLeft(3)<CR>", desc = "Resize Left" },
    { mode="t", "<C-Down>", "<C-\\><C-n> <CMD>:call ResizeDown(1)<CR>", desc = "Resize Down" },
    { mode="t", "<C-Up>", "<C-\\><C-n> <CMD>:call ResizeUp(1)<CR>", desc = "Resize Up" },
    { mode="t", "<C-Right>", "<C-\\><C-n> <CMD>:call ResizeRight(4)<CR>", desc = "Resize Right" },

    { "<C-h>", "<CMD>:call ResizeLeft(3)<CR>", desc = "Resize Left" },
    { "<C-j>", "<CMD>:call ResizeDown(1)<CR>", desc = "Resize Down" },
    { "<C-k>", "<CMD>:call ResizeUp(1)<CR>", desc = "Resize Up" },
    { "<C-l>", "<CMD>:call ResizeRight(4)<CR>", desc = "Resize Right" },

    { mode="t", "<C-h>", "<C-\\><C-n> <CMD>:call ResizeLeft(3)<CR>", desc = "Resize Left" },
    { mode="t", "<C-j>", "<C-\\><C-n> <CMD>:call ResizeDown(1)<CR>", desc = "Resize Down" },
    { mode="t", "<C-k>", "<C-\\><C-n> <CMD>:call ResizeUp(1)<CR>", desc = "Resize Up" },
    { mode="t", "<C-l>", "<C-\\><C-n> <CMD>:call ResizeRight(4)<CR>", desc = "Resize Right" }
  }
}
