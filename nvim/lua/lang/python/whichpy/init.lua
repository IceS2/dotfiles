return {
  "neolooong/whichpy.nvim",
  ft = { "python" },
  opts = {
    -- update_path_env = false,
    -- picker = { name = "telescope" },
    lsp = {
      ty = require("lang.python.whichpy.handlers.ty").new()
    }
  }
}
