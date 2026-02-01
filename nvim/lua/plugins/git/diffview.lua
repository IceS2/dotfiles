return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose", "DiffviewToggleFiles" },
  keys = {
    { "<leader>gdo", "<cmd>DiffviewOpen<cr>", desc = "Open Git DiffView" },
    { "<leader>gdc", "<cmd>DiffviewClose<cr>", desc = "Close Git DiffView" },
    { "<leader>gdf", "<cmd>DiffviewToggleFiles<cr>", desc = "Toggle DiffView file panel" },
    { "<leader>gdh", "<cmd>DiffviewFileHistory %<cr>", desc = "Show File History for current file" },
  },
  config = function()
    require("diffview").setup {}
  end,
}
