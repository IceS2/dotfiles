#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT
mkdir -p "$test_root/one/two"
printf '%s\n' payload >"$test_root/one/file"

command_state=$(
  ZDOTDIR="$repo_root/zsh/config" zsh -dfc '
    compdef() { :; }
    source "$ZDOTDIR/zsh-aliases.zsh"
    print -r -- "DU=$(whence -w du)"
    print -r -- "PS=$(whence -w ps)"
    print -r -- "DUST=$(whence -w dust)"
    print -r -- "PROCS=$(whence -w procs)"
    eval '\''ducks "$1"'\''
  ' zsh "$test_root/one"
)

[[ $command_state == *'DU=du: command'* ]]
[[ $command_state == *'PS=ps: command'* ]]
[[ $command_state == *'DUST=dust: command'* ]]
[[ $command_state == *'PROCS=procs: command'* ]]
[[ $command_state == *"$test_root/one"* ]]

printf 'zsh command compatibility: ok\n'
