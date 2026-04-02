# ╔═══════════════════════════════════════════════════════════╗
# ║                  Completion System                        ║
# ║                zsh-completion.zsh                         ║
# ╚═══════════════════════════════════════════════════════════╝

#: Completion Initialization {{{
# Optimized: Only rebuild cache once per day (50-100ms savings!)
autoload -Uz compinit

# Check if cache is older than 24 hours
zcompdump_path="${ZDOTDIR:-$HOME}/.zcompdump"
if [[ -n $zcompdump_path(#qN.mh+24) ]]; then
  # Rebuild cache
  compinit
else
  # Use existing cache (skip security check with -C)
  compinit -C
fi

# Compile .zcompdump to .zwc for faster loading (runs in background)
{
  zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
  if [[ -s "$zcompdump" && (! -s "${zcompdump}.zwc" || "$zcompdump" -nt "${zcompdump}.zwc") ]]; then
    rm -f "${zcompdump}.zwc"
    zcompile "$zcompdump"
  fi
} &!
#: }}}

#: Completion Behavior {{{
# Progressive completion matchers (tried in order):
# 1. Exact match first (fastest)
# 2. Case-insensitive (Doc = doc = DOC)
# 3. Partial word completion (f-b = foo-bar)
# 4. Substring matching (load = downLOAD)
zstyle ':completion:*' matcher-list \
  '' \
  'm:{a-z}={A-Z}' \
  'r:|[._-]=* r:|=*' \
  'l:|=* r:|=*'

# Color files in completion (uses LS_COLORS)
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Group completions by type
zstyle ':completion:*:descriptions' format '[%d]'

# Disable sort for git checkout (use recent branches first)
zstyle ':completion:*:git-checkout:*' sort false
#: }}}

#: fzf-tab Configuration {{{
# Preview directory contents when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview \
  'ls -1 --color=always $realpath'

# Preview git branches with commit history
zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview \
  'git log --oneline --graph --date=short --color=always --pretty="%C(auto)%h%d %s %C(green)%cr" $word'

# Switch between completion groups with , and .
zstyle ':fzf-tab:*' switch-group ',' '.'
#: }}}
