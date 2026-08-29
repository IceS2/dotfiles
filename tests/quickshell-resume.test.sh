#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

mkdir -p "$TEST_ROOT/bin"

cat > "$TEST_ROOT/bin/qs" <<'EOF'
#!/usr/bin/env bash
printf 'qs:%s\n' "$*" >> "$TEST_CALLS"
EOF

cat > "$TEST_ROOT/bin/hyprctl" <<'EOF'
#!/usr/bin/env bash
case "$1" in
    layers) printf '%s\n' '{"namespace":"quickshell-bar"}' ;;
    clients) printf '%s\n' '[]' ;;
esac
EOF

cat > "$TEST_ROOT/bin/sleep" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

cat > "$TEST_ROOT/bin/quickshell" <<'EOF'
#!/usr/bin/env bash
printf 'quickshell:start\n' >> "$TEST_CALLS"
EOF

cat > "$TEST_ROOT/bin/timeout" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

chmod +x "$TEST_ROOT/bin/qs" "$TEST_ROOT/bin/hyprctl" \
    "$TEST_ROOT/bin/sleep" "$TEST_ROOT/bin/quickshell" "$TEST_ROOT/bin/timeout"

export TEST_CALLS="$TEST_ROOT/calls"
PATH="$TEST_ROOT/bin:$PATH" "$REPO_ROOT/hypr/scripts/resume-from-lock.sh"

expected=$'qs:kill\nquickshell:start'
if [[ $(<"$TEST_CALLS") != "$expected" ]]; then
    printf 'expected resume to restart Quickshell; calls were:\n' >&2
    cat "$TEST_CALLS" >&2
    exit 1
fi
