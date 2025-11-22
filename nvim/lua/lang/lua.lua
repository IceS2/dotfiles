return {
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {}
  },
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        default = { "lazydev" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100,
          }
        }
      }
    }
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      require("lazydev")
      vim.lsp.config("lua_ls", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
        on_attach = function(_, bufnr)
            require("plugins.lsp.keymaps").setup(bufnr)
        end,
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          }
        }
      })
    end
  },
}
