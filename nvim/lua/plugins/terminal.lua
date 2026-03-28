return {
  "2kabhishek/termim.nvim",
  cmd = { "Fterm", "FTerm", "Sterm", "STerm", "Tterm", "TTerm", "Vterm", "VTerm" },
  keys = {
      -- Ephemeral terminals (auto-close when exited)
      { "<leader>;f", "<cmd>Fterm<cr>", desc = "Float terminal (ephemeral)" },
      { "<leader>;s", "<cmd>Sterm<cr>", desc = "Split terminal (ephemeral)" },
      { "<leader>;v", "<cmd>Vterm<cr>", desc = "Vsplit terminal (ephemeral)" },
      { "<leader>;t", "<cmd>Tterm<cr>", desc = "Tab terminal (ephemeral)" },

      -- Persistent terminals (stay open until manually closed)
      { "<leader>;F", "<cmd>FTerm<cr>", desc = "Float terminal (persistent)" },
      { "<leader>;S", "<cmd>STerm<cr>", desc = "Split terminal (persistent)" },
      { "<leader>;V", "<cmd>VTerm<cr>", desc = "Vsplit terminal (persistent)" },
      { "<leader>;T", "<cmd>TTerm<cr>", desc = "Tab terminal (persistent)" },
  }
}
