return {
  {
    "echasnovski/mini.ai",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      {
        "nvim-treesitter/nvim-treesitter-textobjects",
        init = function()
          require("lazy.core.loader").disable_rtp_plugin "nvim-treesitter-textobjects"
        end
      },
      "kana/vim-textobj-user",
      "kana/vim-textobj-entire",
      "kana/vim-textobj-line",
      "kana/vim-textobj-indent",
    },
    keys = {
      { "a", mode = { "x", "o" }},
      { "i", mode = { "x", "o" }},
    },
    config = function()
      local ai = require "mini.ai"
      ai.setup {
        n_lines = 500,
        custom_textobjects = {
          o = ai.gen_spec.treesitter({
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" }
          }, {}),
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner"} , {}),
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner"} , {})
        },
        mappings = {
          around_next = "",
          inside_next = "",
          around_last = "",
          inside_last = ""
        }
      }
    end
  },
  {
    "windwp/nvim-autopairs",
    event = { "InsertEnter" },
    config = true
  },
  {
    "echasnovski/mini.splitjoin",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("mini.splitjoin").setup {
        mappings = {
          toggle = ""
        }
      }
    end,
    keys = {
      {"gS", ":lua require('mini.splitjoin').toggle()<CR>", desc = "SplitJoin Toggle"}
    }
  },
  {
    "echasnovski/mini.surround",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("mini.surround").setup {
        mappings = {
          add = "sa",
          delete = "sd",
          find = "sf",
          find_left = "sF",
          highlight = "sh",
          replace = "sr",
          update_n_lines = "sn",
          suffix_last = "l",
          suffix_next = "n"
        },
        n_lines = 20
      }
    end
  },
  {
    "echasnovski/mini.misc",
    event = "VeryLazy",
    keys = {
      { "<leader>vz", function() require("mini.misc").zoom() end, desc = "Toggle Zoom" },
    },
  },
  {
    "ntpeters/vim-better-whitespace",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      vim.g.better_whitespace_filetypes_blacklist = {
        "lspinfo",
        "TelescopePrompr",
        "dashboard"
      }
      vim.g.strip_whitespace_on_save = 1
      vim.g.strip_whitespace_confirm = 1
      vim.g.strip_whitelines_at_eof = 1
      vim.g.better_whitespace_enabled = 0
    end
  }
}
