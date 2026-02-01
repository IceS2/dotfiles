return {
  "FabijanZulj/blame.nvim",
  lazy = false,
  config = function()
    require("blame").setup({
      date_format="%Y-%m-%d"
    })
  end,
  keys = {
      -- Blame
      vim.keymap.set("n", "<leader>gb", "<cmd>BlameToggle<cr>", { desc = "Toggle Blame" }),
      vim.keymap.set("n", "<leader>gB", "<cmd>BlameToggle virtual<cr>", { desc = "Toggle Blame Virtual" })
  }
}

