# ╔═══════════════════════════════════════════════════════════╗
# ║                    Shell Functions                        ║
# ║              (Custom helper functions)                    ║
# ╚═══════════════════════════════════════════════════════════╝

#: Directory Navigation {{{{
#: Make directory and cd into it
#: Usage: mkcd my-project
mkcd() {
  mkdir -p "$1" && cd "$1"
}

#: Go up N directories
#: Usage: up 3 (goes up 3 levels)
up() {
  local levels=${1:-1}
  local path=""
  for ((i=0; i<levels; i++)); do
    path="../$path"
  done
  cd "$path"
}
#: }}}}

#: File Operations {{{{
#: Extract any archive format
#: Usage: extract file.tar.gz
extract() {
  if [[ -f $1 ]]; then
    case $1 in
      *.tar.bz2)   tar xjf "$1"     ;;
      *.tar.gz)    tar xzf "$1"     ;;
      *.tar.xz)    tar xJf "$1"     ;;
      *.bz2)       bunzip2 "$1"     ;;
      *.rar)       unrar x "$1"     ;;
      *.gz)        gunzip "$1"      ;;
      *.tar)       tar xf "$1"      ;;
      *.tbz2)      tar xjf "$1"     ;;
      *.tgz)       tar xzf "$1"     ;;
      *.zip)       unzip "$1"       ;;
      *.Z)         uncompress "$1"  ;;
      *.7z)        7z x "$1"        ;;
      *)           echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

#: Show largest files/directories using dust
#: Usage: largest [directory] [limit]
largest() {
  local dir=${1:-.}
  local limit=${2:-10}
  
  if (( $+commands[dust] )); then
    dust -n "$limit" "$dir"
  else
    du -ah "$dir" | sort -rh | head -n "$limit"
  fi
}
#: }}}}
