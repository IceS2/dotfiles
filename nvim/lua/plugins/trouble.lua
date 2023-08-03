return {
  "folke/trouble.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "folke/todo-comments.nvim"
  },
  config = function()
    require("trouble").setup {
      height = 20,
      signs = {
        error = "",
        warning = "",
        information = "",
        hint = "",
        other = ""
      }
    }
  end,
  keys = {
    {"<leader>xx", "<CMD>TroubleToggle<CR>", desc = "Toggle Trouble"},
    {"<leader>xd", "<CMD>TodoTrouble<CR>", desc = "Toggle TODO in Trouble"}
  }
}
