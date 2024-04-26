return {
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-fzf-native.nvim",
      "barrett-ruth/telescope-http.nvim",
      "AckslD/nvim-neoclip.lua",
      "LinArcX/telescope-env.nvim",
      "olacin/telescope-cc.nvim",
      "LukasPietzschmann/telescope-tabs",
      "benfowler/telescope-luasnip.nvim",
      "tsakirist/telescope-lazy.nvim",
      "nvim-telescope/telescope-dap.nvim",
      "stevearc/aerial.nvim",
      "aaronhallaert/advanced-git-search.nvim",
      "johmsalas/text-case.nvim"
    },
    config = function()
      local telescope = require "telescope"
      telescope.setup {
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case"
          },
          lazy = {
            show_icon = true
          },
          advanced_git_search = {
            diff_plugin = "diffview",
            show_builtin_git_pickets = false
          }
        }
      }
      telescope.load_extension("fzf")
      telescope.load_extension("http")
      telescope.load_extension("neoclip")
      telescope.load_extension("env")
      telescope.load_extension("conventional_commits")
      telescope.load_extension("telescope-tabs")
      telescope.load_extension("luasnip")
      telescope.load_extension("lazy")
      telescope.load_extension("workspaces")
      telescope.load_extension("dap")
      telescope.load_extension("aerial")
      telescope.load_extension("advanced_git_search")
      telescope.load_extension("textcase")
    end,
    keys = {
      -- Find Files
      { "<leader>f`", "<CMD>Telescope find_files cwd=~<CR>", desc = "Files from Home" },
      { "<leader>ff", "<CMD>Telescope find_files", desc = "Files" },
      { "<leader>fr", "<CMD>Telescope oldfiles<CR>", desc = "Recent" },

      -- Grep
      { "<leader>f/", "<CMD>Telescope live_grep<CR>", desc = "Grep" },

      -- List Tabs/Buffers
      { "<leader>ft", "<CMD>Telescope telescope-tabs list_tabs<CR>", desc = "Tabs" },
      { "<leader>fb", "<CMD>Telescope buffers<CR>", desc = "Buffers" },

      -- List Environment
      { "<leader>fe", "<CMD>Telescope env<CR>", desc = "Environment" },
        -- <c-a> Append Environment Value to Buffer
        -- <c-e> Edit Environment Value for the current Session

      -- List Workspaces
      { "<leader>fw", "<CMD>Telescope workspaces<CR>", desc = "Workspaces" },

      -- List TODOs
      { "<leader>fx", "<CMD>TodoTelescope<CR>", desc = "TODOs" },

      -- List KeyMaps
      { "<leader>fk", "<CMD>Telescope keymaps<CR>", desc = "Keymaps" },

      -- List HTTP Codes
      { "<leader>fh", "<CMD>Telescope http list<CR>", desc = "HTTP Codes" },

      -- List LSP References
      { "<leader>fr", "<CMD>Telescope lsp_references<CR>", desc = "LSP References" },

      -- Case Conversion
      { "<leader>fm", "<CMD>TextCaseOpenTelescope<CR>", desc = "Text Case Conversion" },

      -- Find on Register Unnamed
      { "<leader>fy", "<CMD>Telescope neoclip unnamed<CR>", desc = "Unnamed Register" },


      -- { "<leader>fg", "<CMD>Telescope git_files<CR>", desc = "Git Files" },
      -- { "<leader>fo", "<CMD>Telescope aerial<CR>", desc = "Code Outline" },
      -- { "<leader>fc", "<CMD>Telescope conventional_commits<CR>", desc = "Conventional Commits" },
      -- { <cmd>Telescope luasnip<CR> }
      -- { <cmd>Telescope lazy<CR> }
      -- { <cmd>Telescope dap<CR> }
      -- { <cmd>Telescope advanced_git_search diff_commit_file<CR> }
      -- { <cmd>Telescope advanced_git_search search_log_content<CR> }
    }
  },
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make"
  },
  {
    "AckslD/nvim-neoclip.lua",
    config = function()
      require("neoclip").setup {
        on_select = {
          move_to_front = true
        }
      }
    end
  },
  {
    "LukasPietzschmann/telescope-tabs",
    dependencies = { "nanozuki/tabby.nvim" },
    config = function()
      local tab_name = require "tabby.feature.tab_name"

      require("telescope-tabs").setup {
        entry_formatter = function(tab_id, _buffer_ids, _file_names, _file_paths, is_current)
            local name = tab_name.get(tab_id)
            return string.format("%d: %s%s", tab_id, name, is_current and " <" or "")
        end,
        entry_ordinal = function(tab_id, _buffer_ids, _file_names, _file_paths, _is_current)
          return tab_name.get(tab_id)
        end
      }
    end
  },
  {
    "stevearc/aerial.nvim",
    config = true
  }
}
