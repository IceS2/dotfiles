return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
    delay = 300,
    spec = {
      { "<leader>b", group = "Buffer", icon = " " },
      { "<leader>c", group = "Code", icon = " " },
      { "<leader>d", group = "Debug", icon = " " },
      { "<leader>f", group = "File/Find", icon = " " },
      { "<leader>g", group = "Git", icon = "󰊢 " },
      { "<leader>t", group = "Terminal", icon = " " },
      { "<leader>x", group = "Trouble", icon = " " },
    }
  }
}
