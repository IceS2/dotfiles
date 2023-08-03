return {
  {
    "weilbith/nvim-code-action-menu",
    cmd = "CodeActionMenu",
    keys = {
      { "<leader>ca", "<CMD>CodeActionMenu<CR>", desc = "Open CodeAction Menu"}
    }
  },
  {
    "kosayoda/nvim-lightbulb",
    event = "VeryLazy",
    config = function()
      require("nvim-lightbulb").setup {
        autocmd = {
          enabled = true
        }
      }
    end
  }
}
