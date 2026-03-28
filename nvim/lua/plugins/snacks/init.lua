return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      bigfile = { enabled = true },
      dim = { enabled = true },
      image = { enabled = true },
      indent = { enabled = true },
      input = { enabled = true },
      notifier = { enabled = true },
      scope = { enabled = true },
      scroll = { enabled = true },
      words = { enabled = true },
    },
    keys = {
      { "<leader>fn", function() Snacks.notifier.show_history() end, desc = "Notification History" },
      { "<leader>gB", function() Snacks.gitbrowse() end, desc = "Git Browse (Open in Browser)" },
      { "<leader>ud", function() if Snacks.dim.enabled then Snacks.dim.disable() else Snacks.dim.enable() end end, desc = "Toggle Dim" },
    },
  },
  { import = "plugins.snacks.lazygit" },
  { import = "plugins.snacks.picker" },
  { import = "plugins.snacks.explorer" },
}
