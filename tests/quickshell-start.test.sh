#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d)
first_pid=
second_pid=
cleanup() {
    [[ -z "$first_pid" ]] || kill "$first_pid" 2>/dev/null || true
    [[ -z "$second_pid" ]] || kill "$second_pid" 2>/dev/null || true
    rm -rf "$test_root"
}
trap cleanup EXIT

mkdir -p "$test_root/bin" "$test_root/runtime"
mkfifo "$test_root/hold"

cat > "$test_root/bin/quickshell" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$TEST_CALLS"
cat "$TEST_HOLD_FIFO" >/dev/null
EOF
chmod +x "$test_root/bin/quickshell"

export PATH="$test_root/bin:$PATH"
export XDG_RUNTIME_DIR="$test_root/runtime"
export TEST_CALLS="$test_root/calls"
export TEST_HOLD_FIFO="$test_root/hold"

"$repo_root/hypr/scripts/start-quickshell.sh" &
first_pid=$!
timeout 5 bash -c 'until [[ -s "$TEST_CALLS" ]]; do sleep 0.05; done'

if "$repo_root/hypr/scripts/start-quickshell.sh"; then
    echo "a second start succeeded while Quickshell held the lock" >&2
    exit 1
fi
[[ $(wc -l < "$TEST_CALLS") -eq 1 ]] || {
    echo "a second Quickshell process started" >&2
    exit 1
}

"$repo_root/hypr/scripts/start-quickshell.sh" --wait &
second_pid=$!
printf 'exit\n' > "$TEST_HOLD_FIFO"
wait "$first_pid"
first_pid=

timeout 5 bash -c 'until [[ $(wc -l < "$TEST_CALLS") -eq 2 ]]; do sleep 0.05; done'
printf 'exit\n' > "$TEST_HOLD_FIFO"
wait "$second_pid"
second_pid=

[[ $(<"$TEST_CALLS") == $'--no-duplicate\n--no-duplicate' ]]
