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
    {"<leader>xX", "<CMD>Toggle diagnostics toggle<CR>", desc = "[Trouble] Diagnostics"},
    {"<leader>xx", "<CMD>Trouble diagnostics toggle filter.buf=0 focus=true<CR>", desc = "[Trouble] Buffer Diagnostics"},
    {"<leader>xd", "<CMD>TodoTrouble focus=true<CR>", desc = "Toggle TODO in Trouble"},
    -- {"<leader>xr", "<CMD>TroubleToggle lsp_references<CR>", desc = "Toggle Trouble LSP References"}
    {"<leader>xl", "<CMD>Trouble lsp toggle focus=false win.position=right<CR>", desc = "[Trouble] LSP"},
    {"<leader>xL", "<CMD>Trouble loclist toggle<CR>", desc = "[Trouble] Location List"},
    {"<leader>xq", "<CMD>Trouble qflist toggle<CR>", desc = "[Trouble] Quickfix"},
    {"<leader>xs", "<CMD>Trouble symbols toggle focus=false<CR>", desc = "[Trouble] Symbols"}
  }
}
