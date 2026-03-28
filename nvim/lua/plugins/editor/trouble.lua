return {
  "folke/trouble.nvim",
  cmd = "Trouble",
  opts = {
    focus = true,
  },
  keys = {
    { "<leader>xX", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics Panel (Workspace)" },
    { "<leader>xB", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Diagnostics Panel (Buffer)" },
    { "<leader>xS", "<cmd>Trouble symbols toggle<cr>", desc = "Symbols Panel" },
    { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix Panel" },
    { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location Panel" },
  },
}
