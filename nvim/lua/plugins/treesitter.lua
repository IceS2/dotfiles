return {
  {
    "nvim-treesitter/nvim-treesitter",
    event = "BufReadPost",
    dependencies = { "windwp/nvim-ts-autotag" },
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup {
        ensure_installed = {
          "bash",
          "css",
          "dockerfile",
          "graphql",
          "hcl",
          "html",
          "javascript",
          "json",
          "kotlin",
          "lua",
          "make",
          "markdown",
          "markdown_inline",
          "norg",
          "python",
          "query",
          "regex",
          "rst",
          "rust",
          "sql",
          "terraform",
          "toml",
          "tsx",
          "typescript",
          "vim",
          "yaml"
        },
        highlight = {
          enable = true,
        },
        indent = {
          enable = true,
        },
        matchup = {
          enable = true
        },
        autotag = {
          enable = true
        }
      }
    end
  },
  {
    "IndianBoy42/tree-sitter-just",
    event = "BufReadPost",
    dependencies={ "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("tree-sitter-just").setup({})
    end
  }
}
