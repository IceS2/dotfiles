return {
  {
    "aznhe21/actions-preview.nvim",
    lazy = false,
    config = function()
      require("actions-preview").setup {
        backend = { "nui", "telescope" }
      }
    end,
    keys = {
      { "<leader>ca", function() require("actions-preview").code_actions() end, desc = "Open Code Action Menu"}
    }
  }
}
