return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      local tokyonight = require "tokyonight"
      tokyonight.setup {
        style = "moon",
        styles ={
            floats = "transparent"
        }
      }
      tokyonight.load()
    end
  }
}
