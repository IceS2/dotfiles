return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
    delay = 300,
    spec = {
      { "<leader><leader>", desc = "Smart Find" },
      { "<leader>b", group = "Buffers", icon = " " },
      { "<leader>c", group = "Code", icon = " " },
      { "<leader>d", group = "Debug", icon = " " },
      { "<leader>e", desc = "Explorer" },
      { "<leader>E", desc = "Explorer (File Dir)" },
      { "<leader>f", group = "Find", icon = " " },
      { "<leader>g", group = "Git", icon = "󰊢 " },
      { "<leader>s", group = "Search", icon = " " },
      { "<leader>t", group = "Terminal", icon = " " },
      { "<leader>x", group = "Diagnostics", icon = " " },
    }
  }
}
