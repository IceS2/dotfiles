#!/usr/bin/env bash
# Git configuration installer
source "$(dirname "$0")/../lib/helpers.sh"

log_header "Git"

# Main gitconfig
link_home git/.gitconfig .gitconfig

# Local config (user-specific, not overwritten if exists)
if [[ ! -f "$HOME/.gitconfig.local" ]]; then
    cp "$DOTFILES_DIR/git/.gitconfig.local.template" "$HOME/.gitconfig.local"
    log_ok "Created ~/.gitconfig.local from template"
    log_warn "Edit ~/.gitconfig.local with your name, email, and signing key"
else
    log_skip "~/.gitconfig.local (already exists)"
fi
