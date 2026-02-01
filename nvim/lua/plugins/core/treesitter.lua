return {
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter.configs").setup({
          ensure_installed = {
            "bash",
            "json",
            "lua",
            "markdown",
            "markdown_inline",
            "query",
            "regex",
            "rust",
            "toml",
            "vim",
            "vimdoc",
            "yaml",
        },
        highlight = { enable = true },
        indent = { enable = true },
        matchup = { enable = true },
      })
    end,
  },
  {
    "davidmh/mdx.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    lazy = false
  },
  {
    "andymass/vim-matchup",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      vim.g.matchup_matchparen_offscreen = { method = "popup" }
    end,
  },
  {
    "windwp/nvim-ts-autotag",
    ft = {
      "html",
      "xml",
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
      "markdown",
      "mdx",
    },
    config = function()
      require("nvim-ts-autotag").setup({
        opts = {
          enable_close = true,
          enable_rename = true,
          enable_close_on_slash = false,
        },
      })
    end
  },
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      vim.g.rainbow_delimiters = {
        query = {
          [""] = "rainbow-delimiters",
          lua = "rainbow-blocks"
        }
      }
    end,
  },
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
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner"} , {}),
          p = ai.gen_spec.treesitter({ a = "@parameter.outer", i = "@parameter.inner" }, {}),
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
}
