return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    dependencies = { "mrjones2014/legendary.nvim" },
    config = function()
      local wk = require "which-key"
      wk.setup {
        show_help = false,
        plugins = { spelling = true },
        key_labels = { ["<leader>"] = "SPC" },
        triggers = "auto"
      }
      wk.register({
        -- w = { "<cmd>update!<CR>", "Save" },
        -- q = { "<cmd>lua require('utils').quit()<CR>", "Quit" },
        -- b = { name = "+Buffer" },
        c = { name = "+Code" },
        d = { name = "+Debug" },
        f = { name = "+Find" },
        g = { name = "+Git" },
        r = { name = "+Run" },
        s = { name = "+Search" },
        t = { name = "+Terminal" },
        w = { name = "+Workspace" },
        x = { name = "+Trouble" },
        -- h = { name = "+Help" },
        -- g = { name = "+Git" },
        -- p = { name = "+Project" },
        -- v = { name = "+View" },
        -- ["sn"] = { name = "+Noice" },
        -- s = {
        --   name = "+Search",
        --   c = {
        --     function()
        --       require("utils.cht").cht()
        --     end,
        --     "Cheatsheets",
        --   },
        --   s = {
        --     function()
        --       require("utils.cht").stack_overflow()
        --     end,
        --     "Stack Overflow",
        --   },
        -- },
        -- c = {
        --   name = "+Code",
        --   x = {
        --     name = "Swap Next",
        --     f = "Function",
        --     p = "Parameter",
        --     c = "Class",
        --   },
        --   X = {
        --     name = "Swap Previous",
        --     f = "Function",
        --     p = "Parameter",
        --     c = "Class",
        --   },
        -- },
      }, { prefix = "<leader>" })
    end
  },
}
