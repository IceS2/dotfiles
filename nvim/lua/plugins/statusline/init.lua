-- TODO: Add Virtualenv
return {
  "nvim-lualine/lualine.nvim",
  lazy = false,
  config = function()
    require("lualine").setup {
      options = {
        icons_enabled = true,
        theme = "auto",
        section_separators = { left = " ", right = " " },
        component_separators = { left = "│", right = "│" },
        always_divide_middle = true,
        globalstatus = true,
        extensions = {
          "lazy",
          "nvim-dap-ui",
          "neo-tree",
          "trouble"
        }
      }
    }
  end
}
