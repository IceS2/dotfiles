local present, nvimtree = pcall(require, "nvim-tree")
if not present then
    return
end
local tree_cb = require"nvim-tree.config".nvim_tree_callback

-- Set alias for vim.g.
local g = vim.g

nvimtree.setup {
  ignore_ft_on_setup = { "dashboard" },
  open_on_tab = false,
  actions = {
    open_file = {
      quit_on_open = false,
      -- resize_window = true,
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
    highlight_opened_files = "all",
    indent_markers = {
      enable = true
    }
  },
  hijack_directories = {
    enable = true,
    auto_open = true,
  },
  update_focused_file = {
    enable = true,
    update_root = true
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
    custom = { ".git", "node_modules", ".cache", "__pycache__" }
  }
}
