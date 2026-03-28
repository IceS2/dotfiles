# ╔═══════════════════════════════════════════════════════════╗
# ║                    Key Bindings                           ║
# ║              (Custom keyboard shortcuts)                  ║
# ╚═══════════════════════════════════════════════════════════╝

#: Editing Mode {{{{
#: Use emacs-style keybindings (Ctrl+A/E/K/U/W, etc.)
#: Alternative: 'bindkey -v' for vim mode
bindkey -e
#: }}}}

#: Autosuggestions {{{{
#: Accept autosuggestion with Ctrl+Space (legacy)
bindkey '^ ' autosuggest-accept
#: }}}}

#: Word Navigation {{{{
#: Option+f / Option+b (legacy - macOS style)
bindkey '^[f' forward-word
bindkey '^[b' backward-word

#: Ctrl+Right / Ctrl+Left (terminal compatibility)
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

#: Alt+Right / Alt+Left (additional compatibility)
bindkey '^[[1;3C' forward-word
bindkey '^[[1;3D' backward-word
#: }}}}

#: History Search {{{{
#: Ctrl+R - Reverse history search (legacy)
#: Note: fzf-history-search plugin may override this
bindkey '^R' history-incremental-search-backward

#: Ctrl+S - Forward history search
bindkey '^S' history-incremental-search-forward

#: Up/Down - Smart history search (filters by current input)
#: Type 'git' then press Up to see only git commands
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward
#: }}}}

#: Line Editing {{{{
#: Ctrl+A - Beginning of line (emacs default, explicit for clarity)
bindkey '^A' beginning-of-line

#: Ctrl+E - End of line (emacs default, explicit for clarity)
bindkey '^E' end-of-line

#: Ctrl+U - Delete from cursor to beginning of line
bindkey '^U' backward-kill-line

#: Ctrl+K - Delete from cursor to end of line
bindkey '^K' kill-line

#: Ctrl+W - Delete word backward
bindkey '^W' backward-kill-word

#: Alt+D - Delete word forward
bindkey '^[d' kill-word

#: Ctrl+Y - Paste (yank) killed text (emacs default)
bindkey '^Y' yank
#: }}}}

#: Special Keys {{{{
#: Home / End keys (terminal compatibility)
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line

#: Delete key (forward delete)
bindkey '^[[3~' delete-char

#: Backspace (ensure it works in all terminals)
bindkey '^?' backward-delete-char
bindkey '^H' backward-delete-char
#: }}}}

#: Advanced Features {{{{
#: Ctrl+X Ctrl+E - Edit command line in $EDITOR (nvim)
#: Useful for long/complex commands
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line
#: }}}}

#: Notes {{{{
#: Ctrl+Z - Suspend/resume (built-in zsh, no binding needed)
#: Ctrl+C - Interrupt (built-in zsh, no binding needed)
#: Ctrl+D - Exit shell (built-in zsh, no binding needed)
#: Tab - Completion (handled by completion system)
#: }}}}
