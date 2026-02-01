  vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = { "*.js", "*.jsx", "*.ts", "*.tsx", "*.astro", "*.json", "*.jsonc" },
    callback = function()
      vim.lsp.buf.format({
        async = false,
        filter = function(client)
          return client.name == "biome"
        end
      })
    end,
    desc = "Format with Biome on save",
  })

  -- Using prettier for now for MDX
  vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = { "*.mdx" },
    callback = function()
      vim.lsp.buf.format({
        async = false,
        filter = function(client)
          return client.name == "prettier"
        end
      })
    end,
    desc = "Format MDX with Prettier on save",
  })
