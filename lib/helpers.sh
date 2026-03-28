#!/usr/bin/env bash
# Shared idempotent helper functions for dotfiles install scripts
# Source this file at the top of each module's install.sh

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

# ── Colors ──

_RED='\033[0;31m'
_GREEN='\033[0;32m'
_YELLOW='\033[0;33m'
_BLUE='\033[0;34m'
_CYAN='\033[0;36m'
_DIM='\033[2m'
_BOLD='\033[1m'
_RESET='\033[0m'

# ── Logging ──

log_info()  { printf "${_BLUE}[INFO]${_RESET}  %s\n" "$*"; }
log_ok()    { printf "${_GREEN}[OK]${_RESET}    %s\n" "$*"; }
log_warn()  { printf "${_YELLOW}[WARN]${_RESET}  %s\n" "$*"; }
log_skip()  { printf "${_DIM}[SKIP]${_RESET}  %s\n" "$*"; }
log_error() { printf "${_RED}[ERROR]${_RESET} %s\n" "$*" >&2; }

log_header() {
    printf "\n${_BOLD}${_CYAN}── %s ──${_RESET}\n\n" "$*"
}

# ── Core helpers ──

ensure_dir() {
    local path="$1"
    if [[ -d "$path" ]]; then
        return 0
    fi
    mkdir -p "$path"
    log_ok "Created directory: $path"
}

# Internal: create a symlink idempotently
# Usage: _make_link <source> <destination>
_make_link() {
    local src="$1"
    local dest="$2"

    # Source must exist
    if [[ ! -e "$src" ]]; then
        log_error "Source does not exist: $src"
        return 1
    fi

    # Already correct symlink
    if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
        log_skip "$dest (already linked)"
        return 0
    fi

    # Wrong symlink — remove and recreate
    if [[ -L "$dest" ]]; then
        rm "$dest"
        ln -s "$src" "$dest"
        log_ok "$dest -> $src (relinked)"
        return 0
    fi

    # Regular file/dir exists — back up then link
    if [[ -e "$dest" ]]; then
        mv "$dest" "${dest}.bak"
        log_warn "Backed up existing: $dest -> ${dest}.bak"
        ln -s "$src" "$dest"
        log_ok "$dest -> $src"
        return 0
    fi

    # Nothing exists — create link
    ln -s "$src" "$dest"
    log_ok "$dest -> $src"
}

# Symlink into ~/.config/
# Usage: link_config <relative_source> [config_name]
# Example: link_config nvim        -> ~/.config/nvim -> $DOTFILES_DIR/nvim
# Example: link_config zsh/starship.toml starship.toml -> ~/.config/starship.toml
link_config() {
    local src_rel="$1"
    local name="${2:-$(basename "$src_rel")}"
    local src="$DOTFILES_DIR/$src_rel"
    local dest="$HOME/.config/$name"

    ensure_dir "$HOME/.config"
    _make_link "$src" "$dest"
}

# Symlink into ~/
# Usage: link_home <relative_source> [home_name]
# Example: link_home zsh/.zshenv .zshenv -> ~/.zshenv -> $DOTFILES_DIR/zsh/.zshenv
link_home() {
    local src_rel="$1"
    local name="${2:-$(basename "$src_rel")}"
    local src="$DOTFILES_DIR/$src_rel"
    local dest="$HOME/$name"

    _make_link "$src" "$dest"
}

# Symlink to arbitrary destination
# Usage: link_to <relative_source> <absolute_destination>
link_to() {
    local src_rel="$1"
    local dest="$2"
    local src="$DOTFILES_DIR/$src_rel"

    ensure_dir "$(dirname "$dest")"
    _make_link "$src" "$dest"
}

# Sudo symlink to arbitrary destination
# Usage: sudo_link <relative_source> <absolute_destination>
sudo_link() {
    local src_rel="$1"
    local dest="$2"
    local src="$DOTFILES_DIR/$src_rel"

    if [[ ! -e "$src" ]]; then
        log_error "Source does not exist: $src"
        return 1
    fi

    # Already correct symlink
    if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
        log_skip "$dest (already linked)"
        return 0
    fi

    sudo mkdir -p "$(dirname "$dest")"

    # Remove existing (wrong link or file)
    if [[ -L "$dest" ]] || [[ -e "$dest" ]]; then
        sudo rm -f "$dest"
    fi

    sudo ln -s "$src" "$dest"
    log_ok "$dest -> $src (sudo)"
}

# Copy file to system location (requires sudo), skip if identical
# Usage: sudo_copy <relative_source> <absolute_destination>
sudo_copy() {
    local src_rel="$1"
    local dest="$2"
    local src="$DOTFILES_DIR/$src_rel"

    if [[ ! -e "$src" ]]; then
        log_error "Source does not exist: $src"
        return 1
    fi

    sudo mkdir -p "$(dirname "$dest")"

    # Skip if identical
    if [[ -f "$dest" ]] && diff -q "$src" "$dest" &>/dev/null; then
        log_skip "$dest (identical)"
        return 0
    fi

    sudo cp "$src" "$dest"
    sudo chmod 644 "$dest"
    sudo chown root:root "$dest"
    log_ok "Copied: $src -> $dest"
}

# ── Module runner ──

# Resolve the directory of the calling script
# Usage: MODULE_DIR="$(module_dir)"
module_dir() {
    cd "$(dirname "${BASH_SOURCE[1]}")" && pwd
}
