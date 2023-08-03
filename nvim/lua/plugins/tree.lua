vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1


return {
  "nvim-tree/nvim-tree.lua",
  lazy = false,
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local api = require "nvim-tree.api"
    local tree = require "nvim-tree"

    -- ------------------------------------------------------------------------
    -- Open Nvim Tree on Startup
    -- ------------------------------------------------------------------------
    local function open_nvim_tree(data)
      local IGNORED_FT = {
        "dashboard"
      }

      if not vim.tbl_contains(IGNORED_FT, vim.bo[data.buf].ft) then
        return
      end

      api.tree.toggle({ focus = false })
    end

    vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })
    -- ------------------------------------------------------------------------

    -- ------------------------------------------------------------------------
    -- OnAttach Definition
    -- ------------------------------------------------------------------------
    local function on_attach(bufnr)
      local function opts(desc)
        return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
      end

      api.config.mappings.default_on_attach(bufnr)
    end
    -- ------------------------------------------------------------------------

    tree.setup {
      sync_root_with_cwd = true,
      respect_buf_cwd = true,
      update_focused_file = {
        enable = true,
        update_root = true
      },
      on_attach = on_attach,
      open_on_tab = false,
      actions = {
        open_file = {
          quit_on_open = false,
          window_picker = {
            enable = true,
            exclude = {
              -- filetype = { "" }
              buftype = { "terminal" }
            }
          }
        }
      },
      renderer = {
        add_trailing = true,
        highlight_git = false,
        highlight_opened_files = "name",
        highlight_modified = "icon",
        indent_markers = {
          enable = true
        }
      },
      modified = {
        enable = true
      },
      hijack_directories = {
        enable = true,
        auto_open = true
      },
      diagnostics = {
        enable = true,
        icons = {
          hint = "",
          info = "",
          warning = "",
          error = "",
        }
      },
      view = {
        width = "20%",
        side = "left"
      },
      filters = {
        dotfiles = false,
        custom = { ".git", "node_modules", ".cache", "__pycache__" },
        exclude = { ".github", ".gitignore", "env", ".env" }
      }
    }
  end,
  keys = {
    { "<leader>nt", "<CMD>NvimTreeToggle<CR>", desc = "Toggle NvimTree" }
  }
}
