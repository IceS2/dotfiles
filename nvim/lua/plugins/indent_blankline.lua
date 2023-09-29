return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  event = "VeryLazy",
  config = function()
    require("ibl").setup {
      exclude = {
        buftypes = { "terminal" },
        filetypes = {
          "help",
          "terminal",
          "dashboard",
          "lspinfo"
        }
      },
      scope = {
        enabled = true,
        show_start = true
      },
      whitespace = {
        remove_blankline_trail = true
      }
    }
  end
}
