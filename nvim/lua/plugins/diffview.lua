return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewRefresh", "DiffviewFileHistory"},
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("diffview").setup {}
  end,
  keys = {
    { "<leader>gh", "<CMD>DiffviewFileHistory %<CR>", desc = "File History" },
    { "<leader>gd", "<CMD>DiffviewOpen<CR>", desc = "DiffView Open"},
  }
}
