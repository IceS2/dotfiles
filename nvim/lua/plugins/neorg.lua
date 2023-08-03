return {
  "nvim-neorg/neorg",
  event = "VeryLazy",
  build = ":Neorg sync-parsers",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("neorg").setup {
      load = {
        ["core.defaults"] = {},
        ["core.concealer"] = {},
        ["core.dirman"] = {
          config = {
            workspaces = {
              personal = "~/.neorg/workspaces/personal",
              work = "~/.neorg/workspaces/work"
            }
          }
        }
      }
    }
  end
}
