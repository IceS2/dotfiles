return {
  -- Core DAP
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      -- UI
      {
        "rcarriga/nvim-dap-ui",
        dependencies = { "nvim-neotest/nvim-nio" },
        keys = {
          { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
          { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = { "n", "v" } },
        },
        config = function()
          local dap = require("dap")
          local dapui = require("dapui")
          dapui.setup()
          dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
          dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
          dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
        end,
      },
      -- Virtual text (inline variable values while debugging)
      {
        "theHamsta/nvim-dap-virtual-text",
        opts = { commented = true },
      },
    },
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, desc = "Conditional Breakpoint" },
      { "<leader>dc", function() require("dap").continue() end, desc = "Continue" },
      { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
      { "<leader>do", function() require("dap").step_out() end, desc = "Step Out" },
      { "<leader>dO", function() require("dap").step_over() end, desc = "Step Over" },
      { "<leader>dj", function() require("dap").down() end, desc = "Down (Stack Frame)" },
      { "<leader>dk", function() require("dap").up() end, desc = "Up (Stack Frame)" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
      { "<leader>dP", function() require("dap").pause() end, desc = "Pause" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },
    },
    config = function()
      -- Breakpoint signs
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◉", texthl = "DiagnosticWarn" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DiagnosticInfo" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "DapStoppedLine" })

      -- Highlight for current stopped line
      vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

      local dap = require("dap")

      -- JS/TS adapters (js-debug-adapter via Mason)
      dap.adapters["pwa-node"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = "js-debug-adapter",
          args = { "${port}" },
        },
      }

      dap.adapters["pwa-chrome"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = "js-debug-adapter",
          args = { "${port}" },
        },
      }

      -- VSCode launch.json compatibility aliases
      dap.adapters["node"] = dap.adapters["pwa-node"]
      dap.adapters["chrome"] = dap.adapters["pwa-chrome"]

      -- JS/TS launch configurations
      local js_filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" }
      for _, ft in ipairs(js_filetypes) do
        dap.configurations[ft] = {
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch file",
            program = "${file}",
            cwd = "${workspaceFolder}",
            sourceMaps = true,
            skipFiles = { "<node_internals>/**", "node_modules/**" },
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach to process",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
            sourceMaps = true,
            skipFiles = { "<node_internals>/**", "node_modules/**" },
          },
          {
            type = "pwa-chrome",
            request = "launch",
            name = "Launch Chrome",
            url = "http://localhost:4321",
            webRoot = "${workspaceFolder}/src",
            sourceMaps = true,
          },
        }
      end
    end,
  },

  -- Python DAP
  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
      require("dap-python").setup("uv")
      require("dap-python").test_runner = "pytest"
    end,
    keys = {
      { "<leader>dpt", function() require("dap-python").test_method() end, desc = "Debug Test Method", ft = "python" },
      { "<leader>dpc", function() require("dap-python").test_class() end, desc = "Debug Test Class", ft = "python" },
      { "<leader>dps", function() require("dap-python").debug_selection() end, desc = "Debug Selection", ft = "python", mode = "v" },
    },
  },
}
