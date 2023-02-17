local present, nvimtree = pcall(require, "nvim-tree")
if not present then
    return
end
local tree_cb = require"nvim-tree.config".nvim_tree_callback

-- Set alias for vim.g.
local g = vim.g

local function open_nvim_tree()
  local IGNORED_FT = {
    "dashboard"
  }

  if vim.tbl_contains(IGNORED_FT, filetype) then
    return
  end

  require("nvim-tree.api").tree.toggle({ focus = false })
end

nvimtree.setup {
  open_on_tab = false,
  actions = {
    open_file = {
      quit_on_open = false,
      window_picker = {
        enable = true,
        exclude = {
          filetype = { "packer", "vista_kind" },
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
    auto_open = true,
  },
  update_focused_file = {
    enable = true,
    update_root = false
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
    side = "left",
    mappings = {
      list = {
       {key = "<S-h>", cb = ":call ResizeLeft(3)<CR>"},
       {key = "<C-h>", cb = tree_cb("toggle_dotfiles")},
      }
    }
  },
  filters = {
    dotfiles = false,
    custom = { ".git", "node_modules", ".cache", "__pycache__" },
    exclude = { ".github", ".gitignore", "env"}
  }
}

vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })
