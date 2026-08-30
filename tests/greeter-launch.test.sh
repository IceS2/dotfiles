#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT
mkdir -p "$test_root/bin"

printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf "%s\\n" "$*" >>"$SYSTEMCTL_LOG"' \
  >"$test_root/bin/systemctl"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf "%s\\n" "$*" >"$QUICKSHELL_LOG"' \
  >"$test_root/bin/quickshell"
chmod +x "$test_root/bin/systemctl" "$test_root/bin/quickshell"

SYSTEMCTL_LOG="$test_root/systemctl.log" \
QUICKSHELL_LOG="$test_root/quickshell.log" \
PATH="$test_root/bin:$PATH" \
  bash "$repo_root/system/greeter/launch.sh"

[[ ! -s "$test_root/systemctl.log" ]] || {
  printf 'greeter launcher changed user services:\n' >&2
  cat "$test_root/systemctl.log" >&2
  exit 1
}

[[ $(<"$test_root/quickshell.log") == '-p /etc/greetd/greeter_shell.qml' ]] || {
  printf 'greeter launcher did not start the configured shell\n' >&2
  exit 1
}

printf 'greeter launcher isolation: ok\n'
