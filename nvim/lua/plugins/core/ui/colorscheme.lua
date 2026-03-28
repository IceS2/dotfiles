return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "mocha", -- latte, frappe, macchiato, mocha
      background = {
        light = "latte",
        dark = "mocha",
      },
      transparent_background = false,
      show_end_of_buffer = false,
      term_colors = true,
      dim_inactive = {
        enabled = false,
        shade = "dark",
        percentage = 0.15,
      },
      no_italic = false,
      no_bold = false,
      no_underline = false,
      styles = {
        comments = { "italic" },
        conditionals = { "italic" },
        loops = {},
        functions = {},
        keywords = {},
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
        operators = {},
      },
      color_overrides = {
        mocha = (function()
          local palette_path = vim.fn.expand("~/.config/theme/nvim-palette.lua")
          if vim.fn.filereadable(palette_path) == 1 then
            local ok, colors = pcall(dofile, palette_path)
            if ok and colors then return colors end
          end
          return {}
        end)(),
      },
      custom_highlights = {},
      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        treesitter = true,
        notify = false,
        mini = {
          enabled = true,
          indentscope_color = "",
        },
        native_lsp = {
          enabled = true,
          virtual_text = {
            errors = { "italic" },
            hints = { "italic" },
            warnings = { "italic" },
            information = { "italic" },
          },
          underlines = {
            errors = { "underline" },
            hints = { "underline" },
            warnings = { "underline" },
            information = { "underline" },
          },
        },
        telescope = true,
        which_key = true,
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")

      -- Live theme reload on SIGUSR1 (sent by apply-theme.sh)
      vim.api.nvim_create_autocmd("Signal", {
        pattern = "SIGUSR1",
        callback = function()
          local palette_path = vim.fn.expand("~/.config/theme/nvim-palette.lua")
          if vim.fn.filereadable(palette_path) == 1 then
            local ok, colors = pcall(dofile, palette_path)
            if ok and colors then
              opts.color_overrides = { mocha = colors }
              require("catppuccin").setup(opts)
              vim.cmd.colorscheme("catppuccin")
            end
          end
        end,
      })
    end,
  },
}
