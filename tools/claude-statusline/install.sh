#!/usr/bin/env bash
# Claude Code statusline installer — builds Rust binary and copies to ~/.claude/statusline
source "$(dirname "$0")/../../lib/helpers.sh"

log_header "Claude Statusline"

if command -v cargo &>/dev/null; then
    log_info "Building claude-statusline..."
    (cd "$(dirname "$0")" && cargo build --release --quiet)
    ensure_dir "$HOME/.claude"
    cp "$(dirname "$0")/target/release/claude-statusline" "$HOME/.claude/statusline"
    log_ok "Installed to ~/.claude/statusline"
else
    log_warn "cargo not found, skipping claude-statusline build"
fi
