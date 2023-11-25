return {
  {
    "vim-test/vim-test",
    keys = {
      { "<leader>rtc", "<cmd>w|TestClass<cr>", desc = "Class" },
      { "<leader>rtf", "<cmd>w|TestFile<cr>", desc = "File" },
      { "<leader>rtl", "<cmd>w|TestLast<cr>", desc = "Last" },
      { "<leader>rtn", "<cmd>w|TestNearest<cr>", desc = "Nearest" },
      { "<leader>rts", "<cmd>w|TestSuite<cr>", desc = "Suite" },
      { "<leader>rtv", "<cmd>w|TestVisit<cr>", desc = "Visit" },
    },
    config = function()
      vim.api.nvim_exec([[
      function! FloatermSplit(cmd)
        execute 'FloatermNew --wintype=split --height=0.3 --autoclose=0 '.a:cmd
      endfunction

      let g:test#custom_strategies = {'floaterm_split': function('FloatermSplit')}
      ]], false)
      vim.g["test#strategy"] = "floaterm_split"
      vim.g["test#python#runner"] = "pytest" -- pytest
    end,
  },
  {
    "nvim-neotest/neotest",
    keys = {
      { "<leader>rNF", "<cmd>w|lua require('neotest').run.run({vim.fn.expand('%'), strategy = 'dap'})<cr>", desc = "Debug File" },
      { "<leader>rNL", "<cmd>w|lua require('neotest').run.run_last({strategy = 'dap'})<cr>", desc = "Debug Last" },
      { "<leader>rNa", "<cmd>w|lua require('neotest').run.attach()<cr>", desc = "Attach" },
      { "<leader>rNf", "<cmd>w|lua require('neotest').run.run(vim.fn.expand('%'))<cr>", desc = "File" },
      { "<leader>rNl", "<cmd>w|lua require('neotest').run.run_last()<cr>", desc = "Last" },
      { "<leader>rNn", "<cmd>w|lua require('neotest').run.run()<cr>", desc = "Nearest" },
      { "<leader>rNN", "<cmd>w|lua require('neotest').run.run({strategy = 'dap'})<cr>", desc = "Debug Nearest" },
      { "<leader>rNo", "<cmd>w|lua require('neotest').output.open({ enter = true })<cr>", desc = "Output" },
      { "<leader>rNs", "<cmd>w|lua require('neotest').run.stop()<cr>", desc = "Stop" },
      { "<leader>rNS", "<cmd>w|lua require('neotest').summary.toggle()<cr>", desc = "Summary" },
    },
    dependencies = {
      "vim-test/vim-test",
      "nvim-neotest/neotest-python",
      "nvim-neotest/neotest-plenary",
      "nvim-neotest/neotest-vim-test",
      "rouge8/neotest-rust",
      "linux-cultist/venv-selector.nvim"
    },
    config = function()
      local opts = {
        adapters = {
          require "neotest-python" {
            dap = { justMyCode = false },
            runner = "pytest"
          },
          require "neotest-plenary",
          require "neotest-vim-test" {
            ignore_file_types = { "python", "vim", "lua" },
          },
          require "neotest-rust",
        },
        floating = {
          max_height = 0.8,
          max_width = 0.7,
        },
        icons = {
          child_indent = "│",
          child_prefix = "├",
          collapsed = "─",
          expanded = "┐",
          failed = "",
          final_child_indent = " ",
          final_child_prefix = "└",
          non_collapsible = "─",
          passed = "",
          running = "",
          running_animated = { "/", "|", "\\", "-", "/", "|", "\\", "-" },
          skipped = "",
          unknown = ""
        },
        -- overseer.nvim
        consumers = {
          overseer = require "neotest.consumers.overseer",
        },
        overseer = {
          enabled = true,
          force_default = true,
        },
      }
      require("neotest").setup(opts)
    end,
  },
  {
    "stevearc/overseer.nvim",
    keys = {
      { "<leader>roR", "<cmd>OverseerRunCmd<cr>", desc = "Run Command" },
      { "<leader>roa", "<cmd>OverseerTaskAction<cr>", desc = "Task Action" },
      { "<leader>rob", "<cmd>OverseerBuild<cr>", desc = "Build" },
      { "<leader>roc", "<cmd>OverseerClose<cr>", desc = "Close" },
      { "<leader>rod", "<cmd>OverseerDeleteBundle<cr>", desc = "Delete Bundle" },
      { "<leader>rol", "<cmd>OverseerLoadBundle<cr>", desc = "Load Bundle" },
      { "<leader>roo", "<cmd>OverseerOpen<cr>", desc = "Open" },
      { "<leader>roq", "<cmd>OverseerQuickAction<cr>", desc = "Quick Action" },
      { "<leader>ror", "<cmd>OverseerRun<cr>", desc = "Run" },
      { "<leader>ros", "<cmd>OverseerSaveBundle<cr>", desc = "Save Bundle" },
      { "<leader>rot", "<cmd>OverseerToggle<cr>", desc = "Toggle" },
    },
    config = true,
  },
}
