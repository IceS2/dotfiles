local present, cmp = pcall(require, "cmp")
if not present then
  return
end

local lspkind = require('lspkind')

cmp.setup {
  formatting = {
    format = lspkind.cmp_format({
      mode = 'symbol_text',
      maxwidth = 50,
      ellipsis_char = '...'
    })
  },
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered()
  },
  mapping = {
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.close(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<Tab>"] = function(fallback)
      if cmp.visible() then
         cmp.select_next_item()
      -- elseif require("luasnip").expand_or_jumpable() then
         -- vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-expand-or-jump", true, true, true), "")
      else
         fallback()
      end
    end,
    ["<S-Tab>"] = function(fallback)
      if cmp.visible() then
         cmp.select_prev_item()
      -- elseif require("luasnip").jumpable(-1) then
         -- vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-jump-prev", true, true, true), "")
      else
         fallback()
      end
    end,
  },
  sources = {
    { name = "luasnip" },
    { name = "buffer" },
    { name = "path" },
    { name = "nvim_lsp" },
    { name = "nvim_lua" },
    { name = "nvim_lsp_signature_help"}
  },
}
