#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/runtime"

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
printf 'quickshell:%s\n' "$*" >> "$TEST_CALLS"
EOF

cat > "$TEST_ROOT/bin/timeout" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

chmod +x "$TEST_ROOT/bin/qs" "$TEST_ROOT/bin/hyprctl" \
    "$TEST_ROOT/bin/sleep" "$TEST_ROOT/bin/quickshell" "$TEST_ROOT/bin/timeout"

export TEST_CALLS="$TEST_ROOT/calls"
XDG_RUNTIME_DIR="$TEST_ROOT/runtime" PATH="$TEST_ROOT/bin:$PATH" "$REPO_ROOT/hypr/scripts/resume-from-lock.sh"
/usr/bin/timeout 5 bash -c 'until [[ $(wc -l < "$TEST_CALLS") -eq 2 ]]; do /usr/bin/sleep 0.05; done'

expected=$'qs:kill\nquickshell:--no-duplicate'
if [[ $(<"$TEST_CALLS") != "$expected" ]]; then
    printf 'expected resume to restart Quickshell; calls were:\n' >&2
    cat "$TEST_CALLS" >&2
    exit 1
fi
