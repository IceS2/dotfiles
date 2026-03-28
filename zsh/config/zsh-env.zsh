# ╔═══════════════════════════════════════════════════════════╗
# ║                   Environment Variables                   ║
# ║                     zsh-env.zsh                           ║
# ╚═══════════════════════════════════════════════════════════╝

#: Editor {{{
export EDITOR=nvim
export VISUAL=nvim
export DIFFPROG="nvim -d"
#: }}}

#: XDG Base Directory Specification {{{
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"
#: }}}

#: PATH {{{
# User binaries
export PATH="$HOME/.local/bin:$PATH"
#: }}}

#: Default Tool Configurations {{{
# BAT (modern cat) - Use Catppuccin Mocha theme
export BAT_THEME="Catppuccin Mocha"
#: }}}

#: GPG & SSH Agent {{{
# GPG TTY for passphrase prompts
export GPG_TTY=$(tty)

# Use gpg-agent for SSH (unified agent for GPG + SSH)
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
#: }}}
