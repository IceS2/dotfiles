local M = {}

M.setup = function(bufnr)
    local function safe_map(mode, lhs, rhs, opts)
        if rhs == nil then
            print(string.format("Warning: keymap for '%s' in mode '%s' is nil!", lhs, mode))
            return
        end
        vim.keymap.set(mode, lhs, rhs, opts)
    end
    -- Navigation
    safe_map("n", "gd", vim.lsp.buf.definition, { buffer = bufnr, desc = "Go to Definition" })
    safe_map("n", "gD", vim.lsp.buf.declaration, { buffer = bufnr, desc = "Go to Declaration" })
    safe_map("n", "gi", vim.lsp.buf.implementation, { buffer = bufnr, desc = "Go to Implementation" })
    safe_map("n", "gr", vim.lsp.buf.references, { buffer = bufnr, desc = "Go to References" })
    safe_map("n", "gT", vim.lsp.buf.type_definition, { buffer = bufnr, desc = "Go to Type Definition" })

    -- Info
    safe_map("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "Hover Documentation" })
    safe_map({ "n", "i" }, "<C-s>", vim.lsp.buf.signature_help, { buffer = bufnr, desc = "Signature Help" })

    -- Actions
    safe_map("n", "<leader>cr", vim.lsp.buf.rename, { buffer = bufnr, desc = "Rename Symbol" })
    safe_map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr, desc = "Code Action" })
    safe_map("n", "<leader>cf", function()
      vim.lsp.buf.format({ async = true })
    end, { buffer = bufnr, desc = "Format Document" })

    -- Diagnostics
    safe_map("n", "[d", function()
      vim.diagnostic.jump({ count = -1, float = true })
    end, { buffer = bufnr, desc = "Previous Diagnostic" })
    safe_map("n", "]d", function()
      vim.diagnostic.jump({ count = 1, float = true })
    end, { buffer = bufnr, desc = "Next Diagnostic" })
    safe_map("n", "<leader>cd", vim.diagnostic.open_float, { buffer = bufnr, desc = "Show Diagnostics on Float Window" })

    -- Inlay hints toggle
    safe_map("n", "<leader>ch", function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
    end, { buffer = bufnr, desc = "Toggle Inlay Hints" })
end

return M
