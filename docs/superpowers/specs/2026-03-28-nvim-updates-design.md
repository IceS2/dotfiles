# Neovim Config Updates — Design Spec

**Date:** 2026-03-28
**Scope:** 3 changes — claudecode.nvim, blink.cmp signature help, nvim-lint

---

## 1. Add claudecode.nvim

**Purpose:** Bridge plugin that exposes editor context to Claude Code via WebSocket. Claude Code gains diff review, selection tracking, LSP diagnostics access, and buffer awareness.

**File:** `nvim/lua/plugins/editor/claudecode.lua`

**Plugin spec:**

```lua
return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  config = true,
  keys = {
    { "<leader>a", nil, desc = "AI" },
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume session" },
    { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue session" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add buffer" },
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
  },
  opts = {
    terminal = {
      split_side = "right",
      split_width_percentage = 0.35,
    },
  },
}
```

**Keybind group:** `<leader>a` → "AI" (no conflicts with existing groups).

**Which-key registration:** Add `{ "<leader>a", group = "AI", icon = "󰁤 " }` to which-key spec.

**Decisions:**
- Drop `<leader>am` (model select) — not commonly needed, available via `:ClaudeCodeSelectModel`
- Drop `<leader>as` file-tree variant — snacks.explorer doesn't use those filetypes
- 35% split width (slightly wider than default 30%) for readable Claude output
- All other opts left at defaults (auto_start, track_selection, diff vertical layout)

---

## 2. Enable blink.cmp Signature Help

**Purpose:** Show inline parameter hints while typing function arguments. Previously disabled, now matured in blink.cmp v1.

**File:** `nvim/lua/plugins/core/completion.lua`

**Change:** Replace `signature = { enabled = false }` with:

```lua
signature = {
  enabled = true,
  window = {
    border = "single",
  },
},
```

**Rationale:** Matches the `border = "single"` style used in documentation and completion menu windows. No other config needed — defaults are sensible.

---

## 3. Add nvim-lint

**Purpose:** Async linting for languages without strong LSP linting coverage. Feeds diagnostics into `vim.diagnostic`.

**File:** `nvim/lua/plugins/editor/lint.lua`

**Plugin spec:**

```lua
return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPost", "BufWritePost" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      sh = { "shellcheck" },
      bash = { "shellcheck" },
      zsh = { "zsh" },
      markdown = { "markdownlint" },
    }

    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
      group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
      callback = function()
        lint.try_lint()
      end,
    })
  end,
}
```

**Linter choices:**
- `shellcheck` for sh/bash — the standard, catches quoting issues, unused variables, POSIX compliance
- `zsh` built-in linter for zsh files (shellcheck doesn't fully support zsh)
- `markdownlint` for markdown — catches heading structure, list formatting, line length

**Not included:** vale (prose linting — overkill for a dotfiles repo), ruff/biome (already handled by LSP).

**Prerequisites:** `shellcheck` and `markdownlint-cli` must be installed. Both available via pacman:
```bash
sudo pacman -S shellcheck
pnpm add -g markdownlint-cli
```

---

## Files Changed Summary

| File | Action |
|------|--------|
| `nvim/lua/plugins/editor/claudecode.lua` | Create |
| `nvim/lua/plugins/editor/lint.lua` | Create |
| `nvim/lua/plugins/core/completion.lua` | Edit (signature enable) |
| `nvim/lua/plugins/core/ui/which-key.lua` | Edit (add AI group) |
