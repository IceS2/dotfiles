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
      -- ----------------------------------------------------------------------
      -- Fixing Pyright way for working with pyenv-virtualenv
      -- ----------------------------------------------------------------------
      local util = require('lspconfig/util')
      local path = util.path

      local function get_python_path(workspace)
        -- Use activated virtualenv.
        if vim.env.VIRTUAL_ENV then
          return path.join(vim.env.VIRTUAL_ENV, 'bin', 'python')
        end

        -- Find and use virtualenv in workspace directory.
        for _, pattern in ipairs({'*', '.*'}) do
          local match = vim.fn.glob(
            path.join(workspace, pattern, '.python-local'))
          if match ~= '' then
            return path.join(
              vim.env.PYENV_ROOT,
              'versions',
              path.dirname(match),
              'bin',
              'python')
          end
        end

        -- Fallback to system Python.
        return exepath('python3') or exepath('python') or 'python'
      end

      local function get_venv(workspace)
        for _, pattern in ipairs({'*', '.*'}) do
          local match = vim.fn.glob(path.join(workspace, pattern, '.python-local'))
          if match ~= '' then
            return match
          end
        end
      end
      -- ----------------------------------------------------------------------

      local lsp_capabilities = require("cmp_nvim_lsp").default_capabilities()
      lsp_capabilities.textDocument.foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true
      }

      -- local lsp_attach = function(client, bufnr)
      -- end
      --
      -- require("mason").setup()

      require("mason-lspconfig").setup {
        ensure_installed = {
          "bashls",                                     -- Bash
          "cssls",                                      -- CSS
          "cssmodules_ls",                              -- CSS Modules
          "dockerls",                                   -- Docker
          "docker_compose_language_service",            -- Docker Compose
          "gopls",                                      -- Go
          "graphql",                                    -- GraphQL
          "helm_ls",
          "html",                                       -- HTML
          "jsonls",                                     -- JSON
          "tsserver",                                   -- TypeScript/JavaScript
          "kotlin_language_server",                     -- Kotlin
          "lua_ls",                                     -- Lua
          "marksman",                                   -- Markdown
          "pyright",                                    -- Python
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

        ["pyright"] = function()
          require("lspconfig").pyright.setup {
            capabilities = lsp_capabilities,
            on_init = function(client)
              client.config.settings.python.pythonPath = get_python_path(client.config_root_dir)
              client.config.settings.venvPath = path.join(vim.env.PYENV_ROOT, 'versions')
              client.config.settings.venv = get_venv(client.config.root_dir)
            end
          }
        end,

        ["ruff_lsp"] = function()
          require("lspconfig")["ruff_lsp"].setup {
            capabilities = lsp_capabilities,
            on_init = function(client)
              client.server_capabilities.hoverProvider = false
              client.config.interpreter = get_python_path(client.config.root_dir)
            end
          }
        end,

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
      "jose-elias-alvarez/null-ls.nvim"
    },
    config = function()
      require("mason-null-ls").setup {
        ensure_installed = {
          -- Linter
          "actionlint",
          "curlylint",
          -- "pyproject-flake8",
          "hadolint",
          "jsonlint",
          -- "markdownlint",
          "misspell",
          "revive",
          "rstcheck",
          "ruff",
          "selene",
          "sqlfluff",
          "tflint",
          "tfsec",
          -- "yamllint",
          -- Formatter
          "black",
          "isort",
          "rustfmt",
          "shfmt",
          "sqlfmt",
          "stylua",
          "yamlfmt"
        },
        automatic_installation = false,
        handlers = {
        }
      }
    end
  },
  {
    "jose-elias-alvarez/null-ls.nvim",
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
