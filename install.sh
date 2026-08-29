#!/usr/bin/env bash
# Dotfiles orchestrator
# Usage:
#   ./install.sh              # Install all modules
#   ./install.sh hypr theme   # Install specific modules
#   ./install.sh --list       # List available modules

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

source "$DOTFILES_DIR/lib/helpers.sh"

# Module install order (dependencies first)
ALL_MODULES=(
    zsh
    git
    gnupg
    nvim
    kitty
    hypr
    quickshell
    theme
    media
    gaming
    tools
    system
    local
)

list_modules() {
    echo "Available modules:"
    for mod in "${ALL_MODULES[@]}"; do
        if [[ -x "$DOTFILES_DIR/$mod/install.sh" ]]; then
            printf "  %-14s %s/install.sh\n" "$mod" "$mod"
        fi
    done
}

run_module() {
    local mod="$1"
    shift
    local script="$DOTFILES_DIR/$mod/install.sh"

    if [[ ! -x "$script" ]]; then
        log_error "No install.sh found for module: $mod"
        return 1
    fi

    "$script" "$@"
}

# ── Main ──

if [[ "${1:-}" == "--list" ]]; then
    list_modules
    exit 0
fi

# Pass extra args (like --restart) to individual modules
EXTRA_ARGS=()
MODULES=()

for arg in "$@"; do
    if [[ "$arg" == --* ]]; then
        EXTRA_ARGS+=("$arg")
    else
        MODULES+=("$arg")
    fi
done

# Default to all modules if none specified
if [[ ${#MODULES[@]} -eq 0 ]]; then
    MODULES=("${ALL_MODULES[@]}")
fi

echo ""
log_info "Dotfiles installer — ${#MODULES[@]} module(s)"
echo ""

FAILED=()

for mod in "${MODULES[@]}"; do
    if run_module "$mod" "${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}"; then
        :
    else
        FAILED+=("$mod")
    fi
done

echo ""
if [[ ${#FAILED[@]} -eq 0 ]]; then
    log_ok "All modules installed successfully"
else
    log_error "Failed modules: ${FAILED[*]}"
    exit 1
fi
