return {
  "snacks.nvim",
  opts = {
    picker = {
      matcher = {
        fuzzy = true,
        smartcase = true,
        ignorecase = true,
        frecency = true,
        filename_bonus = true,
        file_pos = true,
        cwd_bonus = true,
        sort_empty = true,
        history_bonus = false,
      },

      layout = {
        preset = "default",
        preview = {
          width = 0.5,
          border = "single"
        }
      },

      prompt = " ",
      focus = "input",
      show_delay = 5000,
      limit_live = 10000,
      ui_select = true,
      auto_close = true,

      sources = {
        file = {
          hidden = true,
          follow = true,
        },
        grep = {
          hidden = true,
        },
        buffers = {
          sort_mru = true,
        }
      }
    }
  },

  keys = {
    {
      "<leader><leader>",
      function() require("snacks").picker.smart() end,
      desc = "Smart Find (buffers + recent + files)"
    },
    {
      "<leader>ff",
      function() require("snacks").picker.files() end,
      desc = "Find Files"
    },
    {
      "<leader>fr",
      function() require("snacks").picker.recent() end,
      desc = "Recent Files"
    },
    {
      "<leader>fb",
      function() require("snacks").picker.buffers() end,
      desc = "Buffers"
    },

    {
      "<leader>sg",
      function() require("snacks").picker.grep() end,
      desc = "Grep (Live Search)"
    },
    {
      "<leader>sw",
      function() require("snacks").picker.grep_word() end,
      desc = "Grep Word Under Cursor"
    },
    {
      "<leader>sb",
      function() require("snacks").picker.grep_buffers() end,
      desc = "Grep Open Buffers"
    },
    {
      "<leader>sl",
      function() require("snacks").picker.lines() end,
      desc = "Search Lines (Current Buffer)"
    },

    {
      "<leader>gs",
      function() require("snacks").picker.git_status() end,
      desc = "Git Status (Picker)"
    },
    {
      "<leader>gc",
      function() require("snacks").picker.git_log() end,
      desc = "Git Commits (Log)"
    },
    {
      "<leader>gC",
      function() require("snacks").picker.git_log_file() end,
      desc = "Git Commits (Current File)"
    },
    {
      "<leader>gL",
      function() require("snacks").picker.git_log_line() end,
      desc = "Git Commits (Current Line)"
    },
    {
      "<leader>gp",
      function() require("snacks").picker.git_branches() end,
      desc = "Git Branches"
    },
    {
      "<leader>gD",
      function() require("snacks").picker.git_diff() end,
      desc = "Git Diff (Picker)"
    },
    {
      "<leader>gS",
      function() require("snacks").picker.git_stash() end,
      desc = "Git Stash"
    },

    {
      "gd",
      function() require("snacks").picker.lsp_definitions() end,
      desc = "Go to Definition (Picker)"
    },
    {
      "gr",
      function() require("snacks").picker.lsp_references() end,
      desc = "References (Picker)"
    },
    {
      "gi",
      function() require("snacks").picker.lsp_implementations() end,
      desc = "Implementations (Picker)"
    },
    {
      "gD",
      function() require("snacks").picker.lsp_declarations() end,
      desc = "Declarations (Picker)"
    },
    {
      "gT",
      function() require("snacks").picker.lsp_type_definitions() end,
      desc = "Declarations (Picker)"
    },
    {
      "<leader>cs",
      function() require("snacks").picker.lsp_symbols() end,
      desc = "LSP Syumbols (Buffer)"
    },
    {
      "<leader>cS",
      function() require("snacks").picker.lsp_workspace_symbols() end,
      desc = "LSP Symbols (Workspace)"
    },

    {
      "<leader>xx",
      function() require("snacks").picker.diagnostics() end,
      desc = "Diagnostics (Workspace)"
    },
    {
      "<leader>xb",
      function() require("snacks").picker.diagnostics_buffer() end,
      desc = "Diagnostics (Buffer)"
    },


    {
      "<leader>xq",
      function() require("snacks").picker.qflist() end,
      desc = "Quickfix List"
    },
    {
      "<leader>xl",
      function() require("snacks").picker.loclist() end,
      desc = "Location List"
    },

    {
      "<leader>fh",
      function() require("snacks").picker.help() end,
      desc = "Help"
    },
    {
      "<leader>fk",
      function() require("snacks").picker.keymaps() end,
      desc = "Keymaps"
    },
    {
      "<leader>fu",
      function() require("snacks").picker.undo() end,
      desc = "Undo History"
    },
    {
      "<leader>fR",
      function() require("snacks").picker.registers() end,
      desc = "Registers"
    },

  }
}
