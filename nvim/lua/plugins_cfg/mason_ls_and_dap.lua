require("mason").setup()

-------------------------------------------------------------------------------
---- LSP
-------------------------------------------------------------------------------
require("mason-lspconfig").setup {
  ensure_installed = {
    "cssls",                                      -- CSS
    "dockerls",                                   -- Docker
    "docker_compose_language_service",            -- Docker Compose
    "gopls",                                      -- Go
    "graphql",                                    -- GraphQL
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


-- Fixing Pyright way for working with pyenv-virtualenv
local configs = require('lspconfig/configs')
local util = require('lspconfig/util')
local path = util.path

local function get_python_path(workspace)
  -- Use activated virtualenv.
  if vim.env.VIRTUAL_ENV then
    return path.join(vim.env.VIRTUAL_ENV, 'bin', 'python')
  end

  -- Find and use virtualenv in workspace directory.
  for _, pattern in ipairs({'*', '.*'}) do
    local match = vim.fn.glob(path.join(workspace, pattern, '.python-local'))
    if match ~= '' then
      return path.join(vim.env.PYENV_ROOT, 'versions', path.dirname(match), 'bin', 'python')
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

-- Setup LSP Handlers
local lsp_defaults = require("lspconfig").util.default_config
lsp_defaults.capabilities = vim.tbl_deep_extend(
  'force',
  lsp_defaults.capabilities,
  require('cmp_nvim_lsp').default_capabilities()
)

require("mason-lspconfig").setup_handlers {

  function(server_name)
    require("lspconfig")[server_name].setup {}
  end,

  ["pyright"] = function()
    require("lspconfig").pyright.setup {
      on_init = function(client)
        client.config.settings.python.pythonPath = get_python_path(client.config.root_dir)
        client.config.settings.venvPath = path.join(vim.env.PYENV_ROOT, 'versions')
        client.config.settings.venv = get_venv(client.config.root_dir)
      end
    }
  end,

  ["ruff_lsp"] = function()
    require("lspconfig")["ruff_lsp"].setup {
      on_init = function(client)
        client.config.interpreter = get_python_path(client.config.root_dir)
      end
    }
  end,

  ["rust_analyzer"] = function()
    require("rust-tools").setup {}
  end
}
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
---- Null LS
-------------------------------------------------------------------------------
require("mason-null-ls").setup({
  automatic_setup = true
})
require("null-ls").setup()


require("mason-null-ls").setup_handlers()
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
---- DAP
-------------------------------------------------------------------------------
require("mason-nvim-dap").setup({
  ensure_installed = {
    "python",
    "cppdbg"
  },
  automatic_setup = {
    configurations = function(default)
      default.python[1].justMyCode = false
      return default
    end
  }
})

-- Setup DAP Handlers
require 'mason-nvim-dap'.setup_handlers {
}

-- Setup DAP UI
require("neodev").setup({
  library = { plugins = { "nvim-dap-ui" }, types = true }
})

require("dapui").setup {}
-------------------------------------------------------------------------------
