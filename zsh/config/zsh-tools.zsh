# ╔═══════════════════════════════════════════════════════════╗
# ║             External Tools Initialization                 ║
# ║         (Prompt, Smart CD, Fuzzy Finder, etc.)            ║
# ╚═══════════════════════════════════════════════════════════╝

#: Prompt: Starship {{{{
#: Cross-shell, Rust-based, minimal overhead (~5ms)
#: Config: ~/.config/starship.toml
if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi
#: }}}}

#: Smart CD: Zoxide {{{{
#: Tracks frecency (frequency + recency) for intelligent directory jumping
#: Usage: z <pattern>, zi (interactive), zoxide query <pattern>
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
fi
#: }}}}

#: Node Version Manager: fnm {{{{
#: Fast Node Manager - Rust-based, faster than nvm
#: Auto-switches Node versions based on .node-version or .nvmrc files
if (( $+commands[fnm] )); then
  eval "$(fnm env --use-on-cd)"
fi
#: }}}}

#: Python Package Manager: uv {{{{
#: Rust-based, replaces pip/venv/pyenv/poetry in one unified tool
#: 10-100x faster than pip, automatic Python version management
#: Usage: uv python install 3.12, uv venv, uv pip install <package>, uv run python
if (( $+commands[uv] )); then
  # Shell completions (minimal overhead)
  eval "$(uv generate-shell-completion zsh)"
fi
#: }}}}

#: Fuzzy Finder: fzf {{{{
#: Use fd for file/directory search (respects .gitignore, faster than find)
#: Use ripgrep for text search
if (( $+commands[fzf] )); then
  # Default command for Ctrl+T (file finder)
  if (( $+commands[fd] )); then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    # Alt+C (directory finder)
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi

  # Catppuccin Mocha theme for fzf (with all color options)
  export FZF_DEFAULT_OPTS=" \
    --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
    --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
    --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
    --color=border:#89b4fa,label:#a6e3a1,query:#cdd6f4:regular \
    --color=gutter:#1e1e2e,selected-bg:#45475a,selected-fg:#cdd6f4 \
    --color=scrollbar:#89b4fa,separator:#6c7086 \
    --border=rounded --prompt='❯ ' --pointer='▶' --marker='✓'"

  # Preview with bat (syntax highlighting)
  if (( $+commands[bat] )); then
    export FZF_CTRL_T_OPTS="
      --preview 'bat --color=always --style=numbers --line-range=:500 {}'
      --preview-window='right:60%:wrap:border-rounded'
      --color=preview-bg:#1e1e2e,preview-fg:#cdd6f4
      --color=preview-border:#cba6f7,preview-label:#f9e2af
      --preview-label='[ Preview ]'"

    # Alt+C preview for directories
    export FZF_ALT_C_OPTS="
      --preview 'eza --tree --level=2 --color=always --icons {}'
      --preview-window='right:60%:wrap:border-rounded'
      --color=preview-bg:#1e1e2e,preview-border:#89b4fa
      --preview-label='[ Directory ]'"
  fi

  # Source fzf keybindings (Ctrl+T, Ctrl+R, Alt+C)
  if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
    source /usr/share/fzf/key-bindings.zsh
  fi

  # Source fzf completion
  if [[ -f /usr/share/fzf/completion.zsh ]]; then
    source /usr/share/fzf/completion.zsh
  fi
fi
#: }}}}
