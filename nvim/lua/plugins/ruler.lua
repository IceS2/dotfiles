return {
  "m4xshen/smartcolumn.nvim",
  event = "VeryLazy",
  opts = {
    colorcolumn = "80",
    disabled_filetypes = {
      "help",
      "text",
      "markdown",
      "NvimTree",
      "lazy",
      "mason"
    },
    scope = "file",
    custom_colorcolumn = {
      python = "120"
    }
  }
}
