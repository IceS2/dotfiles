return {
  "termim",
  dir = "~/Workspace/ices2/termim.nvim/",
  lazy = false,
  keys = {
      -- Default toggles
      { "<leader>tf", "<cmd>FToggleTerm<cr>", desc = "Toggle float terminal" },
      { "<leader>ts", "<cmd>SToggleTerm<cr>", desc = "Toggle split terminal" },
      { "<leader>tv", "<cmd>VToggleTerm<cr>", desc = "Toggle vsplit terminal" },
      { "<leader>tt", "<cmd>TToggleTerm<cr>", desc = "Toggle tab terminal" },

      -- Ephemeral terminals
      { "<leader>tF", "<cmd>FTerm<cr>",       desc = "Float terminal" },
      { "<leader>tS", "<cmd>STerm<cr>",       desc = "Split terminal" },
      { "<leader>tV", "<cmd>VTerm<cr>",       desc = "VSplit terminal" },
      { "<leader>tR", "<cmd>TTerm<cr>",       desc = "Tab terminal" },

  }
}
