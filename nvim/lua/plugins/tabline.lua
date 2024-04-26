return {
  {
    "nanozuki/tabby.nvim",
    event = "VimEnter",
    dependencies = { "tiagovla/scope.nvim" },
    config = function()
      require("tabby").setup {}
      function tab_name(tab)
         return string.gsub(tab,"%[..%]","")
      end


      function tab_modified(tab)
          wins = require("tabby.module.api").get_tab_wins(tab)
          for i, x in pairs(wins) do
              if vim.bo[vim.api.nvim_win_get_buf(x)].modified then
                  return ""
              end
          end
          return ""
      end

      function lsp_diag(buf)
          diagnostics = vim.diagnostic.get(buf)
          local count = {0, 0, 0, 0}

          for _, diagnostic in ipairs(diagnostics) do
              count[diagnostic.severity] = count[diagnostic.severity] + 1
          end
          if count[1] > 0 then
              return vim.bo[buf].modified and "" or ""
          elseif count[2] > 0 then
              return vim.bo[buf].modified and "" or ""
          end
          return vim.bo[buf].modified and "" or ""
      end

      local function get_modified(buf)
          if vim.bo[buf].modified then
              return ''
          else
              return ''
          end
      end

      local function buffer_name(buf)
          if string.find(buf,"NvimTree") then
              return "NvimTree"
          end
          return buf
      end

      local theme = {
        fill = 'TabLineFill',
        -- Also you can do this: fill = { fg='#f2e9de', bg='#907aa9', style='italic' }
        head = 'TabLine',
        -- head = 'TabLineHead',
        current_tab = 'TabLineSel',
        -- inactive_tab = 'TabLineIn',
        inactive_tab = 'TabLine',
        tab = 'TabLine',
        win = 'TabLine',
        tail = 'TabLine',
      }
      require('tabby.tabline').set(function(line)
        return {
          {
            { '  ', hl = theme.head },
            line.sep('', theme.head, theme.fill),
          },
          line.tabs().foreach(function(tab)
            local hl = tab.is_current() and theme.current_tab or theme.inactive_tab
            return {
              line.sep('', hl, theme.fill),
              tab.number(),
              "",
              tab_name(tab.name()),
              "",
              tab_modified(tab.id),
              line.sep('', hl, theme.fill),
              hl = hl,
              margin = ' ',
            }
          end),
          line.spacer(),
          line.wins_in_tab(line.api.get_current_tab()).foreach(function(win)
            local hl = win.is_current() and theme.current_tab or theme.inactive_tab
            return {
              line.sep('', hl, theme.fill),
              win.file_icon(),
              "",
              buffer_name(win.buf_name()),
              "",
              lsp_diag(win.buf().id),
              line.sep('', hl, theme.fill),
              hl = hl,
              margin = ' ',
            }
          end),
          {
            line.sep('', theme.tail, theme.fill),
            { '  ', hl = theme.tail },
          },
          hl = theme.fill,
        }
      end)
    end,
    keys = {
      -- { "<leader><space>", "<cmd>tabclose<cr>", desc = "Close Tab Workspace" },
      -- Go to tab # number
    }
  },
  {
    "tiagovla/scope.nvim",
    enabled = false,
    config = true
  }
}
