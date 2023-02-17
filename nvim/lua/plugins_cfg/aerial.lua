-- Aerial Configuration
require('aerial').setup({
  backends = { "treesitter", "lsp", "markdown" },
  filter_kind = false,
  nerd_font = "auto",
  on_attach = function (client, bufnr)
    -- Aerial does not set any mappings by default, so you'll want to set some up
    -- Toggle the aerial window with <leader>a
    vim.api.nvim_buf_set_keymap(0, 'n', '<leader>a', '<cmd>AerialToggle!<CR>', {})
    -- Jump forwards/backwards with '{' and '}'
    vim.api.nvim_buf_set_keymap(0, 'n', '{', '<cmd>AerialPrev<CR>', {})
    vim.api.nvim_buf_set_keymap(0, 'n', '}', '<cmd>AerialNext<CR>', {})
    -- Jump up the tree with '[[' or ']]'
    vim.api.nvim_buf_set_keymap(0, 'n', '[[', '<cmd>AerialPrevUp<CR>', {})
    vim.api.nvim_buf_set_keymap(0, 'n', ']]', '<cmd>AerialNextUp<CR>', {})
  end
})

