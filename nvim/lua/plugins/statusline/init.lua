-- TODO: Add Virtualenv
return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  config = function()
    require("lualine").setup {
      options = {
        icons_enabled = true,
        theme = "auto",
        -- disabled_filetypes = {
        --   statusline = { "dashboard", "lazy" },
        --   winbar = { "dashboard", "lazy" }
        -- },
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
