function plugin-load {
  local repo plugin_name plugin_dir initfile initfiles
  ZPLUGINDIR=${ZPLUGINDIR:-${ZDOTDIR:-$HOME/.config/zsh}/plugins}
  for repo in $@; do
    plugin_name=${repo:t}
    plugin_dir=$ZPLUGINDIR/$plugin_name
    initfile=$plugin_dir/$plugin_name.plugin.zsh
    if [[ ! -d $plugin_dir ]]; then
      echo "Cloning $repo"
      git clone -q --depth 1 --recursive --shallow-submodules https://github.com/$repo $plugin_dir
    fi
    if [[ ! -e $initfile ]]; then
      initfiles=($plugin_dir/*.plugin.{z,}sh(N) $plugin_dir/*.{z,}sh{-theme,}(N))
      [[ ${#initfiles[@]} -gt 0 ]] || { echo >&2 "Plugin has no init file '$repo'." && continue }
      ln -sf "${initfiles[1]}" "$initfile"
    fi
    fpath+=$plugin_dir
    (( $+functions[zsh-defer] )) && zsh-defer . $initfile || . $initfile
  done
}

function plugin-update {
  ZPLUGINDIR=${ZPLUGINDIR:-$HOME/.config/zsh/plugins}
  for d in $ZPLUGINDIR/*/.git(/); do
    echo "Updating ${d:h:t}..."
    command git -C "${d:h}" pull --ff --recurse-submodules --depth 1 --rebase --autostash
  done
}

plugins=(
  # Lazy Load
  romkatv/zsh-defer

  # In Line Suggestions
  zsh-users/zsh-autosuggestions

  # Web Search from Terminal
  sineto/web-search

  # Alias Reminders
  MichaelAquilina/zsh-you-should-use

  redxtech/zsh-show-path
  ael-code/zsh-colored-man-pages

  # Git Utilities
  Bhupesh-V/ugit

  # Vim Mode
  # jeffreytse/zsh-vi-mode

  # Search History powered by fzf
  joshskidmore/zsh-fzf-history-search

  # Completion powered by fzf
  Aloxaf/fzf-tab

  # Syntax highlight. It should be loaded last!
  zdharma-continuum/fast-syntax-highlighting

)

zmodload zsh/langinfo
zmodload zsh/complist
autoload bashcompinit && bashcompinit
autoload -Uz compinit && compinit

plugin-load $plugins

complete -C $(command -v aws_completer) aws
zstyle ':completion:*:*:git:*' script ~/.config/zsh/completions/git.zsh
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# preview directory's content with exa when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'lsd -1 --color=always $realpath'
# switch group using `,` and `.`
zstyle ':fzf-tab:*' switch-group ',' '.'

bindkey '^ ' autosuggest-accept

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=1000000
setopt autocd
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
unsetopt NOMATCH
unsetopt beep
# bindkey -e
# End of lines configured by zsh-newuser-install


# Prompt -----------------------------------
eval "$(starship init zsh)"

# Zoxide -----------------------------------
eval "$(zoxide init zsh)"

# Pyenv ------------------------------------
export PYENV_ROOT="$HOME/.pyenv"
eval "$(pyenv init -)"
eval "$(pyenv init --path)"
eval "$(pyenv virtualenv-init -)"

# nvm --------------------------------------
# source /usr/share/nvm/init-nvm.sh

# Direnv -----------------------------------
eval "$(direnv hook zsh)"

# Alias ------------------------------------

# icy
icy() {
  if [[ -z $1 ]]; then
    nvim -c Dashboard
  else
    nvim $@
  fi
}

# ls
alias ls="lsd"
alias tree="lsd --tree"

# cat
alias cat="bat"

# kubectl
# alias kubectl="kubecolor"

# Python Virtualenv
alias venv="$HOME/.config/scripts/create_python_env.sh"

venv-delete() {
  pyenv virtualenv-delete $1
}

# Git
alias gfu="git fetch upstream"
alias gf="git fetch"
alias gc="git checkout"
alias gcb='function gcb(){git fetch $2 && gc -b "$1" --no-track $2/main};gcb'
alias gcr='function gcr(){git fetch $1 && gc -B random --no-track $1/main};gcr'

# Bindings ---------------------------------
# bindkey "^[[1;3C" forward-word
# bindkey "^[[1;3D" backward-word
bindkey '^R' history-incremental-search-backward

export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
# export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"
export PATH="$HOME/apache-maven-3.9.6/bin:$PATH"
