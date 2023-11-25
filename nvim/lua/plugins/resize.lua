return {
  "artart222/vim-resize",
  event = "VeryLazy",
  keys = {
    { "<C-Left>", "<CMD>:call ResizeLeft(3)<CR>", desc = "Resize Left" },
    { "<C-Down>", "<CMD>:call ResizeDown(1)<CR>", desc = "Resize Down" },
    { "<C-Up>", "<CMD>:call ResizeUp(1)<CR>", desc = "Resize Up" },
    { "<C-Right>", "<CMD>:call ResizeRight(4)<CR>", desc = "Resize Right" }
  }
}
