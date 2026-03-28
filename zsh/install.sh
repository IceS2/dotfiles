#!/usr/bin/env bash
# Zsh + Starship configuration installer
source "$(dirname "$0")/../lib/helpers.sh"

log_header "Zsh"

# .zshenv bootstraps ZDOTDIR to ~/.config/zsh
link_home zsh/.zshenv .zshenv

# Modular zsh config dir
link_config zsh/config zsh

# Starship prompt config
link_config zsh/starship.toml starship.toml
