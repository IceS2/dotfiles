local M = {}

M.setup = function(bufnr)
  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end

  map("n", "<leader>cr", vim.lsp.buf.rename, "Rename Symbol")
  map("n", "<leader>cR", function()
    Snacks.rename.rename_file()
  end, "Rename File")
  map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code Action")

  map("n", "[d", function()
    vim.diagnostic.jump({ count = -1, float = true })
  end, "Previous Diagnostic")
  map("n", "]d", function()
    vim.diagnostic.jump({ count = 1, float = true })
  end, "Next Diagnostic")
  map("n", "<leader>cd", vim.diagnostic.open_float, "Show Diagnostics")

  map("n", "<leader>ch", function()
    local filter = { bufnr = bufnr }
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(filter), filter)
  end, "Toggle Inlay Hints")
end

return M
