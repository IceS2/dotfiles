return {
  {
    "mrcjkb/rustaceanvim",
    version = "^6",
    ft = "rust",
    init = function()
      vim.g.rustaceanvim = {
        tools = {
          test_executor = "background",
        },
        server = {
          on_attach = function(_, bufnr)
            local opts = { buffer = bufnr }
            require("plugins.lsp.keymaps").setup(bufnr)
            vim.keymap.set("n", "<leader>ca", function()
              vim.cmd.RustLsp("codeAction")
            end, opts)
            vim.keymap.set("n", "<leader>cR", function()
              vim.cmd.RustLsp("runnables")
            end, opts)
            vim.keymap.set("n", "<leader>cD", function()
              vim.cmd.RustLsp("debuggables")
            end, opts)
            vim.keymap.set("n", "<leader>ce", function()
              vim.cmd.RustLsp("expandMacro")
            end, opts)
            vim.keymap.set("n", "<leader>cp", function()
              vim.cmd.RustLsp("parentModule")
            end, opts)
            vim.keymap.set("n", "K", function()
              vim.cmd.RustLsp({ "hover", "actions" })
            end, opts)
          end,
          default_settings = {
            ["rust-analyzer"] = {
              checkOnSave = { command = "clippy" },
              inlayHints = {
                closingBraceHints = { enable = true },
                parameterHints = { enable = true },
                typeHints = { enable = true },
              }
            }
          }
        }
      }
    end
  },
  {
    "saecki/crates.nvim",
    tag = "stable",
    event = { "BufRead Cargo.toml" },
    opts = {
      completion = {
        cmp = {
          enabled = true,
        }
      }
    }
  },
  {
    "saghen/blink.compat",
    version = "2.*",
    lazy = true,
    opts = {}
  },
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        default = { "crates" },
        providers = {
          crates = {
            name = "crates",
            module = "blink.compat.source"
          }
        }
      }
    }
  }
}
