-- TODO: Add Virtualenv

return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "linux-cultist/venv-selector.nvim" }
,
  lazy = false,
  config = function()

    local function get_venv()
      local venv_name = require("venv-selector").get_active_venv()
      if venv_name ~= nil then
        return venv_name
      else
        return [[No Venv Active]]
      end
    end

    require("lualine").setup {
      sections = {
        lualine_a = {'mode'},
        lualine_b = {'branch', 'diff', 'diagnostics'},
        lualine_c = {'filename'},
        lualine_x = {'encoding', 'fileformat', 'filetype', get_venv },
        lualine_y = {'progress'},
        lualine_z = {'location'}
      },
      options = {
        icons_enabled = true,
        theme = "auto",
        disabled_filetypes = {
          statusline = { "dashboard", "lazy" },
          winbar = { "dashboard", "lazy" }
        },
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
