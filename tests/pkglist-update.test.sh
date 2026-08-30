#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT
mkdir -p "$test_root/bin" "$test_root/output"

printf '%s\n' \
  '#!/usr/bin/env bash' \
  'case "$1" in' \
  '  -Qqen) printf "%s\\n" bat git neovim ;;' \
  '  -Qqem) [[ ${FAIL_AUR:-0} == 0 ]] || exit 23; printf "%s\\n" paru waterfox-bin ;;' \
  '  *) exit 24 ;;' \
  'esac' \
  >"$test_root/bin/pacman"
chmod +x "$test_root/bin/pacman"

printf '%s\n' old-official >"$test_root/output/official.txt"
printf '%s\n' old-aur >"$test_root/output/aur.txt"

if FAIL_AUR=1 PATH="$test_root/bin:$PATH" \
  "$repo_root/system/pacman-hooks/update-pkglist" --output-dir "$test_root/output"; then
  printf 'expected a failed AUR query to fail the update\n' >&2
  exit 1
fi

[[ $(<"$test_root/output/official.txt") == old-official ]]
[[ $(<"$test_root/output/aur.txt") == old-aur ]]

PATH="$test_root/bin:$PATH" \
  "$repo_root/system/pacman-hooks/update-pkglist" --output-dir "$test_root/output"

[[ $(<"$test_root/output/official.txt") == $'bat\ngit\nneovim' ]]
[[ $(<"$test_root/output/aur.txt") == $'paru\nwaterfox-bin' ]]
[[ $(stat -c %u "$test_root/output/official.txt") == $(id -u) ]]
[[ $(stat -c %u "$test_root/output/aur.txt") == $(id -u) ]]
[[ -z $(find "$test_root/output" -maxdepth 1 -name '.update.*' -print -quit) ]]

printf 'package manifest update: ok\n'
