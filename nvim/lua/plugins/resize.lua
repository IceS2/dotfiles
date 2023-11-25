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
    { mode="t", "<C-Right>", "<C-\\><C-n> <CMD>:call ResizeRight(4)<CR>", desc = "Resize Right" }
  }
}
