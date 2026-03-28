# ╔═══════════════════════════════════════════════════════════╗
# ║                    Shell Options                          ║
# ║                   zsh-options.zsh                         ║
# ╚═══════════════════════════════════════════════════════════╝

#: History Configuration {{{
HISTFILE=~/.histfile
HISTSIZE=10000              # Max events in memory
SAVEHIST=1000000            # Max events in history file (1 million!)

# History behavior
setopt HIST_IGNORE_ALL_DUPS  # Don't record duplicates
setopt HIST_IGNORE_SPACE     # Don't record commands starting with space
setopt HIST_SAVE_NO_DUPS     # Don't write duplicates to file
setopt HIST_REDUCE_BLANKS    # Remove superfluous blanks
setopt HIST_VERIFY           # Show before executing from history
setopt SHARE_HISTORY         # Share history between sessions
setopt INC_APPEND_HISTORY    # Add immediately, not at shell exit
setopt EXTENDED_HISTORY      # Save timestamp + duration
#: }}}

#: Directory Navigation {{{
setopt AUTO_CD               # Type directory name to cd
setopt AUTO_PUSHD            # cd automatically pushes to directory stack
setopt PUSHD_IGNORE_DUPS     # Don't push duplicates
setopt PUSHD_SILENT          # Don't print directory stack after pushd
#: }}}

#: Completion Behavior {{{
# These complement fzf-tab (don't conflict with it)
setopt COMPLETE_IN_WORD      # Complete from both ends of word
setopt ALWAYS_TO_END         # Move cursor to end after completion

# Note: AUTO_MENU, AUTO_LIST, MENU_COMPLETE are handled by fzf-tab
#: }}}

#: Globbing & Pattern Matching {{{
setopt EXTENDED_GLOB         # Use #, ~, ^ for advanced patterns
unsetopt NOMATCH             # Don't error on no matches
#: }}}

#: Misc Options {{{
unsetopt BEEP                        # No beeping
setopt INTERACTIVE_COMMENTS          # Allow # comments in interactive shell
setopt LONG_LIST_JOBS                # Show PID in job listings
setopt NOTIFY                        # Report background job status immediately
#: }}}
