return {
  "rebelot/heirline.nvim",
  event = "VeryLazy",
  dependencies = {
    "Zeioth/heirline-components.nvim",
    "echasnovski/mini.icons",
  },
  config = function()
    local heirline = require("heirline")
    local hc = require("heirline-components.all")

    hc.init.subscribe_to_events()
    heirline.load_colors(hc.hl.get_colors())

    heirline.setup({
      statusline = {
        hc.component.mode({ mode_text = {} }),
        hc.component.git_branch(),
        hc.component.git_diff(),
        hc.component.diagnostics(),
        hc.component.fill(),
        hc.component.file_info(),
        hc.component.lsp(),
        hc.component.virtual_env(),
        hc.component.nav(),
      },
      statuscolumn = {
        hc.component.foldcolumn(),
        hc.component.numbercolumn(),
        hc.component.signcolumn(),
      }
    })
  end,
}
