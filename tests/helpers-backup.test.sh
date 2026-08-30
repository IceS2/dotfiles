#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT
mkdir -p "$test_root/bin"

printf '%s\n' '#!/usr/bin/env bash' 'printf "%s\\n" 20260830-160000' >"$test_root/bin/date"
chmod +x "$test_root/bin/date"
PATH="$test_root/bin:$PATH"

# shellcheck source=../lib/helpers.sh
source "$repo_root/lib/helpers.sh"

source_file="$test_root/source"
destination="$test_root/config"
printf '%s\n' managed >"$source_file"

clean_destination="$test_root/clean-config"
printf '%s\n' original >"$clean_destination"
_make_link "$source_file" "$clean_destination"
[[ $(<"${clean_destination}.bak") == original ]]

printf '%s\n' first-backup >"${destination}.bak"
printf '%s\n' second-version >"$destination"

_make_link "$source_file" "$destination"

[[ -L $destination && $(readlink "$destination") == "$source_file" ]]
[[ $(<"${destination}.bak") == first-backup ]]
[[ $(<"${destination}.bak.20260830-160000") == second-version ]]

rm "$destination"
printf '%s\n' third-version >"$destination"
_make_link "$source_file" "$destination"

[[ $(<"${destination}.bak") == first-backup ]]
[[ $(<"${destination}.bak.20260830-160000") == second-version ]]
[[ $(<"${destination}.bak.20260830-160000.1") == third-version ]]

printf 'link backup collision handling: ok\n'
