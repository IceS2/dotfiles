return {
  "lukas-reineke/indent-blankline.nvim",
  event = "VeryLazy",
  config = function()
    vim.g.indent_blankline_show_first_indent_level = true
    vim.g.indent_blankline_show_trailing_blankline_indent = false
    vim.g.indent_blankline_buftype_exclude = { "terminal" }
    vim.g.indent_blankline_filetype_exclude = {
      "help",
      "terminal",
      "dashboard",
      "lspinfo"
    }
    require("indent_blankline").setup {
      show_current_context = true
    }
  end
}
