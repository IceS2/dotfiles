return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
    delay = function(ctx)
      return ctx.plugin and 0 or 200
    end,
    plugins = {
      marks = true,
      registers = true,
      spelling = {
        enabled = true,
        suggestions = 20,
      },
      presets = {
        operators = true,
        motions = true,
        text_objects = true,
        windows = true,
        nav = true,
        z = true,
        g = true,
      },
    },
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
      { "<leader>t", group = "Test", icon = " " },
      { "<leader>u", group = "UI", icon = " " },
      { "<leader>;", group = "Terminal", icon = " " },
      { "<leader>a", group = "AI", icon = "󰁤 " },
      { "<leader>x", group = "Diagnostics", icon = " " },
    }
  }
}
