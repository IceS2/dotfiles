-- TODO:
return{
  {
    "hrsh7th/nvim-cmp",
    lazy = false,
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-nvim-lsp-signature-help",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-cmdline",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-nvim-lua",
      "onsails/lspkind-nvim",
      "saadparwaiz1/cmp_luasnip",
      "zbirenbaum/copilot-cmp"
    },
    config = function()
      local cmp = require "cmp"
      local luasnip = require "luasnip"
      local lspkind = require "lspkind"

      local has_words_before = function()
        if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then return false end
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_text(0, line-1, 0, line-1, col, {})[1]:match("^%s*$") == nil
      end

      cmp.setup {
        mapping = {}
      }

      cmp.setup {
        completion = {
          completeopt = "menu,menuone,noselect,preview"
        },
        preselect = cmp.PreselectMode.None,
        formatting = {
          format = lspkind.cmp_format({
            mode = 'symbol_text',
            maxwidth = 50,
            ellipsis_char = '...',
            symbol_map = {
              Copilot = ""
            },
            menu = ({
              luasnip = "[LuaSnip]",
              buffer = "[Buffer]",
              path = "[Path]",
              nvim_lsp = "[LSP]",
              nvim_lsp_signature_help = "[Signature]",
              nvim_lua = "[Lua]",
              neorg = "[Neorg]",
              copilot = "[Copilot]"
            })
          })
        },
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered()
        },
        mapping = {
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = false }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() and has_words_before() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, {
            "i",
            "s",
            "c"
          }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() and has_words_before() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, {
            "i",
            "s",
            "c"
          }),
        },
        sources = {
          { name = "nvim_lsp_signature_help" },
          { name = "nvim_lsp" },
          { name = "nvim_lua" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
          { name = "neorg" },
          { name = "copilot", group_index = 2 }
        }
      }
      -- Use buffer source for `/`
      cmp.setup.cmdline("/", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
      })

      -- Use cmdline & path source for ':'
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" },
        }),
      })
    end
  },
  -- TODO:
  -- Understand
  -- how to
  -- use
  -- luasnip
  {
    "L3MON4D3/LuaSnip",
    event = "VeryLazy",
    dependencies = {
      "rafamadriz/friendly-snippets",
      config = function()
        require("luasnip.loaders.from_vscode").lazy_load()
      end
    },
    config = {
      history = true,
      delete_check_events = "TextChanged",
    },
    -- keys = {
      -- {
      --   "<tab>",
      --   function()
      --     return require("luasnip").jumpable(1) and "<Plug>luasnip-jump-next" or "<tab>"
      --   end,
      --   expr = true, remap = true, silent = true, mode = "i",
      -- },
      -- { "<tab>", function() require("luasnip").jump(1) end, mode = "s" },
      -- { "<s-tab>", function() require("luasnip").jump(-1) end, mode = { "i", "s" } },
    -- },
  },
  {
    "zbirenbaum/copilot-cmp",
    lazy = "VeryLazy",
    dependencies = {
      "zbirenbaum/copilot.lua",
      config = function()
        require("copilot").setup {
          suggestion = { enabled = false },
          panel = { enabled = false }
        }
      end
    },
    config = function()
      require("copilot_cmp").setup(nil)
    end
  }
}
