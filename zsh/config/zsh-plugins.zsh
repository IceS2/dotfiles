# ╔═══════════════════════════════════════════════════════════╗
# ║                    Plugin System                          ║
# ║                  zsh-plugins.zsh                          ║
# ╚═══════════════════════════════════════════════════════════╝

#: Custom Plugin Loader {{{
# Lightweight plugin manager - auto-clones and lazy-loads plugins
function plugin-load {
  local repo plugin_name plugin_dir initfile initfiles
  ZPLUGINDIR=${ZPLUGINDIR:-${ZDOTDIR:-$HOME/.config/zsh}/plugins}
  
  for repo in $@; do
    plugin_name=${repo:t}
    plugin_dir=$ZPLUGINDIR/$plugin_name
    initfile=$plugin_dir/$plugin_name.plugin.zsh
    
    # Clone plugin if not present
    if [[ ! -d $plugin_dir ]]; then
      echo "Cloning $repo..."
      git clone -q --depth 1 --recursive --shallow-submodules \
        https://github.com/$repo $plugin_dir
    fi
    
    # Find and symlink init file
    if [[ ! -e $initfile ]]; then
      initfiles=($plugin_dir/*.plugin.{z,}sh(N) $plugin_dir/*.{z,}sh{-theme,}(N))
      [[ ${#initfiles[@]} -gt 0 ]] || { 
        echo >&2 "Plugin has no init file '$repo'."
        continue 
      }
      ln -sf "${initfiles[1]}" "$initfile"
    fi
    
    # Add to fpath and source (with lazy loading if available)
    fpath+=$plugin_dir
    (( $+functions[zsh-defer] )) && zsh-defer . $initfile || . $initfile
  done
}

# Update all plugins
function plugin-update {
  ZPLUGINDIR=${ZPLUGINDIR:-${ZDOTDIR:-$HOME/.config/zsh}/plugins}
  for d in $ZPLUGINDIR/*/.git(/); do
    echo "Updating ${d:h:t}..."
    command git -C "${d:h}" pull --ff --recurse-submodules --depth 1 --rebase --autostash
  done
}
#: }}}

#: Plugin List {{{
# Load order matters! See comments for details.
plugins=(
  # 1. FIRST - Lazy loading engine
  romkatv/zsh-defer
  
  # 2. Regular plugins (order doesn't matter)
  MichaelAquilina/zsh-you-should-use      # Reminds you of aliases

  # 3. Completion with fzf (after compinit, before wrappers)
  Aloxaf/fzf-tab                          # Fuzzy tab completion
  
  # 4. Autosuggestions (before syntax highlighting)
  zsh-users/zsh-autosuggestions           # Fish-like suggestions
  
  # 5. LAST - Syntax highlighting (must be loaded last!)
  zdharma-continuum/fast-syntax-highlighting
)
#: }}}

#: Load Plugins {{{
# Note: Plugins are loaded in .zshrc after completion system is set up
# This ensures proper initialization order for completion-dependent plugins
#: }}}
