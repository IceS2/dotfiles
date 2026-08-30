#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_home=$(mktemp -d)
trap 'rm -rf -- "$test_home"' EXIT
mkdir -p "$test_home/bin"
printf '%s\n' '#!/usr/bin/env sh' 'printf "%s\\n" "export FNM_TEST_RAN=1"' >"$test_home/bin/fnm"
printf '%s\n' '#!/usr/bin/env sh' 'printf "%s\\n" "function _uv_test_generated { :; }"' >"$test_home/bin/uv"
chmod +x "$test_home/bin/fnm" "$test_home/bin/uv"

startup_state=$(
  HOME="$test_home" ZDOTDIR="$repo_root/zsh/config" PATH="$test_home/bin:$PATH" \
    zsh -dfic 'source "$ZDOTDIR/.zshrc"; print -r -- "HISTFILE=$HISTFILE"; bindkey "^R"; print -r -- "FNM=${+FNM_TEST_RAN} UVCOMP=${+functions[_uv_test_generated]}"'
)

expected_history="HISTFILE=$test_home/.local/state/zsh/history"
expected_binding='"^R" fzf-history-widget'
expected_compdump="$test_home/.cache/zsh/zcompdump-$(zsh -fc 'print -r -- "$ZSH_VERSION"')"

[[ "$startup_state" == *"$expected_history"* ]] || {
  printf 'expected XDG history path %q, got:\n%s\n' "$expected_history" "$startup_state" >&2
  exit 1
}

[[ "$startup_state" == *"$expected_binding"* ]] || {
  printf 'expected upstream fzf Ctrl-R binding %q, got:\n%s\n' "$expected_binding" "$startup_state" >&2
  exit 1
}

[[ "$startup_state" == *'FNM=0 UVCOMP=0'* ]] || {
  printf 'expected fnm and uv initialization to be deferred, got:\n%s\n' "$startup_state" >&2
  exit 1
}

[[ -s "$expected_compdump" ]] || {
  printf 'expected completion cache at %s\n' "$expected_compdump" >&2
  exit 1
}

printf 'zsh startup behavior: ok\n'
