  -- Using prettier for now for MDX
vim.api.nvim_create_autocmd("FileType", {
  pattern = "mdx",
  callback = function()
    vim.bo.formatprg = "prettier --stdin-filepath " .. vim.fn.expand("%")
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.mdx" },
  callback = function()
    vim.cmd("silent! normal! gggqG")
    vim.cmd("silent! write")
  end,
  desc = "Format MDX with Prettier on save",
})
