return {
  "FabijanZulj/blame.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("blame").setup({
      date_format="%Y-%m-%d"
    })
  end,
  keys = {
    { "<leader>gb", "<cmd>BlameToggle<cr>", desc = "Toggle Blame" },
    { "<leader>gv", "<cmd>BlameToggle virtual<cr>", desc = "Toggle Blame Virtual" }
  }
}

