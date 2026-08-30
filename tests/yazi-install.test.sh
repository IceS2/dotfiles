#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT
mkdir -p "$test_root/bin" "$test_root/home"

cat >"$test_root/bin/ya" <<'YA'
#!/usr/bin/env bash
printf '%s\n' "$*" >"$YA_ARGS_FILE"
YA
chmod +x "$test_root/bin/ya"

HOME="$test_root/home" \
DOTFILES_DIR="$repo_root" \
YA_ARGS_FILE="$test_root/ya-args" \
PATH="$test_root/bin:$PATH" \
  "$repo_root/tools/install.sh" >/dev/null

[[ $(<"$test_root/ya-args") == "pkg install" ]]
[[ $(readlink "$test_root/home/.config/yazi") == "$repo_root/tools/yazi" ]]

printf 'yazi package installation: ok\n'
