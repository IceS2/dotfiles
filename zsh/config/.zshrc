# ╔═══════════════════════════════════════════════════════════╗
# ║                      ZSH Configuration                    ║
# ║                   Modular Architecture                    ║
# ╚═══════════════════════════════════════════════════════════╝
#
# This is the main orchestrator file that sources all configuration modules.
# Each module handles a specific aspect of the shell configuration.
#
# Module load order is important:
#   1. Environment variables (must be first)
#   2. Shell options and behavior
#   3. Plugins (includes compinit)
#   4. Completion configuration (after compinit)
#   5. External tools (starship, zoxide, fzf)
#   6. Aliases
#   7. Functions
#   8. Keybindings (last, so nothing overrides them)

# Performance monitoring (optional - uncomment to debug startup time)
# zmodload zsh/zprof

# ─────────────────────────────────────────────────────────────
# Module 1: Environment Variables
# ─────────────────────────────────────────────────────────────
source "${ZDOTDIR:-$HOME/.config/zsh}/zsh-env.zsh"

# ─────────────────────────────────────────────────────────────
# Module 2: Shell Options & Behavior
# ─────────────────────────────────────────────────────────────
source "${ZDOTDIR:-$HOME/.config/zsh}/zsh-options.zsh"

# ─────────────────────────────────────────────────────────────
# Module 3: Plugin Management
# ─────────────────────────────────────────────────────────────
# Loads plugin loader functions and initializes all plugins
# Includes: zsh-defer, autosuggestions, fzf-tab, syntax highlighting, etc.
source "${ZDOTDIR:-$HOME/.config/zsh}/zsh-plugins.zsh"

# ─────────────────────────────────────────────────────────────
# Module 4: Completion System
# ─────────────────────────────────────────────────────────────
# Initialize completion system first (needed by plugins like fzf-tab)
source "${ZDOTDIR:-$HOME/.config/zsh}/zsh-completion.zsh"

# Now load all plugins (after compinit is ready)
plugin-load $plugins

# ─────────────────────────────────────────────────────────────
# Module 5: External Tools
# ─────────────────────────────────────────────────────────────
# Initializes: starship, zoxide, fzf (with fd/bat integration)
source "${ZDOTDIR:-$HOME/.config/zsh}/zsh-tools.zsh"

# ─────────────────────────────────────────────────────────────
# Module 6: Aliases
# ─────────────────────────────────────────────────────────────
# Modern CLI tool replacements (eza, bat, dust, etc.)
source "${ZDOTDIR:-$HOME/.config/zsh}/zsh-aliases.zsh"

# ─────────────────────────────────────────────────────────────
# Module 7: Functions
# ─────────────────────────────────────────────────────────────
# Custom helper functions (icy, mkcd, extract, git helpers, etc.)
source "${ZDOTDIR:-$HOME/.config/zsh}/zsh-functions.zsh"

# ─────────────────────────────────────────────────────────────
# Module 8: Keybindings
# ─────────────────────────────────────────────────────────────
# Load last to ensure nothing overrides custom bindings
source "${ZDOTDIR:-$HOME/.config/zsh}/zsh-keybindings.zsh"

# ─────────────────────────────────────────────────────────────
# Module 9: Private Configuration
# ─────────────────────────────────────────────────────────────
# Load private/sensitive configuration (tokens, API keys, etc.)
# This file is gitignored and contains secrets
if [[ -f "${ZDOTDIR:-$HOME/.config/zsh}/zsh-private.zsh" ]]; then
  source "${ZDOTDIR:-$HOME/.config/zsh}/zsh-private.zsh"
fi

# ─────────────────────────────────────────────────────────────
# Performance Profiling
# ─────────────────────────────────────────────────────────────
# Uncomment to see startup time breakdown
# zprof
