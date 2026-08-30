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
      ensure_installed = { "codelldb", "js-debug-adapter" },
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
      local default_capabilities = require("blink.cmp").get_lsp_capabilities()

      -- Setup autocommand with default groups and capabilities
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client then
            client.config.capabilities = vim.tbl_deep_extend(
              "force",
              client.config.capabilities or {},
              default_capabilities)
          end
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
        automatic_enable =  {
          exclude = {
            "rust_analyzer", -- rustaceanvim handles this
          },
        }
      })
    end
  },
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
    end
  }
}
