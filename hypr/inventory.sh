#!/usr/bin/env bash
# Compares the old .conf config against the staged Lua config.
# Loops make a line-by-line diff useless, so compare extracted sets.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1   # repo root (this script lives in hypr/)
OLD=hypr/configs
NEW=hypr/configs
fail=0

check() { # label expected actual
    if [[ -z "$2" || -z "$3" ]]; then
        # An empty value means a grep failed (missing file) -- never a pass.
        printf '  FAIL  %-24s empty result (expected=%q actual=%q)\n' "$1" "$2" "$3"; fail=1
    elif [[ "$2" == "$3" ]]; then
        printf '  PASS  %-24s %s\n' "$1" "$2"
    else
        printf '  FAIL  %-24s expected %s, got %s\n' "$1" "$2" "$3"; fail=1
    fi
}

check "env vars" \
    "$(grep -c '^env = ' $OLD/env.conf)" \
    "$(grep -c '^hl.env(' $NEW/env.lua)"

check "exec-once" \
    "$(grep -c '^exec-once = ' $OLD/autostart.conf)" \
    "$(grep -c '^\s*hl.exec_cmd(' $NEW/autostart.lua)"

check "bezier curves" \
    "$(grep -c '^\s*bezier = ' $OLD/animations.conf)" \
    "$(grep -c '^hl.curve(' $NEW/animations.lua)"

check "animations" \
    "$(grep -c '^\s*animation = ' $OLD/animations.conf)" \
    "$(grep -c '^hl.animation(' $NEW/animations.lua)"

check "monitors" \
    "$(grep -c '^monitor = ' $OLD/monitors.conf)" \
    "$(grep -c '^hl.monitor(' $NEW/display.lua)"

# Layer namespaces: compare the actual sets, not just counts.
old_ns=$(grep -o 'quickshell-[a-z-]*' $OLD/windowrules.conf | sort -u)
new_ns=$( { sed -n '/^local QUICKSHELL_LAYERS/,/^}/p' $NEW/rules.lua \
              | grep -oE '"[a-z-]+"' | tr -d '"' | sed 's/^/quickshell-/'
            echo quickshell-power; } | sort -u )
if [[ "$old_ns" == "$new_ns" ]]; then
    printf '  PASS  %-24s %s namespaces\n' "layer namespaces" "$(wc -l <<<"$new_ns")"
else
    printf '  FAIL  %-24s\n' "layer namespaces"
    diff <(echo "$old_ns") <(echo "$new_ns"); fail=1
fi

# Window rule matchers: every class/title matched in the old config must appear
# somewhere in the new one.
#
# Two normalisations are required, or this reports false positives:
#   1. hyprlang allows a trailing `# comment` after the matcher with no comma,
#      so strip from the first '#' and trim.
#   2. Lua string literals escape the backslash, so windowrules.conf's
#      `^(gw2-64\.exe)$` is `^(gw2-64\\.exe)$` in rules.lua. Compare with
#      backslashes collapsed on both sides.
missing=0
new_norm=$(sed 's/\\\\/\\/g' $NEW/rules.lua)
while read -r m; do
    [[ -z "$m" ]] && continue
    grep -qF -- "$m" <<<"$new_norm" || { echo "  FAIL  matcher absent: $m"; missing=1; }
done < <(grep -oE 'match:(class|title) [^,]+' $OLD/windowrules.conf \
           | sed -E 's/match:(class|title) //; s/[[:space:]]*#.*$//; s/[[:space:]]+$//' \
           | sort -u)
[[ $missing -eq 0 ]] && printf '  PASS  %-24s %s\n' "window rule matchers" \
    "$(grep -oE 'match:(class|title) [^,]+' $OLD/windowrules.conf \
        | sed -E 's/match:(class|title) //; s/[[:space:]]*#.*$//; s/[[:space:]]+$//' \
        | sort -u | wc -l) unique" || fail=1

exit $fail
