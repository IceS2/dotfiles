#!/usr/bin/env bash
set -euo pipefail

lock_file="${XDG_RUNTIME_DIR:?}/quickshell-shell.lock"

if [[ "${1:-}" == "--wait" ]]; then
    exec flock --close --timeout 10 "$lock_file" quickshell --no-duplicate
fi

exec flock --close --nonblock "$lock_file" quickshell --no-duplicate
