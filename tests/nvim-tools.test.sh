#!/usr/bin/env bash
set -euo pipefail

STATE_ROOT=$(mktemp -d)
trap 'rm -rf "$STATE_ROOT"' EXIT

XDG_STATE_HOME="$STATE_ROOT" nvim --headless -i NONE \
    '+lua if vim.fn.exists(":MasonToolsInstallSync") ~= 2 then vim.api.nvim_err_writeln("MasonToolsInstallSync is unavailable"); vim.cmd.cquit(1) end' \
    '+MasonToolsInstallSync' \
    '+lua if vim.fn.executable("codelldb") ~= 1 then vim.api.nvim_err_writeln("codelldb is unavailable"); vim.cmd.cquit(1) end' \
    '+lua if vim.fn.executable("js-debug-adapter") ~= 1 then vim.api.nvim_err_writeln("js-debug-adapter is unavailable"); vim.cmd.cquit(1) end' \
    '+lua if vim.fn.executable("markdownlint") ~= 1 then vim.api.nvim_err_writeln("markdownlint is unavailable"); vim.cmd.cquit(1) end' \
    '+lua if vim.fn.executable("prettier") ~= 1 then vim.api.nvim_err_writeln("prettier is unavailable"); vim.cmd.cquit(1) end' \
    '+lua if vim.fn.executable("stylua") ~= 1 then vim.api.nvim_err_writeln("stylua is unavailable"); vim.cmd.cquit(1) end' \
    '+qa'
