-- TODO: Add mapping to format code lua vim.lsp.buf.format()
return {
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    dependencies = {
      "folke/neodev.nvim",
      "hrsh7th/cmp-nvim-lsp",
      "williamboman/mason-lspconfig.nvim",
      "williamboman/mason.nvim",
      "simrat39/rust-tools.nvim",
      "towolf/vim-helm"
    },
    config = function()
      local lsp_capabilities = require("cmp_nvim_lsp").default_capabilities()

      vim.api.nvim_create_autocmd('LspAttach', {
        desc = 'LSP actions',
        callback = function(event)
          local opts = {buffer = event.buf}

          vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
          vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
          -- vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
          vim.keymap.set('n', 'gD', '<C-W><C-V> <cmd> lua vim.lsp.buf.definition()<cr>', opts)
          vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
          vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
          vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
          vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
          vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
          vim.keymap.set({'n', 'x'}, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
          vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)

          vim.keymap.set('n', 'gl', '<cmd>lua vim.diagnostic.open_float()<cr>', opts)
          vim.keymap.set('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<cr>', opts)
          vim.keymap.set('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<cr>', opts)
        end
      })

      require("mason-lspconfig").setup {
        ensure_installed = {
          "bashls",                                     -- Bash
          "cssls",                                      -- CSS
          "cssmodules_ls",                              -- CSS Modules
          "dockerls",                                   -- Docker
          "docker_compose_language_service",            -- Docker Compose
          "gopls",                                      -- Go
          "graphql",                                    -- GraphQL
          "helm_ls",                                    -- Helm
          "html",                                       -- HTML
          "jsonls",                                     -- JSON
          "tsserver",                                   -- TypeScript/JavaScript
          "kotlin_language_server",                     -- Kotlin
          "lua_ls",                                     -- Lua
          "marksman",                                   -- Markdown
          "pyright",                                    -- Python
          "ruff_lsp",                                   -- Python
          "rust_analyzer",                              -- Rust
          "sqlls",                                      -- SQL
          "taplo",                                      -- TOML
          "terraformls",                                -- Terraform
          "tflint",                                     -- Terraform
          "vimls",                                      -- Vim
          "lemminx",                                    -- XML
          "yamlls"                                      -- YAML
        }
      }

      require("mason-lspconfig").setup_handlers {
        function(server_name)
          require("lspconfig")[server_name].setup {
            capabilities = lsp_capabilities
          }
        end,

        -- ["pyright"] = function()
        --   require("lspconfig").pyright.setup {
        --     capabilities = lsp_capabilities,
        --     settings = {
        --       python = {
        --         venvPath = vim.fn.expand('/$HOME/.pyenv/versions/')
        --       }
        --     }
        --   }
        -- end,

        ["docker_compose_language_service"] = function()
          require("lspconfig").docker_compose_language_service.setup {
            capabilities = lsp_capabilities,
            on_attach = function(client, bufnr)
              if vim.bo[bufnr].buftype ~= "" or vim.bo[bufnr].filetype == "helm" then
                -- vim.lsp.buf_detach_client(bufnr, client.id)
                vim.lsp.stop_client(client.id)
              end
            end,
          }
        end,

        ["yamlls"] = function()
          require("lspconfig").yamlls.setup {
            capabilities = lsp_capabilities,
            on_attach = function(client, bufnr)
              if vim.bo[bufnr].buftype ~= "" or vim.bo[bufnr].filetype == "helm" then
                -- vim.lsp.buf_detach_client(bufnr, client.id)
                vim.lsp.stop_client(client.id)
              end
            end,
            settings = {
              yaml = {
                keyOrdering = false
              }
            }
          }
        end,

        ["helm_ls"] = function()
          require("lspconfig").helm_ls.setup {
            capabilities = lsp_capabilities,
            filetypes = {"helm"},
            cmd = {"helm_ls", "serve"}
          }
        end,

        -- ["ruff_lsp"] = function()
        --   require("lspconfig")["ruff_lsp"].setup {
        --     capabilities = lsp_capabilities,
        --     on_init = function(client)
        --       client.server_capabilities.hoverProvider = false
        --       client.config.interpreter = get_python_path(client.config.root_dir)
        --     end
        --   }
        -- end,

        ["rust_analyzer"] = function()
          require("rust-tools").setup {
            tools = {
              runnables = {
                use_telescope = true
              },
              inlay_hints = {
                auto = true,
                show_parameter_hints = false,
                parameters_hints_prefix = "",
                other_hints_prefix = "",
              }
            },
            server = {
              capabilities = lsp_capabilities,
              settings = {
                ["rust-analyzer"] = {
                  checkOnSave = {
                    command = "clippy"
                  }
                }
              }
            }
          }
        end
      }
    end
  },
  {
    "jay-babu/mason-null-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "nvimtools/none-ls.nvim"
    },
    config = function()
      require("mason-null-ls").setup {
        ensure_installed = {
          -- -- Linter
          -- "actionlint",
          -- "curlylint",
          -- -- "pyproject-flake8",
          -- "hadolint",
          -- "jsonlint",
          -- -- "markdownlint",
          -- "misspell",
          -- "revive",
          -- "rstcheck",
          -- "ruff",
          -- "selene",
          -- "sqlfluff",
          -- "tflint",
          -- "tfsec",
          -- -- "yamllint",
          -- -- Formatter
          -- "black",
          -- "isort",
          -- "rustfmt",
          -- "shfmt",
          -- "sqlfmt",
          -- "stylua",
          -- "yamlfmt"
        },
        automatic_installation = false,
        handlers = {
        }
      }
    end
  },
  {
    "nvimtools/none-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local null_ls = require "null-ls"
      null_ls.setup {
        sources = {
          null_ls.builtins.code_actions.refactoring,
        }
      }
    end
  },
  {
    "williamboman/mason.nvim",
    build = function()
      pcall(vim.cmd, "MasonUpdate")
    end,
    config = true
  }
}
