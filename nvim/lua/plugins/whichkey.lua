return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    dependencies = { "mrjones2014/legendary.nvim" },
    config = function()
      local wk = require "which-key"
      wk.setup {
        show_help = false,
        plugins = { spelling = true },
        replace = { ["<leader>"] = "SPC" },
        triggers = { "<auto>", mode ="nixsotc" }
      }
      wk.add({
        { "<leader>c", group = "Code" },
        { "<leader>cg", group = "Generate" },
        { "<leader>d", group = "Debug" },
        { "<leader>f", group = "Find" },
        { "<leader>g", group = "Git" },
        { "<leader>r", group = "Run" },
        { "<leader>s", group = "Search" },
        { "<leader>t", group = "Terminal" },
        { "<leader>w", group = "Workspace" },
        { "<leader>wt", group = "Tab" },
        { "<leader>x", group = "Trouble" },
      })
    end
  },
}
