return {
  "saghen/blink.cmp",
  version = "1.*",
  enabled = function()
    local disabled_fts = { "dap-repl", "dapui_watches", "dapui_hover" }
    return not vim.tbl_contains(disabled_fts, vim.bo.filetype)
  end,
  event = { "InsertEnter", "CmdlineEnter" },
  dependencies = {
    "echasnovski/mini.icons",
  },
  opts_extend = { "sources.default" },
  opts = {
    keymap = {
      preset = "default",
      ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
      ["<C-e>"] = { "hide" },
      ["<CR>"] = { "accept", "fallback" },
      ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
      ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
      ["<C-b>"] = { "scroll_documentation_up", "fallback" },
      ["<C-f>"] = { "scroll_documentation_down", "fallback" },
    },
    appearance = {
      nerd_font_variant = "mono"
    },
    sources = {
      default = { "lsp", "path", "buffer" }
    },
    completion = {
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 500,
        treesitter_highlighting = true,
        window = {
          min_width = 10,
          max_width = 60,
          max_height = 20,
          border = "single",
          scrollbar = true,
        }
      },
      list = {
        selection = {
          preselect = true,
        }
      },
      ghost_text = {
        enabled = true
      },
      menu = {
        auto_show = true,
        border = "single",
        draw = {
          treesitter = { "lsp" },
          columns = {
            { "kind_icon" },
            { "label", "label_description", gap = 1 },
            { "kind" },
            { "source_name" ,}
          },
          components = {
            source_name = {
              text = function(ctx)
                return "[" .. ctx.source_name .. "]"
              end
            },
            kind_icon = {
              text = function(ctx)
                local MiniIcons = require("mini.icons")
                if ctx.source_name == "Path" then
                  if ctx.label:match("/$") then
                      local kind_icon, _, _ = MiniIcons.get("directory", ctx.label)
                      return kind_icon
                  end
                  local kind_icon, _, _ = MiniIcons.get("file", ctx.label)
                  return kind_icon
                end
                local kind_icon, _, _ = MiniIcons.get('lsp', ctx.kind)
                return kind_icon
              end,

              highlight = function(ctx)
                local MiniIcons = require("mini.icons")
                if ctx.source_name == "Path" then
                  if ctx.label:match("/$") then
                      local _, hl, _ = MiniIcons.get("directory", ctx.label)
                      return hl
                  end
                  local _, hl, _ = MiniIcons.get("file", ctx.label)
                  return hl
                end
                local _, hl, _ = MiniIcons.get('lsp', ctx.kind)
                return hl
              end,
            },
            kind = {
              highlight = function(ctx)
                local MiniIcons = require("mini.icons")
                if ctx.source_name == "Path" then
                  if ctx.label:match("/$") then
                      local _, hl, _ = MiniIcons.get("directory", ctx.label)
                      return hl
                  end
                  local _, hl, _ = MiniIcons.get("file", ctx.label)
                  return hl
                end
                local _, hl, _ = MiniIcons.get('lsp', ctx.kind)
                return hl
              end,
            }
          },
        }
      }
    },
    signature = {
      enabled = false,
    },
    cmdline = {
      keymap = {
        preset = "inherit",
      },
      completion = {
        ghost_text = {
          enabled = true,
        },
      },
    }
  }
}
