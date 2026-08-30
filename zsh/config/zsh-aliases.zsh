# ╔═══════════════════════════════════════════════════════════╗
# ║                    Command Aliases                        ║
# ║              (Modern CLI Tool Replacements)               ║
# ╚═══════════════════════════════════════════════════════════╝

#: Modern Replacements {{{{
#: ls → eza (Rust, git-aware, icons, colors)
if (( $+commands[eza] )); then
  # Remove any existing aliases first
  unalias ls ll la l 2>/dev/null

  # Use functions instead of aliases for better completion support
  ls() { eza --group-directories-first --icons "$@" }
  ll() { eza -la --group-directories-first --icons --git "$@" }
  la() { eza -a --group-directories-first --icons "$@" }
  l() { eza -l --group-directories-first --icons "$@" }

  alias tree='eza --tree --icons'
  alias lt='eza --tree --level=2 --icons'

  # Use eza's completion for the ls function
  compdef ls=eza
  compdef ll=eza
  compdef la=eza
  compdef l=eza
else
  # Fallback to lsd if eza not installed
  if (( $+commands[lsd] )); then
    alias ls='lsd'
    alias tree='lsd --tree'
  fi
fi

#: cat → bat (already configured in zsh-env.zsh with BAT_THEME)
if (( $+commands[bat] )); then
  alias cat='bat --style=auto'
  alias catt='bat --style=plain'  # bat without decorations
fi

# Keep man-page colors local instead of depending on a plugin repository.
man() {
  env \
    LESS_TERMCAP_md="$(tput bold; tput setaf 4)" \
    LESS_TERMCAP_me="$(tput sgr0)" \
    LESS_TERMCAP_mb="$(tput blink)" \
    LESS_TERMCAP_us="$(tput setaf 2)" \
    LESS_TERMCAP_ue="$(tput sgr0)" \
    LESS_TERMCAP_so="$(tput smso)" \
    LESS_TERMCAP_se="$(tput rmso)" \
    PAGER="${commands[less]:-$PAGER}" \
    man "$@"
}

#: df → duf (not installed, but ready if you install it later)
if (( $+commands[duf] )); then
  alias df='duf'
fi

#: htop → bottom (Rust system monitor)
if (( $+commands[btm] )); then
  alias htop='btm'
  alias top='btm'
fi

#: }}}}

#: Git Aliases {{{{
#: Git shortcuts
alias gfu='git fetch upstream'
alias gf='git fetch'
alias gc='git checkout'
alias gst='git status'
alias gd='git diff'        # Now uses delta
alias gds='git diff --staged'
alias gl='git log --oneline --graph --decorate'
alias gll='git log --graph --pretty=format:"%C(auto)%h%d %s %C(green)%cr %C(blue)%an"'

#: Git branch creation helpers moved to zsh-functions.zsh
#: Use: git-new-branch <name> [remote]
#: Use: git-random-branch [remote]

#: Lazygit TUI
if (( $+commands[lazygit] )); then
  alias lg='lazygit'
fi
#: }}}}

#: Development Tools {{{{
#: Code statistics
if (( $+commands[tokei] )); then
  alias loc='tokei'  # Lines of code
fi

#: Benchmarking
if (( $+commands[hyperfine] )); then
  alias bench='hyperfine'
fi
#: }}}}

#: Quick Shortcuts {{{{
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

#: Safe operations (ask before overwrite)
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

#: Grep with color
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

#: Disk usage sorted
ducks() {
  (( $# > 0 )) || set -- .
  command du -h --max-depth=1 -- "$@" | sort -h
}
#: }}}}

#: File Manager {{{{
#: yazi - Terminal file manager
if (( $+commands[yazi] )); then
  alias fm='yazi'
  alias yy='yazi'
fi
#: }}}}

#: Media {{{{
alias discord-compress='~/.dotfiles/tools/scripts/discord-compress.sh'
#: }}}}

#: System Management {{{{
alias update='~/.dotfiles/tools/scripts/update.sh'
#: }}}}
