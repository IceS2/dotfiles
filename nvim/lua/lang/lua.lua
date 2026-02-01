return {
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      integrations = {
        lspconfig = true
      }
    },
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
}
