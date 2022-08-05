# Rustup binaries
. "$HOME/.cargo/env"

# Path Append
PATH="${PATH}:/home/ices2/.local/bin"

# Misc Exports
export EDITOR=nvim

# Keyboard Layout
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XCOMPOSEFILE=$HOME/.XCompose
export XMODIFIERS=@im=ibus

# Java Window Manager Issue
export _JAVA_AWT_WM_NONREPARENTING=1


# Glovo
source $HOME/.glovo_env
