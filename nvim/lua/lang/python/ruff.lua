vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("disable_ruff_hover", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == "ruff" then
      client.server_capabilities.hoverProvider = false
    end
  end,
  desc = "Disable hover from Ruff (Use Ty instead)",
})

return {
  init_options = {
    settings = {
      lint = { run = "onSave" },
      fixAll = true,
      organizeImports = true,
      showSyntaxErrors = false,
      codeAction = {
        disableRuleComment = { enable = false },
        fixViolation = { enable = true }
      },
      logLevel = "info"
    }
  },
}
