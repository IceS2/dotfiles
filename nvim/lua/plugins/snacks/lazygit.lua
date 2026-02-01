return {
  "snacks.nvim",
  opts = {
    lazygit = {}
  },
  keys = {
    { "<leader>gg", function() 
          local Snacks = require("snacks")
          Snacks.lazygit()
        end, desc = "Lazygit"}
  }
}
