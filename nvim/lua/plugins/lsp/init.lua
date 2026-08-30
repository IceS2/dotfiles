return {
  {
    "mason-org/mason.nvim",
    lazy = false,
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = {},
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    lazy = false,
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      ensure_installed = {
        "codelldb",
        "js-debug-adapter",
        "markdownlint",
        "prettier",
        "stylua",
      },
      run_on_start = true,
      debounce_hours = 24,
    },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    config = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = function(ev)
          require("plugins.lsp.keymaps").setup(ev.buf)
        end,
      })

      -- Override Any Server Configuration
      -- ---------------------------------
      -- Python
      vim.lsp.config("ruff", require("lang.python.ruff"))
      vim.lsp.config("ty", require("lang.python.ty"))

      -- JavaScript
      vim.lsp.config("vtsls", require("lang.javascript.vtsls"))

      require("mason-lspconfig").setup({
        ensure_installed = {
          -- Lua
          "lua_ls",
          -- Python
          "ty",
          "ruff",
          -- JavaScript
          "vtsls",
          "biome",
          "astro",
        },
        automatic_enable = {
          exclude = {
            "rust_analyzer", -- rustaceanvim handles this
          },
        },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function() end,
  },
}
