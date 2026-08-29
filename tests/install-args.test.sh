#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

mkdir -p "$TEST_ROOT/lib" "$TEST_ROOT/media"
cp "$REPO_ROOT/install.sh" "$TEST_ROOT/install.sh"
cp "$REPO_ROOT/lib/helpers.sh" "$TEST_ROOT/lib/helpers.sh"

cat > "$TEST_ROOT/media/install.sh" <<'MODULE'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$DOTFILES_DIR/received-args"
MODULE
chmod +x "$TEST_ROOT/install.sh" "$TEST_ROOT/media/install.sh"

"$TEST_ROOT/install.sh" media --restart >/dev/null

if [[ $(<"$TEST_ROOT/received-args") != "--restart" ]]; then
    printf 'expected media installer to receive --restart\n' >&2
    exit 1
fi
