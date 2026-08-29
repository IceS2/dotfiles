#!/usr/bin/env bash
# Exercises the three degradation paths from spec §4.3.
# Run: hypr/staging/lib/colors_test.sh
set -uo pipefail
LIB="$(cd "$(dirname "$0")" && pwd)"
fail=0

check() { if [[ "$2" == "$3" ]]; then printf '  PASS  %s\n' "$1"
          else printf '  FAIL  %s: expected %s, got %s\n' "$1" "$2" "$3"; fail=1; fi; }

run() { COLORS_JSON="$1" lua -e "package.path='$LIB/?.lua;'..package.path
        local C=require('colors'); print($2)"; }

trunc=$(mktemp); printf '{ "primary": "#aabb' > "$trunc"

# (a) real file yields the live palette
check "real file: 6 hex digits" "ok" \
  "$(run "$HOME/.config/theme/colors.json" "C.rgb('primary'):match('^rgb%(%x%x%x%x%x%x%)$') and 'ok' or 'bad'")"
check "real file: rgba alpha" "ok" \
  "$(run "$HOME/.config/theme/colors.json" "C.rgba('surface_container_lowest','aa'):match('aa%)$') and 'ok' or 'bad'")"

# (b) missing and (c) truncated files fall back instead of erroring
check "missing file: fallback"   "rgb(cba6f7)" "$(run /nonexistent.json "C.rgb('primary')")"
check "truncated file: fallback" "rgb(cba6f7)" "$(run "$trunc" "C.rgb('primary')")"

# typos still fail loudly in every mode
for f in "$HOME/.config/theme/colors.json" /nonexistent.json "$trunc"; do
  check "typo rejected ($(basename "$f"))" "false" \
    "$(run "$f" "tostring(pcall(C.rgb,'surfaceContainer'))")"
done

rm -f "$trunc"
exit $fail
