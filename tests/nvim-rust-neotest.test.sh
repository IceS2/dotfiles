#!/usr/bin/env bash
set -euo pipefail

STATE_ROOT=$(mktemp -d)
FIXTURE_ROOT=$(mktemp -d)
DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
trap 'rm -rf "$STATE_ROOT" "$FIXTURE_ROOT"' EXIT

printf 'fn main() {}\n' > "$FIXTURE_ROOT/empty.rs"
printf '#[test]\nfn works() {}\n' > "$FIXTURE_ROOT/test.rs"

XDG_STATE_HOME="$STATE_ROOT" NVIM_RUST_FIXTURE="$FIXTURE_ROOT/empty.rs" NVIM_RUST_TEST_FIXTURE="$FIXTURE_ROOT/test.rs" DOTFILES_ROOT="$DOTFILES_ROOT" nvim --headless -i NONE \
    '+lua local ok, err = pcall(dofile, vim.env.DOTFILES_ROOT .. "/tests/nvim-rust-neotest.test.lua"); if not ok then vim.api.nvim_err_writeln(err); vim.cmd.cquit(1) end' \
    '+qa'
