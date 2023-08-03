-- TODO:
return {
  {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = {
      "mfussenegger/nvim-dap",
      "williamboman/mason.nvim",
      "theHamsta/nvim-dap-virtual-text"
    },
    config = function()
      dap = require "mason-nvim-dap"
      dap.setup {
        ensure_installed = {
          "python",
          "codelldb"
        },
        handlers = {
          function(config)
            dap.default_setup(config)
          end,
          python = function(config)
            config.configurations[1].justMyCode = false
            dap.default_setup(config)
          end
        }
      }
    end,
    keys = {
      { "<leader>dR", function() require("dap").run_to_cursor() end, desc = "Run to Cursor", },
      { "<leader>dC", function() require("dap").set_breakpoint(vim.fn.input "[Condition] > ") end, desc = "Conditional Breakpoint", },
      { "<leader>db", function() require("dap").step_back() end, desc = "Step Back", },
      { "<leader>dc", function() require("dap").continue() end, desc = "Continue", },
      { "<leader>dd", function() require("dap").disconnect() end, desc = "Disconnect", },
      { "<leader>dg", function() require("dap").session() end, desc = "Get Session", },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step Into", },
      { "<leader>do", function() require("dap").step_over() end, desc = "Step Over", },
      { "<leader>dp", function() require("dap").pause.toggle() end, desc = "Pause", },
      { "<leader>dq", function() require("dap").close() end, desc = "Quit", },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL", },
      { "<leader>ds", function() require("dap").continue() end, desc = "Start", },
      { "<leader>dt", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint", },
      { "<leader>dx", function() require("dap").terminate() end, desc = "Terminate", },
      { "<leader>du", function() require("dap").step_out() end, desc = "Step Out", },
    },
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      "folke/neodev.nvim"
    },
    config = function()
      require("dapui").setup {}

      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end,
    keys = {
      { "<leader>dE", function() require("dapui").eval(vim.fn.input "[Expression] > ") end, desc = "Evaluate Input", },
      { "<leader>dU", function() require("dapui").toggle() end, desc = "Toggle UI", },
      { "<leader>de", function() require("dapui").eval() end, mode = {"n", "v"}, desc = "Evaluate", },
      { "<leader>dh", function() require("dap.ui.widgets").hover() end, desc = "Preview Variables", },
      { "<leader>dS", function() require("dap.ui.widgets").scopes() end, desc = "Scopes", },
    }
  },
  {
    "theHamsta/nvim-dap-virtual-text",
    config = function()
      require("nvim-dap-virtual-text").setup {
        commented = true
      }
    end
  }
}
