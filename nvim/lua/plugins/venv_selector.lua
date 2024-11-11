return {
  "linux-cultist/venv-selector.nvim",
  branch = "regexp",
  event = "VeryLazy",
  dependencies = { "neovim/nvim-lspconfig", "nvim-telescope/telescope.nvim" },
  config = function()
    require("venv-selector").setup {
      search_venv_managers = true,
      search_workspaces = true,
      search = true,
      name = {"venv", ".venv", "env", ".env"},
      parents = 2,
      poetry_path = "",
      pipenv_path = "",
      fd_binary_name = "fd",
    }
  end,
  keys = {
    {"<leader>cv", "<CMD>VenvSelect<CR>", desc = "Select Virtualenv"}
  }
}
