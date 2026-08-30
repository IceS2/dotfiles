#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT

mkdir -p "$test_root/theme"
ln -s "$repo_root/theme/catppuccin26.py" "$test_root/theme/catppuccin26.py"
ln -s "$repo_root/theme/dank16.py" "$test_root/theme/dank16.py"
jq '.primary = "#112233" | .surface = "#445566"' \
  "$repo_root/theme/colors.json" >"$test_root/theme/colors.json"
XDG_CONFIG_HOME="$test_root" "$repo_root/theme/apply-theme.sh" --no-reload >/dev/null

gtk4_colors="$test_root/gtk-4.0/colors.css"
[[ -s $gtk4_colors ]]
rg -q --fixed-strings ':root {' "$gtk4_colors"
rg -q --fixed-strings -- '--accent-bg-color: #112233;' "$gtk4_colors"
rg -q --fixed-strings -- '--window-bg-color: #445566;' "$gtk4_colors"

printf 'theme generation: ok\n'
