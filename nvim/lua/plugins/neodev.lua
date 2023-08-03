return {
  "folke/neodev.nvim",
  event = "VeryLazy",
  config = function()
    require("neodev").setup {
      library = {
        plugins = { "nvim-dap-ui", "neotest" },
        types = true
      }
    }
  end
}
