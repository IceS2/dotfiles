return {
  "folke/snacks.nvim",
  priority = 999,
  lazy = false,
  opts = {
    lazygit = {}
  },
  keys = {
    { "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit"}
  }
}
